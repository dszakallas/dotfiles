# Shared configuration across my darwins.
{ self, pkgs, system, nixConfig, ... }: {
  environment.systemPackages = with pkgs; [ curl vim git ];

  environment.shells = with pkgs; [ bash zsh ];

  services.nix-daemon.enable = true;

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
