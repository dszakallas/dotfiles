{ self, davids-dotfiles, ... }:
let myUsername = "davidszakallas";
in {
  imports = [
    davids-dotfiles.darwinModules.default
    davids-dotfiles.darwinModules.homeapps
    "${self}/users/${myUsername}"
  ];

  nix.settings.trusted-users = [ "root" myUsername ];
}
