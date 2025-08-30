#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/util/tmux.sh"

BUILD_CFG_DIR="$HOME/.local/share/tmux"
BUILD_CFG_FILE="$BUILD_CFG_DIR/build.json"

main(){
    local dir="" command_key="" command_val=""
    if [ ! -d "$BUILD_CFG_DIR" ]; then 
        mkdir -p "$BUILD_CFG_DIR"
    fi 

    if [ ! -f "$BUILD_CFG_FILE" ]; then 
        touch "$BUILD_CFG_FILE"
        echo "{}" > "$BUILD_CFG_FILE"

    fi 

    case $1 in
        menu) shift 1; menu "$@"; return;;
        run) shift 1; run "$@"; return;;
        set) shift 1; setc "$@"; return;;
        del|delete) shift 1; delete "$@"; return;;
        *) usage; return 1 ;; 
    esac
}

# edit_json(){}

delete(){
    local dir="" command_key="" new_cfg=""

    while [[ $# -gt 0 ]]; do
        case $1 in 
            --dir) dir="$2"; shift 2;; 
            --key) command_key="$2"; shift 2;;
        esac
    done

    if [ -z "$dir" ]; then return 1; fi
    if [ -z "$command_key" ]; then
        new_cfg="$(jq --arg dir "$dir" \
            'del(.[$dir])' \
            "$BUILD_CFG_FILE")"
        update_cfg "$new_cfg"
    else
        new_cfg=$(jq --arg dir "$dir" \
            --arg key "$command_key" \
            'del(.[$dir][$key])' \
            "$BUILD_CFG_FILE")
        update_cfg "$new_cfg"
    fi
}
setc(){
    local dir="" command_key="" command_val=""
    while [[ $# -gt 0 ]]; do
        case $1 in 
            --dir) dir="$2"; shift 2;; 
            --key) command_key="$2"; shift 2;;
            --command) command_val="$2"; shift 2;;
        esac
    done

    if [ -z "$dir" ]; then dir="$(pwd)"; fi
    if [ -z "$command_key" ]; then command_key="build"; fi
    if [ -z "$command_val" ]; then 
        command_val=$(tmux_prompt "Enter command for '$command_key': ")
    fi
    set_command "$dir" "$command_key" "$command_val"
}

run(){
    local dir="" command_key="" 
    while [[ $# -gt 0 ]]; do
        case $1 in 
            --dir) dir="$2"; shift 2;; 
            --key) command_key="$2"; shift 2;;
        esac
    done

    if [ -z "$dir" ]; then dir="$(pwd)"; fi
    if [ -z "$command_key" ]; then command_key="build"; fi

    if ! run_command "$dir" "$command_key"; then 
        command_val=$(tmux_prompt "Enter command for '$command_key': ")
        set_command "$dir" "$command_key" "$command_val"
        run_command "$dir" "$command_key"
    fi 
}

usage(){ #TODO
    echo "Usage: \n"
    return 0;
}
set_command(){
    local dir="" command_key="" command_val="" new_cfg=""
    dir="$1"
    command_key="$2"
    command_val="$3"
    new_cfg="$(jq --arg dir "$dir" \
        --arg key "$command_key" \
        --arg val "$command_val" \
        '.[$dir][$key] = $val' \
        "$BUILD_CFG_FILE")" 
    update_cfg "$new_cfg"
    return 0
}
get_command(){
    local dir="" command_key="" command_val=""
    dir="$1"
    command_key="$2"
    command_val=$(
        jq -r --arg dir "$dir" \
            --arg key "$command_key" \
        '.[$dir][$key]' "$BUILD_CFG_FILE"
    )
    echo "$command_val"
}
run_command(){
    local dir="" command_key="" command_val=""
    dir="$1"
    command_key="$2"
    command_val="$(get_command "$dir" "$command_key")"
    if [ -n "$command_val" ] && [ "$command_val" != "null" ]; then
        exec "$command_val"
    else 
        return 1
    fi
    return 0
}
update_cfg(){
    local new_cfg="" tempfile=""
    new_cfg="$1"
    tmpfile=$(mktemp)
    echo "$new_cfg" > "$tmpfile" && mv "$tmpfile" "$BUILD_CFG_FILE"
}



main "$@"
