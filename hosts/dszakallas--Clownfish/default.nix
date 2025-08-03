{
  self,
  darwinModules,
  davids-dotfiles-common,
  users,
  ...
}:
let
  primaryUser = "dszakallas";
in
{
  imports = [
    davids-dotfiles-common.systemModules.default
    darwinModules.base
    users.${primaryUser}
  ];

  system = { inherit primaryUser; };

  nix.settings.trusted-users = [
    primaryUser
  ];

  homebrew.casks = [
    "logseq"
    "ukelele"
  ];

  ids.gids.nixbld = 350;

  # TODO: Replace with fine-grained and mergable alternative
  nixpkgs.config.allowUnfree = true;
}
