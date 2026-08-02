{
  pkgs,
  lib,
  config,
  inputs,
  bikeshed,
  ...
}:
let
  lib' = bikeshed.lib;
  mcpServers = {
    devenv = {
      type = "stdio";
      command = "devenv";
      args = [ "mcp" ];
      env = {
        DEVENV_ROOT = config.devenv.root;
      };
    };
  };
in
{
  module = {
    imports = [
      inputs.bikeshed.devenvModules.agents
    ];

    agents = {
      mcp = {
        enable = true;
        servers = mcpServers;
      };
      skills = {
        enable = true;
        entries = {
          shared = inputs.bikeshed.lib.agents.mkSkill pkgs {
            name = "shared-skills";
            version = "unstable";
            src = ../users/shared;
            include = [ "devenv" ];
          };
        };
      };
    }
    // lib.genAttrs [ "vscode" "claude" "copilot" "gemini" "opencode" ] (name: {
      enable = true;
      mcp = {
        enable = true;
        servers = lib'.agents.mcpServersForAgent name mcpServers;
      };
    });
  };
}
