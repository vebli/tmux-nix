#!/usr/bin/env bash

source "$(dirname "$0")/util/tmux.sh"

main(){
    local sessions=tmux_list_sessions    
    { read -r key;  read -r name; } < <( "$sessions" | fzf --ansi --tmux\
        --expect=ctrl-a,ctrl-d,ctrl-e,enter\
        --header="ctrl-a: add | ctrl-d: delete | ctrl-e: edit | enter : run" 
    )
    case $key in 
        enter) 
            if tmux has-session -t="$name" 2>/dev/null; then
                tmux switch-client -t "$name"
            fi
        ;;
    esac
}

main
