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
    extra-substituters =
      [ "https://nix-community.cachix.org" "https://devenv.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager
    , davids-dotfiles-private, poetry2nix, ... }:
    let
      davids-dotfiles = rec {
        lib = import ./lib { inherit (nixpkgs) lib; };
        darwinModules =
          builtins.mapAttrs (_: v: import v) (lib.subDirs ./modules/darwin);
        systemModules =
          builtins.mapAttrs (_: v: import v) (lib.subDirirs ./modules/system);
        homeModules =
          builtins.mapAttrs (_: v: import v) (lib.subDirs ./modules/home);
      };
      mkDarwin = { host, arch, ... }:
        nix-darwin.lib.darwinSystem rec {
          system = "${arch}-darwin";
          specialArgs = let
            hostPlatform = nixpkgs.legacyPackages.${system}.stdenv.hostPlatform;
          in {
            inherit self home-manager hostPlatform davids-dotfiles
              davids-dotfiles-private poetry2nix system nixConfig;
          };
          modules = [
            home-manager.darwinModules.home-manager
            ./hosts/${host}
            { home-manager = { extraSpecialArgs = specialArgs; }; }
          ];
        };
    in {
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
}
