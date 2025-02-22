{
  self,
  davids-dotfiles-private,
  systemModules,
  darwinModules,
  users,
  ...
}@inputs:
let
  myUsername = "davidszakallas";
in
{
  imports = [
    systemModules.default
    darwinModules.default
    darwinModules.homeapps
    darwinModules.p10y
    davids-dotfiles-private.systemModules.jupiter
    davids-dotfiles-private.systemModules.kolobok
    users.${myUsername}
  ];

  nix.settings.trusted-users = [
    "root"
    myUsername
  ];

  davids.emacs = {
    enable = true;
    version = "30";
  };

  davids.jupiter = {
    enable = true;
    amalthea.staticIP.v4 = "192.168.1.244";
    callisto.staticIP.v4 = "192.168.1.144";
  };

  davids.kolobok = {
    enable = true;
    internalServices.staticIP.v4 = "192.168.1.186";
  };
}
