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
        davids-dotfiles-common.homeModules.agents
        davids-dotfiles-private.homeModules.default
        davids-dotfiles-private.homeModules.jupiter
        davids-dotfiles-private.homeModules.kolobok
        homeModules.id
      ];

      home = {
        username = "davidszakallas";
        homeDirectory = "/Users/davidszakallas";
        stateVersion = "24.05";
        packages = [
          packages.${system}.notebooklm-py
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
          gogcli
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
              let
                memory = [
                  ../shared/instructions/home.md
                  ../shared/instructions/worktrees.md
                ];
                concatenatedMemory = pkgs.writeText "concatenated-memory" (
                  "# User-level memory\n\n"
                  + lib.concatMapStrings (f: builtins.readFile f + "\n") memory
                  + lib.concatStringsSep "\n" (lib.attrValues davids-dotfiles-common.lib.agents.memory)
                  + lib.concatStringsSep "\n" (lib.attrValues davids-dotfiles-private.lib.agents.memory.personal)
                );
              in
              (pkgs.replaceVars concatenatedMemory (
                {
                  agentMemoryDirectory = agentConf.memory.directory;
                  agentMemoryFile = agentConf.memory.target;
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
                  memory = {
                    enable = true;
                    source = mkMemory config.davids.agents."${v}" { };
                  };
                }
                // lib.optionalAttrs (v == "claude" || v == "copilot" || v == "antigravity") {
                  # non-free, self-updating tools, better installed with Homebrew
                  package = null;
                };
              }
            )
            {
              enable = true;
              skills.enable = true;
              skills.entries = packages.${system}.agentskills // {
                dotfiles-common-skills = pkgs.mkSkill {
                  name = "davids-dotfiles-common-skills";
                  version = "unstable";
                  src = davids-dotfiles-common;
                };
              };
            }
            [
              "claude"
              "copilot"
              "antigravity"
              "opencode"
            ];
        ssh = {
          enable = true;
          agent.enable = true;
        };
        git = {
          enable = true;
          userPresets = {
            github-user1.enable = true;
            dszakallas.enable = true;
          };
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
