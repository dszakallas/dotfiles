{ self, davids-dotfiles, davids-dotfiles-private, ... }@inputs:
let myUsername = "davidszakallas";
in {
  imports = [
    davids-dotfiles.systemModules.default
    davids-dotfiles.darwinModules.default
    davids-dotfiles.darwinModules.homeapps
    davids-dotfiles-private.systemModules.jupiter
    davids-dotfiles-private.systemModules.kolobok
    davids-dotfiles.users.${myUsername}
  ];

  nix.settings.trusted-users = [ "root" myUsername ];

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
