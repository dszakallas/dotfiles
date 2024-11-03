{ self, davids-dotfiles, ... }:
{ pkgs, config, system, nixConfig, ... }: {

  environment.shells = with pkgs; [ bash zsh ];

  environment.systemPackages = with pkgs; [ curl vim git ];
  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = system;

  nix = {
    settings = nixConfig;
    nixPath = if config.nix.channel.enable then
      [ "nixpkgs-overlays=${self}/overlays-compat/" ]
    else
      [ ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm.bak";
  };

  environment.etc."hosts" = {
    # TODO Linking the hosts file to /etc/hosts in darwin doesn't work.
    enable = if pkgs.stdenv.hostPlatform.isDarwin then false else true;
    text = davids-dotfiles.lib.textRegion {
      name = "davids-dotfiles/default";
      content = (builtins.readFile ./hosts);
    };
  };
}
