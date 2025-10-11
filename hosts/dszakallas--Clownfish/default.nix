{
  self,
  darwinModules,
  davids-dotfiles-common,
  users,
  ...
}@inputs:
{
  lib,
  ...
}:
let
  primaryUser = "dszakallas";
  flakeInputs = (lib.filterAttrs (_: v: (lib.hasAttr "_type" v) && (v._type == "flake")) inputs);
in
{
  imports = [
    davids-dotfiles-common.systemModules.default
    darwinModules.base
    users.${primaryUser}
  ];

  config = {
    system = { inherit primaryUser; };

    nix = {
      settings.trusted-users = [
        primaryUser
      ];
    };

    davids.nix = {
      enable = true;
      pinnedFlakes = flakeInputs;
    };

    homebrew.casks = [
      "logseq"
      "ukelele"
    ];

    ids.gids.nixbld = 350;

    # TODO: Replace with fine-grained and mergable alternative
    nixpkgs.config.allowUnfree = true;
  };
}
