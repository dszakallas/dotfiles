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
    bikeshed-pure.darwinModules.default
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
      "claude"
      "claude-code"
      "google-gemini"
      "ollama-app"
      "plexamp"
      "stats"
      "ukelele"
    ];

    ids.gids.nixbld = 350;

    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) (
        [
          "github-copilot-cli"
        ]
        ++ bikeshed-pure.lib.pure.unfreePackages
      );

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
          bikeshed.homeModules.github
          bikeshed.homeModules.ssh
          bikeshed-homelab.homeModules.default
          bikeshed-pure.homeModules.default
          homeModules.id
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
            jira.enable = true;
          };

          # Impure brew programs
          brew = {
            enable = true;
            prefix = "/opt/homebrew";
          };

          k8stools.enable = true;

          agents =
            let
              mkMemory =
                agentConf: extra:
                let
                  memoryFiles = [
                    ./home.md
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
                inherit (bikeshed-pure.packages.${system}.mcp-servers) glean atlassian-mcp atlassian-mcp-cloud;
                inherit (bikeshed.packages.${system}.mcp-servers) chrome-devtools;
              };
            in
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
              claude = {
                enable = true;
                memory = {
                  enable = true;
                  source = mkMemory config.bikeshed.agents.claude { };
                };
                mcp.servers = bikeshed.lib.agents.mcpServersForAgent "claude" mcpServers;
                # Installed with Homebrew
                package = null;
              };
            };
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
              github-pure = {
                enable = true;
                credential = {
                  enable = true;
                  helper = bikeshed.lib.git.mkEnvCredentialHelper "PURE_PROD_KRYPTON_GITHUB_PRIVATE_";
                };
              };
              dszakallas = {
                enable = true;
                sshIdentity = [ "sk1" ];
                credential = {
                  enable = true;
                  helper = bikeshed.lib.git.mkEnvCredentialHelper "GITHUB_PRIVATE_";
                };
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
