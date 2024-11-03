{ self, davids-dotfiles, ... }:
{ pkgs, system, nixConfig, ... }: {
  services.nix-daemon.enable = true;

  homebrew.enable = true;

  homebrew.casks = [ "gpg-suite" "iterm2" ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh = {
    enable = true; # default shell on catalina

    # Add back the original contents
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
}
