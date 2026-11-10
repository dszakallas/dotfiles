{
  self,
  beads,
  bikeshed,
  bikeshed-homelab,
  bikeshed-emacs,
  darwinModules,
  systemModules,
  homeModules,
  overlays,
  packages,
  ...
}@ctx:
{
  lib,
  pkgs,
  config,
  system,
  ...
}:
let
  primaryUser = "davidszakallas";
in
{
  imports = [
    bikeshed.systemModules.default
    bikeshed-homelab.systemModules.jupiter
    systemModules.default
    darwinModules.default
  ];

  config = {
    sops = {
      defaultSopsFile = ./secrets.sec.yaml;
    };

    system = { inherit primaryUser; };

    homebrew.casks = [
      "antigravity"
      "antigravity-cli"
      "calibre"
      "claude"
      "claude-code"
      "codex"
      "discord"
      "font-mononoki-nerd-font"
      "font-symbols-only-nerd-font"
      "google-drive"
      "google-gemini"
      "paseo"
      "plexamp"
      "signal"
      "slack"
      "spotify"
      "stats"
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
        package = pkgs.darwin.linux-builder-vz;
        ephemeral = true;
        maxJobs = 8;
        config = {
          virtualisation = {
            darwin-builder = {
              diskSize = 64 * 1024;
              memorySize = 16 * 1024;
            };
            cores = 8;
          };
        };
      };
    };

    bikeshed.jupiter = {
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

    users.users.${primaryUser} = {
      name = primaryUser;
      home = "/Users/${primaryUser}";
      shell = pkgs.zsh;
    };

    home-manager.users.${primaryUser} =
      { config, ... }:
      {
        imports = [
          bikeshed.homeModules.base
          bikeshed.homeModules.git
          bikeshed.homeModules.podman
          bikeshed-emacs.homeModules.emacs
          bikeshed.homeModules.github
          bikeshed.homeModules.ssh
          bikeshed-homelab.homeModules.default
          bikeshed-homelab.homeModules.jupiter
          bikeshed-homelab.homeModules.kolobok
          homeModules.id
          homeModules.git-operator
          homeModules.doom-config
          (import ./agents.nix ctx)
        ];

        home = {
          username = primaryUser;
          homeDirectory = "/Users/${primaryUser}";
          stateVersion = "24.05";
          packages = [
            packages.${system}.notebooklm-py
            beads.packages.${system}.bd
          ]
          ++ (with pkgs; [
            (fluxcd.withPlugins (p: [
              p.schema
              p.mirror
              p.operator
            ]))
            fluxcd-operator
            ffmpeg
            asciinema
            awscli2
            backblaze-b2
            rclone
            yt-dlp
            google-cloud-sdk
            gogcli
            poppler-utils
          ]);
        };

        programs.ssh.settings =
          builtins.listToAttrs (
            builtins.map
              (name: {
                name = "Match host ${name}";
                value = {
                  User = "gamer";
                  IdentitiesOnly = true;
                  IdentityFile = "~/.ssh/gamer@${name}";
                  ForwardAgent = true;
                  ServerAliveInterval = 5;
                  SendEnv = [ "NIX_CONFIG" ];
                };
              })
              [
                "callisto"
                #"amalthea"
              ]
          )
          // {
            "Match host sparkplug" = {
              ForwardAgent = true;
              IdentitiesOnly = true;
              User = "david";
              SendEnv = [ "NIX_CONFIG" ];
              ServerAliveInterval = 5;
              IdentityFile = "~/.ssh/sparkplug";
            };
          };

        programs.home-manager.enable = true;

        davids.id = {
          enable = true;
          identity = [ "sk1" ];
        };

        bikeshed = {
          jupiter.enable = true;
          kolobok.enable = true;

          # Impure brew programs
          brew = {
            enable = true;
            prefix = "/opt/homebrew";
          };
          k8stools = {
            enable = true;
          };
          devenv.enable = true;
          direnv.enable = true;
          emacs = {
            enable = true;
            daemon.enable = true;
            spacemacs = {
              enable = false;
            };
          };
          ssh = {
            enable = true;
            agent.enable = true;
          };
          podman = {
            enable = true;
            desktop.enable = true;
            dockerCompat.enable = true;
          };
          git = {
            enable = true;
            userPresets = {
              github-user1.enable = true;
              dszakallas = {
                enable = true;
                sshIdentity = [ "sk1" ];
                credential = {
                  enable = true;
                  helper = bikeshed.lib.git.mkEnvCredentialHelper "GITHUB_PRIVATE_";
                };
              };
              dszakallas-kolobok = {
                enable = true;
                sshIdentity = [ "sk1" ];
                credential.enable = true;
              };
            };
          };
          github = {
            enable = true;
            ssh = {
              enable = true;
            };
            extensions = [ pkgs.gh-stack ];
          };
        };
      };
  };
}
