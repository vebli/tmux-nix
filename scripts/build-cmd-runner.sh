#!/run/current-system/sw/bin/bash
TVAR_CURR_CMD="@v_build_cmd_curr"

set_curr_cmd(){
  tmux command-prompt -p "Enter build command:" \
    "set-option $TVAR_CURR_CMD '%%'"
}

run_curr_cmd(){
  CMD=$(tmux show -qv $TVAR_CURR_CMD) 
  if [[ -n "$CMD" ]]; then
    tmux split-window -v -c "#{pane_current_path}" -l 30% "bash -c '$CMD & while [ : ]; do sleep 1; done'"
  else
    echo "No build command set."
  fi
}

case "$1" in
  --set)
    set_curr_cmd
    ;;

  --run)
    run_curr_cmd
    ;;
  *)
    run_curr_cmd
    ;;
esac
