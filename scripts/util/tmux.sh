#!/usr/bin/env bash

tmux_is_running(){
    local tmux_running=$(pgrep tmux)

    if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
        tmux new-session -s $selected_name -c $selected
        return 0
    fi
    return 1 
}

tmux_list_sessions(){
    tmux list-sessions -F '#S'
}

tmux_run_cmd(){
    local cmd=$1
    tmux split-window -v -c "#{pane_current_path}" -l 30% "bash -c '$cmd & while [ : ]; do sleep 1; done'"
}

tmux_prompt(){
    local prompt="$1"
    local inputs="$2"
    local tmp_file="/tmp/tmux_prompt"
    if [ -d tmp_file ]; then 
        rm tmp_file
    fi

    tmux command-prompt -p "$prompt" -I "${inputs:-}" "run-shell 'echo %% > $tmp_file'"
    cat $tmp_file
}


tmux_get_str_arr(){
    local -n arr=$1
    local option="$2"
    local separator=${3:-'\n'}

    local str_arr
    str_arr="$(tmux show-option -qv "$option")"
    if [[ $separator == '\n' ]]; then
        str_arr=$(printf "%b" "$str_arr") # replace \n with actual new lines
        IFS=$'\n' read -d '' -ra arr < <(printf "%s" "$str_arr") # feed each string to read
    else
        IFS="$separator" read -ra arr <<< "$str_arr"
    fi
}

# Get element of separated string array
tmux_option_arr_get(){
    local option="$1"
    local index="$2"
    local separator=${3:-}
    local arr
    tmux_get_str_arr arr "$option" "#separator"
    echo "${arr[$index]}"
}

tmux_option_arr_delete(){
    local option=$1
    local separator=$2
    local index=$3
}
