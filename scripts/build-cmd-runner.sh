#!/run/current-system/sw/bin/bash
TVAR_CURR_CMD="@v_build_cmd_curr"
get_curr_cmd(){
    echo "$(tmux show -qv $TVAR_CURR_CMD)"
}

set_curr_cmd(){
    tmux command-prompt -p "Enter build command:" \
        "set-option $TVAR_CURR_CMD '%%'"
}

run_curr_cmd(){
    CMD=$(get_curr_cmd)
    if [[ -n "$CMD" ]]; then
        tmux split-window -v -c "#{pane_current_path}" -l 30% "bash -c '$CMD & while [ : ]; do sleep 1; done'"
    else
        echo "No build command set."
    fi
}
edit_curr_cmd(){
    CMD=$(get_curr_cmd)
    tmux command-prompt -p "Edit build command:" -I "$CMD"\
        "set-option $TVAR_CURR_CMD '%%'"
}

case "$1" in
    --set)
        set_curr_cmd
        ;;

    --run)
        run_curr_cmd
        ;;
    --edit)
        edit_curr_cmd
        ;;

    *)
        run_curr_cmd
        ;;
esac
