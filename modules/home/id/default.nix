{ self, davids-dotfiles-common, ... }:
{ lib, config, ... }:
let
  identities =
    if lib.isList config.davids.id.identity then
      config.davids.id.identity
    else
      [ config.davids.id.identity ];

  identityFiles = builtins.concatMap (identity: [
    {
      name = ".ssh/${identity}";
      value.source = ./. + "/${identity}";
    }
    {
      name = ".ssh/${identity}.pub";
      value.source = ./. + "/${identity}.pub";
    }
  ]) identities;
in
{

  options = {
    davids.id = {
      enable = lib.mkEnableOption "SSH identity management";
      identity = lib.mkOption {
        type = lib.types.oneOf [
          lib.types.str
          (lib.types.listOf lib.types.str)
        ];
        default = "sk1";
        description = "The SSH identity or identities to use";
      };
    };
  };

  config = lib.mkIf config.davids.id.enable {
    home = {
      # Let's put the keys into to the SSH folder so we have a stable
      # identity for the macOS Keychain
      file = builtins.listToAttrs identityFiles;
    };

    davids = {
      git = {
        configLines = lib.mkBefore (
          davids-dotfiles-common.lib.textRegion {
            name = "dotfiles/modules/home/id";
            content = ''
              [user]
                name = Dávid Szakállas
                email = 5807322+dszakallas@users.noreply.github.com
              [github]
                user = dszakallas
            '';
          }
        );
      };
      github = {
        ssh = {
          matchBlocks = {
            "git" = {
              identityFile =
                if lib.isList config.davids.id.identity then
                  builtins.map (identity: "~/.ssh/${identity}") config.davids.id.identity
                else
                  "~/.ssh/${config.davids.id.identity}";
              isFIDO2 = true;
            };
          };
        };
      };
    };
  };

}
