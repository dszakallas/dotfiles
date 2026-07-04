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
    skills = {
      enable = true;
      entries = {
        shared = inputs.davids-dotfiles-common.lib.agents.mkSkill pkgs {
          name = "shared-skills";
          version = "unstable";
          src = ../../../users/shared;
          include = [ "devenv" ];
        };
      };
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
