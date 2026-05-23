{ ... }:
{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    mkMerge
    ;

  mkAgentModule =
    {
      name,
      defaultPackage,
      defaultUserDirectory,
      defaultMainMemoryFile,
    }:
    {
      options = {
        enable = mkEnableOption "${name} agent";
        package = mkOption {
          type = types.package;
          default = defaultPackage;
          description = "The package for the ${name} agent.";
        };
        userDirectory = mkOption {
          type = types.str;
          default = defaultUserDirectory;
          description = "The user directory for ${name} local files.";
        };
        memory = {
          enable = mkEnableOption "memory management for ${name}";
          main = {
            enable = mkEnableOption "main memory file for ${name}";
            content = mkOption {
              type = types.nullOr types.lines;
              default = null;
              description = "Content of the main memory file.";
            };
            target = mkOption {
              type = types.str;
              default = defaultMainMemoryFile;
              description = "Path to the target file for the main memory file.";
            };
            source = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "Path to the source file for the main memory file.";
            };
          };
        };
      };

      config =
        let
          cfg = config.davids.agents.${name};
          memoryBaseDir = "${config.home.homeDirectory}/${cfg.userDirectory}";
          memoryFile = "${memoryBaseDir}/${cfg.memory.main.target}";
          unmanagedFile = "${memoryBaseDir}/unmanaged.MEMORY.MD";
        in
        mkIf cfg.enable (mkMerge [
          {
            home.packages = [ cfg.package ];
          }
          (mkIf (cfg.memory.enable && cfg.memory.main.enable) {
            home.file."${memoryFile}" =
              if cfg.memory.main.content != null then
                { text = cfg.memory.main.content; }
              else if cfg.memory.main.source != null then
                { source = cfg.memory.main.source; }
              else
                { };

            home.activation."initUnmanagedMemory${name}" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${memoryBaseDir}"
              if [[ ! -f "${unmanagedFile}" ]]; then
                $DRY_RUN_CMD cat <<EOF > "${unmanagedFile}"
              # Unmanaged Memory for ${name}

              <!--
              This file is for your private, local-only agent memory.
              Unlike '${cfg.memory.main.target}', this file is NOT managed by Nix.
              It will never be overwritten, and it is safe to edit manually.

              Use this for:
              - Personal secrets or local-only context.
              - Temporary notes you don't want to commit to your dotfiles.
              - Machine-specific configuration hints.
              -->
              EOF
                $DRY_RUN_CMD chmod $VERBOSE_ARG 644 "${unmanagedFile}"
              fi
            '';
          })
        ]);
    };

  geminiModule = mkAgentModule {
    name = "gemini";
    defaultPackage = pkgs.gemini-cli;
    defaultUserDirectory = ".gemini";
    defaultMainMemoryFile = "GEMINI.md";
  };

  claudeModule = mkAgentModule {
    name = "claude";
    defaultPackage = pkgs.claude-code;
    defaultUserDirectory = ".claude";
    defaultMainMemoryFile = "CLAUDE.md";
  };

  copilotModule = mkAgentModule {
    name = "copilot";
    defaultPackage = pkgs.github-copilot-cli;
    defaultUserDirectory = ".copilot";
    defaultMainMemoryFile = "copilot-instructions.md";
  };
in
{
  options.davids.agents = {
    enable = mkEnableOption "AI agent tools";
    gemini = geminiModule.options;
    claude = claudeModule.options;
    copilot = copilotModule.options;
  };

  config = mkIf config.davids.agents.enable (mkMerge [
    geminiModule.config
    claudeModule.config
    copilotModule.config
  ]);
}
