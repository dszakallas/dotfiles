{
  self,
  bikeshed,
  bikeshed-homelab,
  bikeshed-pure,
  darwinModules,
  systemModules,
  homeModules,
  overlays,
  packages,
  ...
}:
{
  lib,
  pkgs,
  system,
  ...
}:
let
  primaryUser = "dszakallas";
in
{
  imports = [
    bikeshed.systemModules.default
    systemModules.default
    darwinModules.default
    darwinModules.podman
  ];

  config = {
    system = { inherit primaryUser; };

    services.openssh.extraConfig = ''
      PasswordAuthentication no
      ChallengeResponseAuthentication no
    '';

    nix = {
      settings.trusted-users = [
        primaryUser
      ];
    };

    homebrew.casks = [
      "antigravity"
      "antigravity-cli"
      "claude"
      "claude-code"
      "copilot-cli"
      "google-gemini"
      "ollama-app"
      "plexamp"
      "stats"
      "ukelele"
    ];

    ids.gids.nixbld = 350;

    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "vault"
        "terraform"
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
          bikeshed.homeModules.agents
          bikeshed.homeModules.emacs
          bikeshed.homeModules.github
          bikeshed.homeModules.ssh
          bikeshed-homelab.homeModules.default
          bikeshed-pure.homeModules.default
          homeModules.id
          homeModules.spacemacs-config
        ];

        home = {
          username = primaryUser;
          homeDirectory = "/Users/${primaryUser}";
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

        davids.id = {
          enable = true;
          identity = [ "sk1" ];
        };

        bikeshed = {
          pure = {
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
                    + lib.concatStringsSep "\n" (lib.attrValues bikeshed.lib.agents.memory)
                    + lib.concatStringsSep "\n" (lib.attrValues bikeshed-pure.lib.agents.memory)
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
                inherit (bikeshed-pure.lib.agents.mcpServers) glean atlassian-mcp atlassian-mcp-cloud;
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
                servers = bikeshed.lib.agents.mcpServersForAgent agent mcpServers;
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
                          source = mkMemory config.bikeshed.agents."${v}" { };
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
                  inherit (packages.${system}.agentskills) local whobson-python-skills mattpocock-skills;
                  bikeshed-skills = pkgs.mkSkill {
                    name = "bikeshed-skills";
                    version = "unstable";
                    src = bikeshed;
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
            matchBlocks."dev-dszakallas-reef" = {
              match = "host dev-dszakallas-reef";
              IdentityFile = "~/.ssh/id_ed25519_vault";
              CertificateFile = "~/.ssh/id_ed25519_vault-cert.pub";
            };
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
  };
}
