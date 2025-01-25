rec {
  description = "My personal Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix.url = "github:nix-community/poetry2nix";
    poetry2nix.inputs.nixpkgs.follows = "nixpkgs";
    davids-dotfiles-private.url = "github:dszakallas/davids-dotfiles-private";
    davids-dotfiles-private.inputs.nixpkgs.follows = "nixpkgs";
    davids-dotfiles-private.inputs.flake-utils.follows = "flake-utils";
    davids-dotfiles-private.inputs.poetry2nix.follows = "poetry2nix";
  };

  nixConfig = {
    extra-experimental-features = [
      "nix-command"
      "flakes"
    ];
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://devenv.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      davids-dotfiles-private,
      poetry2nix,
      flake-utils,
      ...
    }:
    let
      importChildren =
        d: builtins.mapAttrs (_: v: import v (inputs // outputs)) (outputs.davids-dotfiles.lib.subDirs d);
      mkDarwin =
        { host, arch, ... }:
        nix-darwin.lib.darwinSystem rec {
          system = "${arch}-darwin";
          specialArgs =
            let
              hostPlatform = nixpkgs.legacyPackages.${system}.stdenv.hostPlatform;
            in
            {
              inherit
                home-manager
                hostPlatform
                system
                nixConfig
                ;
            };
          modules = [
            home-manager.darwinModules.home-manager
            (import ./hosts/${host} (inputs // outputs))
            {
              home-manager = {
                extraSpecialArgs = specialArgs;
              };
            }
          ];
        };
      outputs = {
        davids-dotfiles = rec {
          lib = import ./lib { inherit (nixpkgs) lib; };
          darwinModules = importChildren ./modules/darwin;
          systemModules = importChildren ./modules/system;
          homeModules = importChildren ./modules/home;
          users = importChildren ./users;
          packages = (
            flake-utils.lib.eachDefaultSystem (
              system:
              let
                pkgs = nixpkgs.legacyPackages.${system};
                packages = lib.callPackageDirWith ./pkgs (inputs // pkgs);
              in
              packages
            )
          );
        };
        darwinConfigurations = {
          Jellyfish = mkDarwin {
            host = "Jellyfish";
            arch = "aarch64";
          };
          "dszakallas--Clownfish" = mkDarwin {
            host = "dszakallas--Clownfish";
            arch = "aarch64";
          };
        };
      };
    in
    outputs;
}
