{ self, bikeshed, ... }:
{ lib, config, ... }:
let
  identities =
    if lib.isList config.dotfiles.id.identity then
      config.dotfiles.id.identity
    else
      [ config.dotfiles.id.identity ];

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
    dotfiles.id = {
      enable = lib.mkEnableOption "SSH identity management";
      identity = lib.mkOption {
        type = lib.types.oneOf [
          lib.types.str
          (lib.types.listOf lib.types.str)
        ];
        description = "The SSH identity or identities to use";
      };
    };
  };

  config = lib.mkIf config.dotfiles.id.enable {
    home = {
      # Let's put the keys into to the SSH folder so we have a stable
      # identity for the macOS Keychain
      file = builtins.listToAttrs identityFiles;
    };
  };
}
