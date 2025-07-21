{
  self,
  darwinModules,
  davids-dotfiles-common,
  davids-dotfiles-private,
  users,
  ...
}@inputs:
let
  primaryUser = "davidszakallas";
in
{
  imports = [
    davids-dotfiles-common.systemModules.default
    davids-dotfiles-private.systemModules.jupiter
    darwinModules.default
    darwinModules.homeapps
    darwinModules.p10y
    users.${primaryUser}
  ];

  system = { inherit primaryUser; };

  nix.settings.trusted-users = [
    primaryUser
  ];

  davids.jupiter = {
    enable = true;
    amalthea.staticIP.v4 = "192.168.1.244";
    callisto.staticIP.v4 = "192.168.1.144";
  };
}
