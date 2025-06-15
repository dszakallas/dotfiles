{
  self,
  darwinModules,
  davids-dotfiles-common,
  users,
  ...
}:
let
  myUsername = "dszakallas";
in
{
  imports = [
    davids-dotfiles-common.systemModules.default
    darwinModules.default
    darwinModules.p10y
    users.${myUsername}
  ];

  davids.emacs = {
    enable = true;
    version = "29";
  };

  nix.settings.trusted-users = [
    "root"
    myUsername
  ];

  ids.gids.nixbld = 350;

  # TODO: Replace with fine-grained and mergable alternative
  nixpkgs.config.allowUnfree = true;
}
