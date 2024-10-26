# Shared configuration across my darwins.
{ self, pkgs, system, nixConfig, davids-dotfiles, ... }: {
  environment.systemPackages = with pkgs; [ curl vim git ];

  environment.shells = with pkgs; [ bash zsh ];

  environment.etc."hosts" = {
    enable =
      false; # TODO Linking the hosts file to /etc/hosts in darwin doesn't work.
    text = davids-dotfiles.lib.textRegion {
      name = "davids-dotfiles/default";
      content = (builtins.readFile ./hosts);
    };
  };

  services.nix-daemon.enable = true;

  homebrew.enable = true;

  homebrew.casks = [ "gpg-suite" "iterm2" ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh = {
    enable = true; # default shell on catalina
    shellInit = ''
      if [ -x /usr/libexec/path_helper ]; then
        eval `/usr/libexec/path_helper -s`
      fi
    '';
  };

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = system;

  nix.settings = nixConfig;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm.bak";
  };
}
