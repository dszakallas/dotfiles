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
      nixpkgs,
      nix-darwin,
      home-manager,
      flake-utils,
      davids-dotfiles-common,
      ...
    }:
    let
      inherit (davids-dotfiles-common.lib) importRec importRec1 callPackageWithRec;
      inherit (nixpkgs) lib;
      pkgsFor = system: nixpkgs.legacyPackages.${system}.extend overlays;
      overlays = lib.foldl' lib.composeExtensions (_: _: { }) (lib.attrValues (importRec ./overlays));
      ctx = (inputs // outputs);
      mkDarwin =
        { host, arch, ... }:
        nix-darwin.lib.darwinSystem rec {
          system = "${arch}-darwin";
          specialArgs =
            let
              hostPlatform = (pkgsFor system).stdenv.hostPlatform;
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
      outputs =
        (flake-utils.lib.eachDefaultSystem (
          system:
          let
            pkgs = pkgsFor system;
          in
          {
            packages = callPackageWithRec (inputs // pkgs) ./pkgs;
          }
        ))
        // flake-utils.lib.eachDefaultSystemPassThrough (system: {
          systemModules = importRec1 ./modules/system ctx;
          # Extract to dotfiles-common once it is more generic
          darwinModules = importRec1 ./modules/darwin ctx;
          homeModules = importRec1 ./modules/home ctx;
          users = importRec1 ./users ctx;

          inherit overlays;

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
