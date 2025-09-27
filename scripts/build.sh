#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/util/tmux.sh"

BUILD_CFG_DIR="$HOME/.local/share/tmux"
BUILD_CFG_FILE="$BUILD_CFG_DIR/build.json"
BUILD_CFG_LOG_DIR="$BUILD_CFG_DIR/logs"

main(){
    local dir="" command_key="" command_val="" option="${1:-}"
    if [ ! -d "$BUILD_CFG_DIR" ]; then 
        mkdir -p "$BUILD_CFG_DIR"
    fi 

    if [ ! -d "BUILD_CFG_LOG_DIR" ]; then 
        mkdir -p "$BUILD_CFG_LOG_DIR"
    fi 

    if [ ! -f "$BUILD_CFG_FILE" ]; then 
        touch "$BUILD_CFG_FILE"
        echo "{}" > "$BUILD_CFG_FILE"

    fi 
    if ! is_valid_json_file "$BUILD_CFG_FILE"; then
        edit_json 
    fi

    shift 1;
    while [[ $# -gt 0 ]]; do
        case $1 in 
            --dir) dir="$2"; shift 2;; 
            --key) command_key="$2"; shift 2;;
            --command) command_val="$2"; shift 2;;
            *) usage; return 1;;
        esac
    done

    case "$option" in
        menu) menu "$dir";;
        run) run "$dir" "$command_key";;
        del|delete) delete "$dir" "$command_key";;
        set) setc "$dir" "$command_key" "$command_val";;
        edit) edit_json "$dir";;
        gen|gen-commands) gen_commands "$dir";;
        log) show_log "$command_key";;
        help|--help) usage;;
        *) usage; return 1 ;; 
    esac
    return 0;
}

menu(){
    local dir="${1:-"$(pwd)"}" command_key="" command_val=""

    while true; do
        local key="" selected=""
        { read -r key; read -r selected; } < <(
            jq -r --arg dir "$dir" \
                '.[$dir] // empty | to_entries[] | "\(.key)\t\(.value)"' \
                "$BUILD_CFG_FILE" |
            { grep . || echo "** no commands **"; } | \
            fzf --tmux --ansi \
                --expect=ctrl-a,ctrl-d,ctrl-e,ctrl-c,enter,ctrl-r,ctrl-q,ctrl-c,ctrl-g,esc \
                --header="enter: run | r: run split | a: add | d: del | e: edit | g: gen | q: quit"
        )
        if [[ "$selected" == *$'\t'* ]]; then
            command_key="${selected%%$'\t'*}"  
            command_val="${selected#*$'\t'}"
        fi
        case "$key" in
            enter) run_core_quiet "$dir" "$command_key" "$command_val"; return;;
            ctrl-r) run_core_split "$dir" "$command_key" "$command_val"; return;;
            ctrl-a) setc "$dir";;
            ctrl-d) delete "$dir" "$command_key";;
            ctrl-e) edit_json "$dir" "$command_key";;
            ctrl-g) gen_commands "$dir";;
            ctrl-q|ctrl-c|esc) return;;
        esac
    done
}
edit_json(){
    local dir="${1:-}" tmpfile=""
    tmpfile="$(mktemp)"
    if [ -z "$dir" ]; then dir="$(pwd)"; fi
    if [ ! -f "$tmpfile" ]; then return 1; fi 
    cat "$BUILD_CFG_FILE" > "$tmpfile"
    if [ -z "$EDITOR" ]; then
        tmux display-message "No editor specified"
    fi
    if { [ "$EDITOR" == "vim" ] || [ "$EDITOR" == "nvim" ]; } && cat "$BUILD_CFG_FILE" | grep "$dir" &> /dev/null; then #Jump cursor to current project folder
        local dir_escaped="${dir//\//\\/}"
        "$EDITOR" "+/$dir_escaped" "$tmpfile" 
    else
        "$EDITOR" "$tmpfile"
    fi

    if is_valid_json_file "$tmpfile"; then 
        update_cfg "$(cat "$tmpfile")"
        return 0
    else
        tmux display-message "Invalid json"
        return 1
    fi
}

gen_commands(){
    local dir="${1:-"$(pwd)"}" 

    # cmake 
    local cmake_key="cmake build"
    if [ -f "$dir/CMakeLists.txt" ] && [ -d "$dir/build" ] && [ -z "$(get_cfg_command "$dir" "$cmake_key")" ]; then
        setc "$dir" "$cmake_key" "cd .$dir/build && cmake .. && cmake --build ."
    fi

    # nix 
    local flake_run_key="flake run"
    if [ -f "$dir/flake.nix" ] && [ -z "$(get_cfg_command "$dir" "$flake_run_key")" ]; then
        setc "$dir" "$flake_run_key" "nix run $dir"
    fi

}

delete(){
    local dir="${1-:}" command_key="${2-:}" new_cfg=""

    if [ -z "$dir" ]; then dir="$(pwd)"; fi

    if [ -z "$command_key" ]; then
        new_cfg="$(jq -r --arg dir "$dir" \
            'del(.[$dir])' \
            "$BUILD_CFG_FILE")"
        update_cfg "$new_cfg"
    else
        new_cfg=$(jq -r --arg dir "$dir" \
            --arg key "$command_key" \
            'del(.[$dir][$key])' \
            "$BUILD_CFG_FILE")
        update_cfg "$new_cfg"
    fi
}
setc(){ 
    local dir="${1:-"$(pwd)"}" command_key="${2:-}" command_val="${3:-}" 

    if [ -n "$command_key" ] && [ -z "$command_val" ]; then
        command_val=$(tmux_prompt "Enter command for '$command_key': ") 
    elif [ -z "$command_key" ] && [ -z "$command_val" ]; then
        command_key=$(tmux_prompt "Enter command key for '$dir': ") 
        command_val=$(tmux_prompt "Enter command for '$command_key': ") 
    fi
    set_cfg_command "$dir" "$command_key" "$command_val"
}


run(){
    local dir="${1:-"$(pwd)"}" command_key="${2:-}" command_val="" selected=""

    selected="$(jq -r --arg dir "$dir" \
        '.[$dir] | to_entries[] | "\(.key)\t\(.value)"' \
        "$BUILD_CFG_FILE" |\
        fzf --tmux --ansi 
    )" 
    command_key="${selected%%$'\t'*}"  
    command_val="${selected#*$'\t'}"

    run_core_quiet "$dir" "$command_key" "$command_val"
}

usage() {
    cat <<EOF
Usage: ./build.sh <command> [options]

Commands:
  menu                 Launch interactive menu 
  run                  Run a stored command
  set                  Add or update a command
  del | delete         Delete a command
  edit                 Edit the JSON config directly

Options:
  --dir <directory>    Specify the project directory (default: current directory)
  --key <command_key>  Specify the command key (default: 'build')
  --command <cmd>      Specify the command string to store

Examples:
  ./build.sh menu
  ./build.sh run --dir /path/to/project --key build
  ./build.sh set --dir /path/to/project --key build --command "cmake .. && cmake --build ."
  ./build.sh del --dir /path/to/project --key build
  ./build.sh edit

EOF
}
run_core_split(){ local dir="${1:-}" command_key="${2:-}" command_val="" 
    command_val="$(get_cfg_command "$dir" "$command_key")" 
    [ -z "$command_val" ] || [ "$command_val" == "null" ] && return 1;
    tmux split-window -v -l 30% "cd '$dir' && { $command_val; } 2>&1"
}

run_core_quiet(){
    local dir="${1:-}" command_key="${2:-}" command_val=""
    command_val="$(get_cfg_command "$dir" "$command_key")"
    [ -z "$command_val" ] || [ "$command_val" == "null" ] && return 1;
   

    # sed to filter cursor movement escape codes
    (cd "$dir" && eval "$command_val")  \
        | sed -r 's/\x1B\[([0-9;]*[A-Za-z])//g' \
        > "$BUILD_CFG_LOG_DIR/$command_key.log"
}

show_log(){
    local command_key="${1:-}" 
    if [ -z "$command_key" ]; then 
        tmux display-message "Missing argument key"
        return 1
    fi

    local logfile="$BUILD_CFG_LOG_DIR/$command_key.log"
    if [ ! -s "$logfile" ]; then
        tmux display-message "No log for $command_key"
        return 1
    fi

    tmux split-window -v -l 30% "less +G -R '$logfile'"
}

get_cfg_dir(){
    local dir="$1" cfg=""
    cfg="$(jq -r --arg dir "$dir" '.[$dir]' "$BUILD_CFG_FILE")"
    if [ "$command_val" == "null" ]; then return 1; fi
    echo "$cfg"
    return 0

}

get_cfg_command(){
    local dir="$1" command_key="$2" command_val=""
    command_val="$(jq -r --arg dir "$dir" \
        --arg key "$command_key" \
        '.[$dir][$key]' \
        "$BUILD_CFG_FILE")"
    if [ "$command_val" == "null" ]; then return 1; fi
    echo "$command_val"
    return 0
}

set_cfg_command(){
    local dir="$1" command_key="$2" command_val="$3"
    cfg="$(jq -r --arg dir "$dir" \
        --arg key "$command_key" \
        --arg val "$command_val" \
        '.[$dir][$key] = $val' \
        "$BUILD_CFG_FILE")"
    update_cfg "$cfg"
}

is_valid_json_file(){
    local file="${1:-}"
    jq empty "$file" >/dev/null 2>&1
}

update_cfg(){
    local new_cfg="${1:-}" tmpfile=""
    tmpfile="$(mktemp)"
    if [ ! -f "$tmpfile" ] || [ -z "$new_cfg" ]; then return 1; fi 
    echo "$new_cfg" > "$tmpfile" && mv "$tmpfile" "$BUILD_CFG_FILE"
}

main "$@"
