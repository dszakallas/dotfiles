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
      "antigravity"
      "antigravity-cli"
      "calibre"
      "claude"
      "discord"
      "google-drive"
      "google-gemini"
      "ollama-app"
      "plexamp"
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
            cores = 8;
          };
        };
      };
    };

    davids.jupiter = {
      enable = true;
      amalthea.staticIP.v4 = "192.168.1.244";
      callisto.staticIP.v4 = "192.168.1.144";
    };
    # Allow proprietary agents :(
    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "claude-code"
        "github-copilot-cli"
      ];
  };
}
