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
                memoryFiles = [
                  ../shared/instructions/user.md
                  ../shared/instructions/worktrees.md
                  ../shared/instructions/tropes.md
                ];
                concatenatedMemory = pkgs.writeText "concatenated-memory" (
                  "# User-level memory\n\n"
                  + lib.concatMapStrings (f: builtins.readFile f + "\n") memoryFiles
                  + davids-dotfiles-common.lib.agents.memory.commitConventions
                );
              in
              (pkgs.replaceVars concatenatedMemory (
                {
                  agentMemoryDirectory = agentConf.memory.directory;
                  agentMemoryFile = agentConf.memory.target;
                }
                // extra
              ));

            shared-skills = pkgs.stdenvNoCC.mkDerivation {
              name = "dotfiles-skills";
              src = ../shared/skills;
              dontBuild = true;
              installPhase = ''
                mkdir -p $out/skills
                cp -r $src/* $out/skills/
              '';
            };
          in
          lib.foldl'
            (
              a: v:
              a
              // {
                "${v}" = {
                  enable = true;
                  memory =
                    if v == "gemini" then
                      {
                        enable = false;
                      }
                    else
                      {
                        enable = true;
                        source = mkMemory config.davids.agents."${v}" { };
                      };
                };
              }
            )
            {
              enable = true;
              skills.enable = true;
              skills.entries = {
                shared = shared-skills;
                dotfiles-common-skills = davids-dotfiles-common.lib.agents.mkSkill pkgs {
                  name = "dotfiles-common-skills";
                  version = "unstable";
                  src = davids-dotfiles-common;
                };
                cc-skills-golang = davids-dotfiles-common.lib.agents.mkSkill pkgs {
                  name = "cc-skills-golang";
                  version = "2026-07-02";
                  src = pkgs.fetchFromGitHub {
                    owner = "samber";
                    repo = "cc-skills-golang";
                    rev = "8b2d019212d6a5390d472a7660a8489109d7db49";
                    hash = "sha256-oSFApXKBndeM1wsl6GyPwiDuIgt5bGXWzDtpnmC6SaM=";
                  };
                };
              };
            }
            [
              "gemini"
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
