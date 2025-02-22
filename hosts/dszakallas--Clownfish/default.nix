{
  self,
  systemModules,
  darwinModules,
  users,
  ...
}:
let
  myUsername = "dszakallas";
in
{
  imports = [
    systemModules.default
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
