{
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
  localAgentMemory = import ../../lib/agents;
  agentMemory = pkgs.writeText "agent-memory" (
    "# User-level memory\n\n"
    # Include every local memory fragment for each configured agent.
    + lib.concatStringsSep "\n" (lib.attrValues localAgentMemory.memory)
    + lib.concatStringsSep "\n" (lib.attrValues bikeshed-homelab.lib.agents.memory)
  );
in
{
  imports = [
    bikeshed.homeModules.agents
    homeModules.rea
  ];

  home.packages = with pkgs; [ claude-agent-acp ];

  bikeshed.agents = {
    enable = true;
    skills.enable = true;
    skills.entries = bikeshed.packages.${system}.agentskills // packages.${system}.agentskills;
    harnesses =
      (lib.foldl'
        (
          a: v:
          a
          // {
            "${v}" = {
              enable = true;
              linkSkills = true;
              memory = {
                enable = true;
                source = agentMemory;
              };
              mcp = {
                servers = {
                  chrome-devtools = bikeshed.lib.agents.mcpServers.chrome-devtools pkgs;
                  rea = localAgentMemory.mcpServers.rea (pkgs // { inherit (packages.${system}) rea; });
                  open-pencil = localAgentMemory.mcpServers.open-pencil (
                    pkgs // { inherit (packages.${system}) open-pencil-mcp; }
                  );
                };
              };
            }
            // lib.optionalAttrs (v == "claude" || v == "antigravity" || v == "codex") {
              # self-updating tools, I prefer to install them with Homebrew
              # on personal workstation (containers are a different story)
              package = null;
            }
            // lib.optionalAttrs (v == "claude") {
              settings = {
                entries.attribution.value = {
                  commit = "";
                  pr = "";
                };
              };
              # Claude is wrapped to use ~/.claude/.claude.json instead of ~/.claude.json for its configuration.
              # With package = null, the wrapper needs to know the path to the executable.
              wrapper.executable = "${config.bikeshed.brew.prefix}/bin/claude";
            };
          }
        )
        { }
        [
          "claude"
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
