#!/usr/bin/env bash

tmux_is_running(){
    if [[ -n $TMUX ]]; then 
        return 0
    fi
    return 1 
}

tmux_list_sessions(){
    tmux list-sessions -F '#S'
}

tmux_current_session(){
    tmux display-message -p "#S"
}

tmux_kill_session(){
    # Kill session without detaching
    local name="${1:-}"
    if ! tmux has-session -t "$name" &>/dev/null; then return 0; fi
    if [[ "$(tmux_current_session)" == "$name" ]]; then 
        tmux_goto_session "default"
    fi
    tmux kill-session -t "$name"
}
tmux_goto_session(){
    # Switches to session or creates new one if it doesn't exist
    local name="$1"
    shift
    if tmux has-session -t "$name" &>/dev/null; then
        if tmux_is_running; then
            tmux switch-client -t "$name"
        else
            tmux attach -t "$name"
        fi
    else
        tmux new-session -d -s "$name" "$@"
        if tmux_is_running; then
            tmux switch-client -t "$name"
        else 
            tmux attach -t "$name"
        fi
    fi
}

tmux_run_cmd_in_split(){
    local cmd=$1
    tmux split-window -v -c "#{pane_current_path}" -l 30% "bash -c '$cmd & while [ : ]; do sleep 1; done'"
}

tmux_prompt(){
    # Returns user input as string
    local prompt="$1"
    local inputs=${2:-}
    local tmpfile="$(mktemp)"
    tmux command-prompt -p "$prompt" -I "$inputs" "run-shell 'echo %% > $tmpfile'"
    cat $tmpfile
}


