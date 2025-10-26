{tmuxPlugins}:
with tmuxPlugins; [
  # {plugin = resurrect;}
  # {
  #   plugin = continuum;
  #   config = ''
  #     set -g @continuum-restore 'on'
  #   '';
  # }
  { plugin = vim-tmux-navigator; }
  # { plugin = copycat; }
]
