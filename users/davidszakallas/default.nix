{
  self,
  davids-dotfiles-common,
  davids-dotfiles-private,
  homeModules,
  packages,
  ...
}:
{
  pkgs,
  lib,
  system,
  ...
}:
{
  users.users.davidszakallas = {
    name = "davidszakallas";
    home = "/Users/davidszakallas";
    shell = pkgs.zsh;
  };

  # Allow proprietary agents :(
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
      "github-copilot-cli"
    ];

  home-manager.users.davidszakallas =
    { config, ... }:
    rec {
      imports = [
        davids-dotfiles-common.homeModules.base
        davids-dotfiles-common.homeModules.emacs
        davids-dotfiles-common.homeModules.github
        davids-dotfiles-private.homeModules.default
        davids-dotfiles-private.homeModules.jupiter
        davids-dotfiles-private.homeModules.kolobok
        homeModules.id
        homeModules.agents
      ];

      home = {
        username = "davidszakallas";
        homeDirectory = "/Users/davidszakallas";
        stateVersion = "24.05";
        packages = [
        ]
        ++ (with pkgs; [
          fluxcd-operator
          ffmpeg
          asciinema
          awscli2
          minio-client
          backblaze-b2
          rclone
          yt-dlp
          google-cloud-sdk
          playwright-mcp
        ]);
      };

      programs.ssh.matchBlocks =
        builtins.listToAttrs (
          builtins.map
            (name: {
              inherit name;
              value = {
                match = "host ${name}";
                user = "gamer";
                identitiesOnly = true;
                identityFile = "~/.ssh/gamer@${name}";
                forwardAgent = true;
                serverAliveInterval = 5;
                sendEnv = [ "NIX_CONFIG" ];
              };
            })
            [
              "callisto"
              #"amalthea"
            ]
        )
        // {
          "sparkplug" = {
            match = "host sparkplug";
            forwardAgent = true;
            identitiesOnly = true;
            user = "david";
            sendEnv = [ "NIX_CONFIG" ];
            serverAliveInterval = 5;
            identityFile = "~/.ssh/sparkplug";
          };
        };

      programs.home-manager.enable = true;

      davids = {
        # Impure brew programs
        brew = {
          enable = true;
          prefix = "/opt/homebrew";
        };
        k8stools = {
          enable = true;
        };
        emacs = {
          enable = true;
          daemon.enable = true;
          spacemacs = {
            enable = true;
          };
        };
        jupiter.enable = true;
        kolobok.enable = true;
        id = {
          enable = true;
        };
        agents =
          let
            mkMemory =
              agentConf: extra:
              (pkgs.replaceVars ./MEMORY.md (
                {
                  agentUserDirectory = agentConf.userDirectory;
                  agentMainMemoryFile = agentConf.memory.main.target;
                  userLevelFilesExtraH3 = "";
                  packageManagentExtraH3 = "";
                  workTreesExtraH3 = "";
                }
                // extra
              ));
          in
          lib.foldl'
            (
              a: v:
              a
              // {
                "${v}" = {
                  enable = true;
                  memory.enable = true;
                  memory.main.enable = true;
                  memory.main.source = mkMemory config.davids.agents."${v}" { };
                };
              }
            )
            {
              enable = true;
            }
            [
              "gemini"
              "claude"
              "copilot"
            ];
        ssh = {
          enable = true;
          agent.enable = true;
        };
        git = {
          enable = true;
        };
        github = {
          enable = true;
          ssh = {
            enable = true;
          };
        };
      };
    };
}
