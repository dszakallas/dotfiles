{
  pkgs,
  lib,
  config,
  inputs,
  davids-dotfiles-common,
  ...
}:
let
  lib' = davids-dotfiles-common.lib;
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
  imports = [
    inputs.davids-dotfiles-common.devenvModules.agents
  ];

  agents = {
    mcp = {
      enable = true;
      servers = mcpServers;
    };
    gemini = {
      enable = true;
      settings = {
        enable = true;
        value = (lib'.agents.mcpServersForAgent "gemini" mcpServers) // {
          context = {
            fileName = [ "AGENTS.md" ];
          };
        };
      };
    };
  }
  // lib.genAttrs [ "vscode" "claude" "copilot" ] (name: {
    enable = true;
    mcp = {
      enable = true;
      servers = lib'.agents.mcpServersForAgent name mcpServers;
    };
  });
}
