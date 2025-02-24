inputs @ {pkgs, ...}: 
let
  lib = pkgs.lib;
  plugins = with pkgs.tmuxPlugins; [
    {
      plugin = vim-tmux-navigator;
      config = ''
      '';
    }
    {
      plugin = inputs.minimal-tmux.packages.${pkgs.system}.default;
      config = ''
        set -g @minimal-tmux-status "top"
      '';
    }
  ];
  getPluginName = plugin: lib.strings.removePrefix "tmuxplugin-" plugin.pname;
  mkPluginCfg = plugins: builtins.concatStringsSep "\n"
    (map (p: ''
    # ------ ${getPluginName p.plugin} config 
    ${p.config}

    run-shell ${p.plugin.rtp}
    # ------
    '') plugins);

    # set-option -g default-shell ${pkgs.zsh}/bin/zsh
  config = ''
    set-option -g prefix C-Space

    set-option -g base-index 1

    setw -g mode-keys vi

    ${mkPluginCfg plugins}
  '';
  rtp = pkgs.stdenv.mkDerivation {
    name = "tmux-config";
    src = ./.;
    # buildInputs = with pkgs.tmuxPlugins; [
    # ];
    phases = ["installPhase" ];
    installPhase = ''
      mkdir -p $out
      touch $out/tmux.conf
      echo "${config}" >> $out/tmux.conf
    '';
  };

in
   pkgs.writeShellApplication {
    name = "tmux-custom";
    runtimeInputs = []; 
    text = ''
      ${pkgs.tmux}/bin/tmux -f ${rtp}/tmux.conf "$@"
    '';
}
