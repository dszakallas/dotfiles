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

      # TODO: Make it more generic and move to davids-dotfiles-common
      registry = lib.attrsets.mapAttrs (name: value: {
        exact = true;
        from = {
          id = name;
          type = "indirect";
        };
        flake = value;
      }) flakeInputs;

      nixPath = map (v: "${v}=flake:${v}") (builtins.attrNames flakeInputs);
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
