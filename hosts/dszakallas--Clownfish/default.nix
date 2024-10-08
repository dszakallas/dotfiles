{ self, davids-dotfiles, ... }:
let
  myUsername = "dszakallas";
in
{
  imports = [
    davids-dotfiles.darwinModules.default
    "${self}/users/${myUsername}"
  ];

  nix.settings.trusted-users = [ "root" myUsername ];
}
