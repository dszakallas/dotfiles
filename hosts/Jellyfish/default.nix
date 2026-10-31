{
  self,
  bikeshed,
  bikeshed-homelab,
  bikeshed-emacs,
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
    bikeshed-homelab.systemModules.jupiter
    systemModules.default
    darwinModules.default
    darwinModules.podman
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
        enable = false;
        package = pkgs.darwin.linux-builder-vz;
        ephemeral = true;
        maxJobs = 8;
        config = {
          fileSystems."/" = lib.mkForce {
            device = "tmpfs";
            fsType = "tmpfs";
            neededForBoot = true;
            options = [
              "mode=0755"
              "size=32G"
            ];
          };

          nix.settings.build-dir = "/nix/.rw-store/builds";

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
        "antigravity-par"
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
          bikeshed-emacs.homeModules.emacs
          bikeshed.homeModules.github
          bikeshed.homeModules.agents
          bikeshed.homeModules.ssh
          bikeshed-homelab.homeModules.default
          bikeshed-homelab.homeModules.jupiter
          bikeshed-homelab.homeModules.kolobok
          homeModules.id
          homeModules.git-operator
          homeModules.doom-config
          homeModules.reverse-engineering
        ];

        home = {
          username = primaryUser;
          homeDirectory = "/Users/${primaryUser}";
          stateVersion = "24.05";
          packages = [
            packages.${system}.antigravity-par
            packages.${system}.notebooklm-py
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
            playwright-mcp
            gogcli
            poppler-utils
          ]);
        };

        programs.zsh.envExtra = ''
          export PASEO_AGY_ACP_BIN="${
            packages.${system}.antigravity-par
          }/libexec/antigravity-par/agy_acp_server.par"
        '';

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
                    # Include every shared memory fragment for each configured agent.
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
                inherit (bikeshed.packages.${system}.mcp-servers) chrome-devtools;
                inherit (packages.${system}.mcp-servers) rea;
              };
              mkMcp = {
                servers = mcpServers;
              };
              mcpAgents = bikeshed.lib.agents.popularHarnesses;
            in
            {
              enable = true;
              skills.enable = true;
              skills.entries =
                bikeshed.packages.${system}.agentskills
                // packages.${system}.agentskills
                // {
                  bikeshed-skills = pkgs.mkSkill {
                    name = "bikeshed-skills";
                    version = "unstable";
                    src = bikeshed;
                  };
                };
              harnesses =
                (lib.foldl'
                  (
                    a: v:
                    a
                    // {
                      "${v}" = {
                        enable = true;
                        memory = {
                          enable = true;
                          source =
                            let
                              homeConf = bikeshed.lib.agents.harnesses.${v}.homeConfiguration;
                              agentConf = {
                                memory = {
                                  directory = homeConf.defaultMemoryDirectory or homeConf.defaultUserDirectory;
                                  target = homeConf.defaultMemoryFile;
                                };
                              };
                            in
                            mkMemory agentConf { };
                        };
                      }
                      // lib.optionalAttrs (builtins.elem v mcpAgents) { mcp = mkMcp; }
                      // lib.optionalAttrs (v == "claude" || v == "copilot" || v == "antigravity" || v == "codex") {
                        # non-free, self-updating tools, better installed with Homebrew
                        package = null;
                      }
                      // lib.optionalAttrs (v == "claude") {
                        wrapper.executable = "${config.bikeshed.brew.prefix}/bin/claude";
                      };
                    }
                  )
                  { }
                  [
                    "claude"
                    "copilot"
                    "antigravity"
                    "opencode"
                    "codex"
                  ]
                )
                // {
                  claude-qwen = {
                    enable = true;
                    type = "claude";
                    package = null;
                    wrapper.executable = "${config.bikeshed.brew.prefix}/bin/claude";
                    wrapper.initExtra = ''
                      export ANTHROPIC_BASE_URL="''${BAILIAN_BASE_URL}"
                      export ANTHROPIC_AUTH_TOKEN="''${BAILIAN_API_KEY}"
                      export ANTHROPIC_API_KEY=""
                      export ANTHROPIC_DEFAULT_OPUS_MODEL="qwen3.7-max"
                      export ANTHROPIC_DEFAULT_SONNET_MODEL="qwen3.7-plus"
                      export ANTHROPIC_DEFAULT_HAIKU_MODEL="qwen3.7-flash"
                      export CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1
                      export CLAUDE_CODE_DISABLE_TELEMETRY=1
                    '';
                  };
                };
            };
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
