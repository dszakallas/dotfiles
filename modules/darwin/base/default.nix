{ self, ... }:
{
  pkgs,
  config,
  system,
  nixConfig,
  hostName,
  lib,
  ...
}:
{
  config = {
    homebrew.enable = true;

    homebrew.casks = [
      "iterm2"
      "firefox"
      "keepassxc"
    ];

    # Create /etc/zshrc that loads the nix-darwin environment.
    programs.zsh = {
      enable = true; # default shell on catalina

      # Add back the original contents
      # shellInit = ''
      #   if [ -x /usr/libexec/path_helper ]; then
      #     eval `/usr/libexec/path_helper -s`
      #   fi
      # '';
    };

    security.sudo.extraConfig = ''
      # Added by dotfiles/darwin/default
      Defaults:root,%admin env_keep+=NIX_CONFIG
    '';

    services.openssh.extraConfig = ''
      # Added by dotfiles/darwin/default
      PasswordAuthentication no
      ChallengeResponseAuthentication no
    '';

    # Set Git commit hash for darwin-version.
    system.configurationRevision = self.rev or self.dirtyRev or null;

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    system.stateVersion = 4;
  };
}
