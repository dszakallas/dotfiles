{
  bikeshed,
  bikeshed-homelab,
  bikeshed-pure,
  homeModules,
  packages,
  ...
}:
let
  primaryUser = "dszakallas";
in
{
  config,
  pkgs,
  lib,
  system,
  ...
}:
{
  imports = [
    bikeshed.homeModules.base
    bikeshed.homeModules.ssh
    bikeshed.homeModules.agents
    bikeshed.homeModules.github
    bikeshed-pure.homeModules.default
    bikeshed-homelab.homeModules.default
    homeModules.id
  ];

  home = {
    username = primaryUser;
    homeDirectory = "/u/${primaryUser}";
    stateVersion = "24.05";
  };

  # This is not a NixOS system, so home-manager needs to wire up nix's own
  # profile scripts itself (PATH, etc.) instead of relying on the system.
  targets.genericLinux.enable = true;

  # targets.genericLinux only sources the nixpkgs-provided nix.sh, which adds
  # ~/.nix-profile/bin but not the multi-user install's own profile
  # (/nix/var/nix/profiles/default/bin, where `nix` itself lives). This
  # system's Nix installer never wired that into zsh's startup files.
  programs.zsh.envExtra = ''
    [[ -s "/etc/profile.d/nix.sh" ]] && source "/etc/profile.d/nix.sh"
  '';

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
          # Installed manually
          package = null;
        };
      };

    git = {
      enable = true;
      userPresets = {
        github-pure = {
          enable = true;
          credential = {
            enable = true;
            helper = ''!f() { cat >/dev/null; if [ "$1" = get ]; then printf 'username=%s\npassword=%s\n' "$PURE_PROD_KRYPTON_GITHUB_PRIVATE_USERNAME" "$PURE_PROD_KRYPTON_GITHUB_PRIVATE_PASSWORD"; fi; }; f'';
          };
        };
        dszakallas = {
          enable = true;
          sshIdentity = [ "sk1" ];
          credential = {
            enable = true;
            helper = ''!f() { cat >/dev/null; if [ "$1" = get ]; then printf 'username=%s\npassword=%s\n' "$GITHUB_PRIVATE_USERNAME" "$GITHUB_PRIVATE_PASSWORD"; fi; }; f'';
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
}
