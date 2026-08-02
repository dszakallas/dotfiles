{
  self,
  davids-dotfiles-common,
  davids-dotfiles-private,
  davids-bikeshed-pure,
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
        davids-dotfiles-common.homeModules.ssh
        davids-dotfiles-private.homeModules.default
        davids-bikeshed-pure.homeModules.default
        homeModules.id
        homeModules.spacemacs-config
      ];

      home = {
        username = "dszakallas";
        homeDirectory = "/Users/dszakallas";
        stateVersion = "24.05";
        # TODO move to common
        packages = [
          packages.${system}.notebooklm-py
        ]
        ++ (with pkgs; [
          (fluxcd.withPlugins (p: [
            p.schema
            p.mirror
          ]))
          fluxcd-operator
          temporal-cli
          gogcli
          uv
        ]);
      };

      programs.home-manager.enable = true;

      bikeshed.pure = {
        enable = true;
        python = {
          enable = true;
          setPurePypiMirrorAsDefault = true;
          setPureExtraIndexes = true;
        };
        go = {
          enable = true;
          setPureGoProxy = true;
        };
      };

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
        id = {
          enable = true;
          identity = [ "sk1" ];
        };

        agents =
          let
            mkMemory =
              agentConf: extra:
              let
                memoryFiles = [
                  ../shared/instructions/home.md
                  ../shared/instructions/worktrees.md
                ];
                concatenatedMemory = pkgs.writeText "concatenated-memory" (
                  "# User-level memory\n\n"
                  + lib.concatMapStrings (f: builtins.readFile f + "\n") memoryFiles
                  + lib.concatStringsSep "\n" (lib.attrValues davids-dotfiles-common.lib.agents.memory)
                  + lib.concatStringsSep "\n" (lib.attrValues davids-bikeshed-pure.lib.agents.memory)
                );
              in
              (pkgs.replaceVars concatenatedMemory (
                {
                  agentMemoryDirectory = agentConf.memory.directory;
                  agentMemoryFile = agentConf.memory.target;
                }
                // extra
              ));

            # User-level (global) MCP servers, specified once in the generic
            # schema and transformed per agent.
            mcpServers = {
              inherit (davids-bikeshed-pure.lib.agents.mcpServers) glean atlassian-mcp;
              chrome-devtools = {
                type = "stdio";
                command = "npx";
                args = [
                  "-y"
                  "chrome-devtools-mcp@latest"
                  "--no-usage-statistics"
                  "--no-performance-crux"
                ];
                env = { };
              };
            };
            mkMcp = agent: {
              servers = davids-dotfiles-common.lib.agents.mcpServersForAgent agent mcpServers;
            };
            mcpAgents = [
              "gemini"
              "claude"
              "copilot"
              "antigravity"
              "opencode"
            ];

            shared-skills = pkgs.stdenvNoCC.mkDerivation {
              name = "shared-skills";
              src = ../shared;
              dontBuild = true;
              installPhase = ''
                mkdir -p $out
                cp -r $src/* $out/
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
                }
                // lib.optionalAttrs (builtins.elem v mcpAgents) { mcp = mkMcp v; }
                // lib.optionalAttrs (v == "claude" || v == "copilot") {
                  # Installed with Homebrew
                  package = null;
                };
              }
            )
            {
              enable = true;
              skills.enable = true;
              skills.entries = {
                inherit (packages.${system}.agentskills) local;
                dotfiles-common-skills = pkgs.mkSkill {
                  name = "davids-dotfiles-common-skills";
                  version = "unstable";
                  src = davids-dotfiles-common;
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
          userPresets = {
            github-pure.enable = true;
            dszakallas = {
              enable = true;
              sshIdentity = [ "sk1" ];
            };
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
