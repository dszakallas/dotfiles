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
            src = ../hosts/shared;
            include = [ "devenv" ];
          };
        };
      };
    }
    // lib.genAttrs lib'.agents.popularHarnesses (name: {
      enable = true;
      mcp = {
        enable = true;
        servers = lib'.agents.mcpServersForAgent name mcpServers;
      };
    });
  };
}
