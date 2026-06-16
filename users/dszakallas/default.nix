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
  system,
  lib,
  ...
}:
{
  users.users.dszakallas = {
    name = "dszakallas";
    home = "/Users/dszakallas";
    shell = pkgs.zsh;
  };

  home-manager.users.dszakallas =
    { config, ... }:
    {
      imports = [
        davids-dotfiles-common.homeModules.base
        davids-dotfiles-common.homeModules.agents
        davids-dotfiles-common.homeModules.emacs
        davids-dotfiles-common.homeModules.github
        davids-dotfiles-private.homeModules.default
        davids-dotfiles-private.homeModules.pure
        homeModules.id
        homeModules.spacemacs-config
      ];

      home = {
        username = "dszakallas";
        homeDirectory = "/Users/dszakallas";
        stateVersion = "24.05";
        # TODO move to common
        packages = [
        ]
        ++ (with pkgs; [
          fluxcd-operator
          temporal-cli
        ]);
      };

      programs.home-manager.enable = true;

      davids = {
        # Impure brew programs
        brew = {
          enable = true;
          prefix = "/opt/homebrew";
        };

        k8stools.enable = true;
        emacs = {
          enable = true;
          daemon.enable = true;
          spacemacs = {
            enable = true;
          };
        };
        pure.enable = true;
        id.enable = true;

        agents =
          let
            mkMemory =
              agentConf: extra:
              let
                memoryFiles = [
                  ../instructions/user.md
                  ../instructions/worktrees.md
                  ../instructions/tropes.md
                ];
                concatenatedMemory = pkgs.writeText "concatenated-memory" (
                  "# User-level memory\n\n"
                  + lib.concatMapStrings (f: builtins.readFile f + "\n") memoryFiles
                  + davids-dotfiles-private.lib.agents.memory.pure.purelogin
                  + davids-dotfiles-private.lib.agents.memory.pure.commitConventions
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
              skills.entries = lib.mapAttrs (name: _: ../skills + "/${name}") (
                lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../skills)
              );
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
        git.enable = true;
        github = {
          enable = true;
          ssh = {
            enable = true;
          };
        };
      };
    };
}
