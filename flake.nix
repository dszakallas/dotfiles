rec {
  description = "My personal Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    davids-dotfiles-private.url = "git+file:vendor/davids-dotfiles-private";
    davids-dotfiles-private.inputs.nixpkgs.follows = "nixpkgs";
    poetry2nix.url = "github:nix-community/poetry2nix";
    poetry2nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-experimental-features = [ "nix-command" "flakes" ];
    extra-substituters = [ "https://nix-community.cachix.org" "https://devenv.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, davids-dotfiles-private, poetry2nix, ... }:
  let
    inherit (nixpkgs) lib;
    system = "aarch64-darwin";
    subDirs = d: lib.foldlAttrs (a: k: v: a // (if v == "directory" then {${k} = d + "/${k}";} else {})) {} (builtins.readDir d);
    davids-dotfiles = {
      darwinModules = subDirs ./modules/darwin;
      homeModules = subDirs ./modules/home;
    };
    mkDarwinCfg = name: nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
          inherit self home-manager davids-dotfiles davids-dotfiles-private poetry2nix system nixConfig;
      };
      modules = [
        home-manager.darwinModules.home-manager
        ./hosts/${name}
      ];
    };
  in
  {
    darwinConfigurations = {
      Jellyfish = mkDarwinCfg "Jellyfish";
      "dszakallas--Clownfish" = mkDarwinCfg "dszakallas--Clownfish";
    };
  };
}
