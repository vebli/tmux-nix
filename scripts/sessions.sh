#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/util/tmux.sh"

PROJECT_DIRS=(
    "$HOME/code/projects"
    "$HOME/code/tools"
)

list_project_dirs(){
    find "${PROJECT_DIRS[@]}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null
}

main(){
    case "$1" in
        --clear) kill_unnamed_session;;
        --proj) open_project;;
        --manage) manage_sessions;;
    esac
    return 0
}

kill_unnamed_session(){
    # Deletes numbered sessions 
    local regex="^[0-9]+$"
    for session in $(tmux_list_sessions); do 
        # TODO: Breaks for session names with spaces 
        if [[ "$session" =~ $regex ]]; then
            tmux_kill_session "$session"
        fi
    done
}
manage_sessions() { #TODO: Breaks if session name has spaces or starts with *
    while true; do 
        # all_sessions=($(tmux_list_sessions))
        local all_sessions proj_dirs num_active_sessions
        mapfile -t all_sessions < <(tmux_list_sessions)
        num_active_sessions=${#all_sessions[@]}
        echo $num_active_sessions
        proj_dirs=$(echo "$(list_project_dirs)")
        for dir in $proj_dirs; do
            if printf '%s\n' "${all_sessions[@]}" | grep -qx "$(basename "$dir")"; then
                continue
            else
                all_sessions+=("$(basename "$dir")")
            fi
        done
        for i in $(seq $((num_active_sessions - 1)) -1 0); do
            all_sessions[i]="* ${all_sessions[i]}" 
        done
        { read -r key;  read -r name_with_prefix; } < <( printf "%s\n" "${all_sessions[@]}" |
            sort -k1,1r|\
                fzf --ansi --tmux --tac\
                --expect=ctrl-q,ctrl-d,ctrl-e,ctrl-c,enter\
                --header="enter: attach | ctrl-d: delete | ctrl-c: clear | ctrl-q: quit" 
            )
            local name=${name_with_prefix/*\ /}
            case "$key" in 
                enter) tmux_goto_session "$name"; return;;
                ctrl-q) return;;
                ctrl-c) kill_unnamed_session ;;
                ctrl-d) tmux_kill_session "$name" ;;
            esac
        done
    }

main "$@"
