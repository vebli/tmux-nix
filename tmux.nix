inputs @ {
  lib,
  callPackage,
  stdenv,
  tmux,
  writeShellApplication,
  fzf,
  pstree,
  jq,
}: let
  plugins = callPackage ./plugins.nix {};
  getPluginName = plugin: lib.strings.removePrefix "tmuxplugin-" plugin.pname;
  mkPluginCfg = plugins:
    builtins.concatStringsSep "\n"
    (map (p: ''
        # ------ ${getPluginName p.plugin} config
        ${
          if p ? config
          then p.config
          else ""
        }

        run-shell ${p.plugin.rtp}
      '')
      plugins);

  generalCfg = builtins.readFile ./tmux.conf;
  pluginCfg = mkPluginCfg plugins;
  config = ''
    # ---- General Config ------
    ${generalCfg}

    # ----- Plugin Config ------
    ${pluginCfg}
  '';
  rtp = stdenv.mkDerivation {
    name = "tmux-config";
    src = ./.;
    phases = ["installPhase"];
    installPhase = ''
      mkdir -p $out
      touch $out/tmux.conf
      cp -r $src/scripts $out
      chmod u+x $out/scripts/*
      cat <<EOF > $out/tmux.conf
      set -g @v_conf_dir $out 
      set -g @v_scripts_dir $out/scripts
      ${config}
    '';
  };
in
  writeShellApplication {
    name = "tmux";
    runtimeInputs = [fzf pstree tmux.man jq];
    text = ''
      ${tmux}/bin/tmux -f ${rtp}/tmux.conf "$@"
    '';
  }
