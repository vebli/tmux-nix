#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/util/tmux.sh"

BUILD_CFG_DIR="$HOME/.local/share/tmux"
BUILD_CFG_FILE="$BUILD_CFG_DIR/build.json"

main(){
    local dir="" command_key="" command_val=""
    if [ ! -d "$BUILD_CFG_DIR" ]; then 
        mkdir -p "$BUILD_CFG_DIR"
        return 0
    fi 

    if [ ! -f "$BUILD_CFG_FILE" ]; then 
        touch "$BUILD_CFG_FILE"
    fi 

    while [[ $# -gt 0 ]]; do
        case $1 in 
            --dir) dir="$2"; shift 2;; 
            --key) command_key="$2"; shift 2;;
            --command) command_val="$2"; shift 2;;
        esac
    done
    if [ -n "$dir" ] && [ -n "$command_key" ]; then
        if [ -n "$command_val" ]; then 
            set_command "$dir" "$command_key" "$command_val"
        else
            run_command "$dir" "$command_key" 
        fi 
    else
        dir=$(pwd)
        command_key="build"
        if [ -n "$command_val" ]; then
            command_val=$(tmux_prompt "Enter command: ")
            set_command "$dir" "$command_key" "$command_val"
        else
            run_command "$dir" "$command_key" 
        fi
    fi




}

usage(){ #TODO
    echo "Usage: \n"
    return 0;
}
set_command(){
    local dir="" command_key="" command_val=""
    dir="$1"
    command_key="$2"
    command_val="$3"
    tmpfile=$(mktemp)
    jq --arg dir "$dir" \
        --arg key "$command_key" \
        --arg val "$command_val" \
        '.[$dir][$key] = $val' \
        "$BUILD_CFG_FILE" > "$tmpfile" && mv "$tmpfile" "$BUILD_CFG_FILE"
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
        tmux display-message "No command under \"$command_key\""
    fi
    return 0
}



main "$@"
