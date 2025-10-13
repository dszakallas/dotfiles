rec {
  description = "My personal Nix configuration";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    davids-dotfiles-common = {
      url = "github:dszakallas/dotfiles-common";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.flake-utils.follows = "flake-utils";
    };
    davids-dotfiles-private = {
      url = "github:dszakallas/dotfiles-private";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.flake-utils.follows = "flake-utils";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.pyproject-build-systems.follows = "pyproject-build-systems";
      inputs.uv2nix.follows = "uv2nix";
      inputs.davids-dotfiles-common.follows = "davids-dotfiles-common";
    };
  };

  nixConfig = {
    extra-experimental-features = [
      "nix-command"
      "flakes"
      "configurable-impure-env"
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
      flake-utils,
      davids-dotfiles-common,
      ...
    }:
    let
      ctx = (inputs // outputs);
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
            (import ./hosts/${host} ctx)
            {
              home-manager = {
                extraSpecialArgs = specialArgs;
              };
            }
          ];
        };
      inherit (davids-dotfiles-common) lib;
      outputs =
        (flake-utils.lib.eachDefaultSystem (system: {
          packages.npm = import ./node2nix-pkgs {
            pkgs = nixpkgs.legacyPackages.${system};
            nodejs = nixpkgs.legacyPackages.${system}.nodejs_20;
            inherit system;
          };
        }))
        // flake-utils.lib.eachDefaultSystemPassThrough (system: {
          # Extract to dotfiles-common once it is more generic
          darwinModules = lib.importDir ./modules/darwin ctx;
          users = lib.importDir ./users ctx;

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
        });
    in
    outputs;
}
