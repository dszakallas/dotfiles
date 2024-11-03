{ self, davids-dotfiles, ... }:
let myUsername = "dszakallas";
in {
  imports = [
    davids-dotfiles.systemModules.default
    davids-dotfiles.darwinModules.default
    davids-dotfiles.users.${myUsername}
  ];

  nix.settings.trusted-users = [ "root" myUsername ];
}
