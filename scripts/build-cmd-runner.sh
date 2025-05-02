#!/run/current-system/sw/bin/bash

main(){
    #Stores the current command
    local TVAR_cmd_current="@v_build_cmd_curr"

    #Stores list of commands separated with '\n'
    local TVAR_cmd_list="@v_build_cmd_list"

    case "$1" in
        --set)
            set_cmd_current
            ;;

        --run)
            run_cmd_current
            ;;
        --edit)
            edit_cmd_current
            ;;
        --show)
            cmd_list_select
            ;;
        *)
            run_cmd_current
            ;;
    esac
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

get_cmd_current(){
    echo "$(tmux show -qv $TVAR_cmd_current)"
}

set_cmd_current(){
    tmux command-prompt -p "Enter build command:" \
        "set-option $TVAR_cmd_current '%%'"
}
edit_cmd_current(){
    local cmd
    cmd=$(get_cmd_current)
    tmux command-prompt -p "Enter build command:" -I "$cmd" \
        "set-option $TVAR_cmd_current '%%'"
}

run_cmd_current(){
    CMD=$(get_cmd_current)
    if [[ -n "$CMD" ]]; then
        tmux_run_cmd "$CMD"
    else
        echo "No build command set."
    fi
}

cmd_list_add(){
    cmd_list=$(tmux show-option -qv $TVAR_cmd_list)
    new_cmd=$(tmux_prompt "Enter command:")
    local updated_cmd_list
    if [ -n "$new_cmd" ]; then 
        if [ -z $cmd_list ]; then 
            updated_cmd_list="$new_cmd"
        else
            updated_cmd_list="$new_cmd\n$cmd_list"
        fi
        tmux set-option $TVAR_cmd_list "$updated_cmd_list"
    fi
}


get_cmd_list(){
    echo -e "$(tmux show -qv $TVAR_cmd_list)"
}

cmd_list_delete_front(){
    local cmd_list
    cmd_list=$(get_cmd_list)
    cmd_list_new=$(sed '1d' <<<"$cmd_list")
    tmux set-option $TVAR_cmd_list "$cmd_list_new"
}

cmd_list_select(){
    { read -r key;  read -r cmd; } < <( get_cmd_list | fzf --ansi -disabled --no-input --tmux\
        --expect=ctrl-a,ctrl-d,ctrl-e,enter\
        --header="ctrl-a: add | ctrl-d: delete | ctrl-e: edit | enter : run" 
    )
    case $key in
        enter) tmux_run_cmd $cmd ;;
        ctrl-a) 
            cmd_list_add
            cmd_list_select
            ;;
        ctrl-d)
            cmd_list_delete_front
            cmd_list_select
            ;;
        #TODO: 
        # ctrl-e) 
        #     local new_cmd
        #     new_cmd=tmux_prompt "Edit command" "$cmd"
        #     cmd_list_select
        #     ;;
    esac
}

# cmd_list_get(){
#
# }



main "$@"
