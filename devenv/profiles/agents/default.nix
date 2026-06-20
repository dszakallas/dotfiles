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
  }
  // lib.genAttrs [ "vscode" "claude" "copilot" "gemini" ] (name: {
    enable = true;
    mcp = {
      enable = true;
      servers = lib'.agents.mcpServersForAgent name mcpServers;
    };
  });
}
