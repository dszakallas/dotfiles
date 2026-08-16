{
  self,
  bikeshed,
  bikeshed-homelab,
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
    bikeshed.darwinModules.litellm
    bikeshed-homelab.systemModules.jupiter
    systemModules.default
    darwinModules.default
    darwinModules.podman
  ];

  config = {
    sops = {
      defaultSopsFile = ./secrets.sec.yaml;
      secrets."litellm/master_key" = { };
      templates."litellm-env".content = ''
        LITELLM_MASTER_KEY=${config.sops.placeholder."litellm/master_key"}
      '';
    };

    services.litellm = {
      enable = true;
      environmentFile = config.sops.templates."litellm-env".path;
    };
    system = { inherit primaryUser; };

    homebrew.casks = [
      "antigravity"
      "antigravity-cli"
      "calibre"
      "claude"
      "claude-code"
      "copilot-cli"
      "discord"
      "google-drive"
      "google-gemini"
      "ollama-app"
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
          bikeshed.homeModules.emacs
          bikeshed.homeModules.github
          bikeshed.homeModules.agents
          bikeshed.homeModules.ssh
          bikeshed-homelab.homeModules.default
          bikeshed-homelab.homeModules.jupiter
          bikeshed-homelab.homeModules.kolobok
          homeModules.id
        ];

        home = {
          username = primaryUser;
          homeDirectory = "/Users/${primaryUser}";
          stateVersion = "24.05";
          packages = [
            packages.${system}.notebooklm-py
          ]
          ++ (with pkgs; [
            (fluxcd.withPlugins (p: [
              p.schema
              p.mirror
            ]))
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
                  memory = [
                    ./home.md
                    ../shared/instructions/worktrees.md
                  ];
                  concatenatedMemory = pkgs.writeText "concatenated-memory" (
                    "# User-level memory\n\n"
                    + lib.concatMapStrings (f: builtins.readFile f + "\n") memory
                    + lib.concatStringsSep "\n" (lib.attrValues bikeshed.lib.agents.memory)
                    + lib.concatStringsSep "\n" (lib.attrValues bikeshed-homelab.lib.agents.memory)
                  );
                in
                (pkgs.replaceVars concatenatedMemory (
                  {
                    agentMemoryDirectory = agentConf.memory.directory;
                    agentMemoryFile = agentConf.memory.target;
                  }
                  // extra
                ));
              mcpServers = {
                inherit (bikeshed-homelab.lib.agents.mcpServers) ibkr;
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
                "claude"
                "copilot"
                "antigravity"
                "opencode"
              ];
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
                      source = mkMemory config.bikeshed.agents."${v}" { };
                    };
                  }
                  // lib.optionalAttrs (builtins.elem v mcpAgents) { mcp = mkMcp v; }
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
                  bikeshed-skills = pkgs.mkSkill {
                    name = "bikeshed-skills";
                    version = "unstable";
                    src = bikeshed;
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
              dszakallas = {
                enable = true;
                sshIdentity = [ "sk1" ];
                credential = {
                  enable = true;
                  username = "dszakallas-all-ro";
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
