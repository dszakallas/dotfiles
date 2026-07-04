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
        shared = pkgs.stdenvNoCC.mkDerivation {
          name = "shared-skills";
          src = ../../../users/shared;
          dontBuild = true;
          installPhase = ''
            mkdir -p $out
            cp -r $src/* $out/
          '';
        };
        cc-skills-golang = lib'.agents.mkSkill pkgs {
          name = "cc-skills-golang";
          version = "2026-07-02";
          src = pkgs.fetchFromGitHub {
            owner = "samber";
            repo = "cc-skills-golang";
            rev = "8b2d019212d6a5390d472a7660a8489109d7db49";
            hash = "sha256-oSFApXKBndeM1wsl6GyPwiDuIgt5bGXWzDtpnmC6SaM=";
          };
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
