{
  self,
  darwinModules,
  davids-dotfiles-common,
  davids-dotfiles-private,
  users,
  ...
}@inputs:
{
  lib,
  ...
}:
let
  primaryUser = "davidszakallas";
  flakeInputs = (lib.filterAttrs (_: v: (lib.hasAttr "_type" v) && (v._type == "flake")) inputs);
in
{
  imports = [
    davids-dotfiles-common.systemModules.default
    davids-dotfiles-private.systemModules.jupiter
    darwinModules.base
    darwinModules.podman
    users.${primaryUser}
  ];

  config = {
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

    nix = {
      settings.trusted-users = [
        primaryUser
      ];
    };

    davids.nix = {
      enable = true;
      pinnedFlakes = flakeInputs;
    };

    davids.jupiter = {
      enable = true;
      amalthea.staticIP.v4 = "192.168.1.244";
      callisto.staticIP.v4 = "192.168.1.144";
    };
  };
}
