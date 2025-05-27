#!/usr/bin/env bash

source "$(dirname "$0")/util/tmux.sh"
#TODO: 
PROJECT_DIRS=(
    "$HOME/code/projects"
    "$HOME/code/tools"
)

main(){
    case "$1" in
        --proj) open_project;;
        --manage) manage_sessions;;
    esac
}

open_project() {
    { read -r key; read -r selected; } < <(
        for dir in "${PROJECT_DIRS[@]}"; do
            find "$dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null 
        done | while read -r path; do
            printf "%s\t%s\n" "$(basename "$path")" "$path"
        done | fzf --ansi --tmux \
                   --expect=enter \
                   --with-nth=1 \
                   --delimiter="\t"
    )
    local name=$(basename "$fullpath")
    case $key in
        enter)
            fullpath="${selected#*$'\t'}"
            name="$(basename "$fullpath")"


            if tmux has-session -t "$name" 2>/dev/null; then
                if tmux_is_running; then
                    tmux switch-client -t "$name"
                else
                    tmux attach -t "$name"
                fi
            else
                tmux new-session -d -s "$name" -c "$fullpath"
                if tmux_is_running; then
                    tmux switch-client -t "$name"
                else 
                    tmux attach -t "$name"
                fi
            fi
        ;;
    esac
}

manage_sessions() {
    local sessions=tmux_list_sessions    
    { read -r key;  read -r name; } < <( "$sessions" | fzf --ansi --tmux\
        --expect=ctrl-a,ctrl-d,ctrl-e,enter\
        --header="ctrl-a: add | ctrl-d: delete | ctrl-e: edit | enter: attach" 
    )
    case $key in 
        enter) 
            if tmux has-session -t="$name" 2>/dev/null; then
                tmux switch-client -t "$name"
            fi
        ;;
        ctrl-a) open_project;;
    esac
}

main "$@"
