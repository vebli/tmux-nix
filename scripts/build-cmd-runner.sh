#!/usr/bin/env bash 

source "$(dirname "$0")/util/tmux.sh"

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
        tmux_run_cmd_in_split "$CMD"
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
