{
  self,
  davids-dotfiles-common,
  davids-dotfiles-private,
  darwinModules,
  systemModules,
  users,
  overlays,
  ...
}:
{
  lib,
  ...
}:
let
  primaryUser = "davidszakallas";
in
{
  imports = [
    davids-dotfiles-common.systemModules.default
    davids-dotfiles-private.systemModules.jupiter
    systemModules.default
    darwinModules.default
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
      linux-builder = {
        enable = true;
        ephemeral = true;
        maxJobs = 8;
        config = {
          virtualisation = {
            darwin-builder = {
              diskSize = 64 * 1024;
              memorySize = 12 * 1024;
            };
            cores = 4;
          };
        };
      };
    };

    davids.jupiter = {
      enable = true;
      amalthea.staticIP.v4 = "192.168.1.244";
      callisto.staticIP.v4 = "192.168.1.144";
    };
  };
}
