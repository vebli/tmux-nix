#!/usr/bin/env bash

source "$(dirname "$0")/util/tmux.sh"

PROJECT_DIRS=(
    "$HOME/code/projects"
    "$HOME/code/tools"
)

main(){
    case "$1" in
        --clear) kill_unnamed_session;;
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
            tmux_goto_session "$name" -c "$fullpath"
        ;;
    esac
}

kill_unnamed_session(){
    # Deletes numbered sessions 
    local regex="^[0-9]+$"
    local current_session=tmux_current_session
     
    for session in $(tmux_list_sessions); do 
        # TODO: Breaks for session names with spaces 
        if [[ "$session" =~ $regex ]]; then
            tmux_kill_session "$current_session"
        fi
    done
}

manage_sessions() {
    local sessions=tmux_list_sessions    
    while true; do 
        { read -r key;  read -r name; } < <( "$sessions" | fzf --ansi --tmux\
            --expect=ctrl-a,ctrl-d,ctrl-e,enter\
            --header="ctrl-a: add | ctrl-d: delete | ctrl-c: clear | ctrl-e: edit | enter: attach" 
        )
        case $key in 
            enter) 
                if tmux has-session -t="$name" 2>/dev/null; then
                    tmux switch-client -t "$name"
                fi
                break
                ;;
            ctrl-a) 
                open_project
                break
                ;;
            ctrl-c) 
                kill_unnamed_session
                ;;
            ctrl-d) 
                #TODO: Menu closes if current session is deleted. 
                tmux_kill_session "$name"
        esac
    done
}

main "$@"
