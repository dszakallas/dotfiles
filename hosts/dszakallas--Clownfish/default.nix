{ self, davids-dotfiles, ... }:
let myUsername = "dszakallas";
in {
  imports = [
    davids-dotfiles.systemModules.default
    davids-dotfiles.darwinModules.default
    davids-dotfiles.darwinModules.p10y
    davids-dotfiles.users.${myUsername}
  ];

  davids.emacs = {
    enable = true;
    version = "29";
  };

  nix.settings.trusted-users = [ "root" myUsername ];
}
