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
    darwinModules.base
    users.${primaryUser}
  ];

  system = { inherit primaryUser; };

  homebrew.casks = [
    "calibre"
    "discord"
    "google-drive"
    "logseq"
    "signal"
    "slack"
    "spotify"
    "syncthing-app"
    "ukelele"
    "zoom"
  ];

  nix.settings.trusted-users = [
    primaryUser
  ];

  davids.jupiter = {
    enable = true;
    amalthea.staticIP.v4 = "192.168.1.244";
    callisto.staticIP.v4 = "192.168.1.144";
  };
}
