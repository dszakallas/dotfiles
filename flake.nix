rec {
  description = "My personal Nix configuration";

  inputs = {
    self.submodules = true;
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
    bikeshed = {
      url = "path:./deps/bikeshed";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.flake-utils.follows = "flake-utils";
    };
    bikeshed-homelab = {
      url = "path:./deps/bikeshed-homelab";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.flake-utils.follows = "flake-utils";
      inputs.bikeshed.follows = "bikeshed";
    };
    bikeshed-pure = {
      url = "path:./deps/bikeshed-pure";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.flake-utils.follows = "flake-utils";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.pyproject-build-systems.follows = "pyproject-build-systems";
      inputs.uv2nix.follows = "uv2nix";
      inputs.bikeshed.follows = "bikeshed";
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
      bikeshed,
      bikeshed-pure,
      ...
    }:
    let
      inherit (bikeshed.lib) importRec importRec1 callPackageWithRec;
      inherit (nixpkgs) lib;
      pkgsFor = system: nixpkgs.legacyPackages.${system}.extend overlays;
      overlays = lib.foldl' lib.composeExtensions (_: _: { }) (
        lib.attrValues (importRec1 ./overlays ctx)
      );
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
          # Extract to bikeshed once it is more generic
          darwinModules = importRec1 ./modules/darwin ctx;
          homeModules = importRec1 ./modules/home ctx;

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

          homeConfigurations = {
            "dszakallas@dev-dszakallas-reef" =
              let
                system = "x86_64-linux";
                # Standalone home-manager configurations take a fixed `pkgs`
                # value, so the unfree allowlist (mirroring the one set at
                # the darwin system level for the other hosts) has to be
                # baked in here rather than via a `nixpkgs.config` option.
                pkgs = import nixpkgs {
                  inherit system;
                  overlays = [ overlays ];
                  config.allowUnfreePredicate =
                    pkg:
                    builtins.elem (lib.getName pkg) (
                      [
                        "github-copilot-cli"
                      ]
                      ++ bikeshed-pure.lib.pure.unfreePackages
                    );
                };
                hostPlatform = pkgs.stdenv.hostPlatform;
              in
              home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                extraSpecialArgs = {
                  inherit system hostPlatform;
                };
                modules = [ (import ./hosts/dev-dszakallas-reef ctx) ];
              };
          };
        });
    in
    outputs;
}
