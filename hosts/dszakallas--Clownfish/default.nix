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
    darwinModules.default
    darwinModules.p10y
    users.${primaryUser}
  ];

  system = { inherit primaryUser; };

  davids.emacs = {
    enable = true;
    version = "29";
  };

  nix.settings.trusted-users = [
    primaryUser
  ];

  ids.gids.nixbld = 350;

  # TODO: Replace with fine-grained and mergable alternative
  nixpkgs.config.allowUnfree = true;
}
