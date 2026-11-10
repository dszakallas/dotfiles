{
  beads,
  bikeshed,
  bikeshed-homelab,
  homeModules,
  packages,
  ...
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
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
  beadsSkill = pkgs.mkSkill {
    name = "beads";
    version = beads.packages.${system}.bd.version;
    src = beads;
    sourceRoot = "plugins/beads";
  };
in
{
  imports = [
    bikeshed.homeModules.agents
    homeModules.reverse-engineering
  ];

  bikeshed.agents = {
    enable = true;
    skills.enable = true;
    skills.entries =
      bikeshed.packages.${system}.agentskills
      // packages.${system}.agentskills
      // {
        beads = beadsSkill;
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
              # Claude is wrapped to use ~/.claude/.claude.json instead of ~/.claude.json for its configuration.
              # With package = null, the wrapper needs to know the path to the executable.
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
          harness = "claude";
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
}
