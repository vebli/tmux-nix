{
  description = "Tmux config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    minimal-tmux = {
      url = "github:niksingh710/minimal-tmux-status";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, nixpkgs-unstable, minimal-tmux, ...}: let
      system = "x86_64-linux";
      pkgs = import nixpkgs-unstable {
        inherit system;
    };
    in rec{
    overlays.default = super: self: {
      tmux= packages.${super.system}.default;
    };

    packages.${system}.default =  import ./tmux.nix {inherit pkgs minimal-tmux;};
  };
}
