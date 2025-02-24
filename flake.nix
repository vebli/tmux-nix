{
  description = "Tmux config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
  };

  outputs = inputs @ { self, nixpkgs, nixpkgs-unstable, ...}: let
      system = "x86_64-linux";
      pkgs = import nixpkgs-unstable {
        inherit system;
    };
    in rec{
    overlays.default = super: self: {
      tmux-custom = packages.${super.system}.default;
    };

    packages.${system}.default =  pkgs.callPackage ./tmux.nix {};
  };
}
