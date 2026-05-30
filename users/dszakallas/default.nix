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
        davids-dotfiles-common.homeModules.emacs
        davids-dotfiles-common.homeModules.github
        davids-dotfiles-private.homeModules.default
        davids-dotfiles-private.homeModules.pure
        homeModules.id
        homeModules.spacemacs-config
        homeModules.agents
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
              (pkgs.replaceVars ../MEMORY.md (
                {
                  agentMemoryDirectory = agentConf.memory.directory;
                  agentMemoryFile = agentConf.memory.target;
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
                  memory.source = mkMemory {
                    memory = {
                      directory = ".agents/${v}";
                      target = "MEMORY.md";
                    };
                  } { };

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
              "antigravity"
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
