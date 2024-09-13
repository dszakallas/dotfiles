{
  description = "my-darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-experimental-features = [ "nix-command" "flakes" ];
    extra-substituters = [ "https://nix-community.cachix.org" "https://devenv.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, ... }:
  let
    system = "aarch64-darwin";
    mkDarwinCfg = name: nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
          inherit self home-manager system;
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
