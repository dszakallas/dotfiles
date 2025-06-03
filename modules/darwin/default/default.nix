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
  options = with lib; {
    davids.emacs = {
      enable = mkEnableOption "Emacs configuration (system-wide)";
      version = mkOption {
        default = "29";
        type = types.str;
        description = "Emacs major version";
      };
    };
  };
  config = {
    homebrew.enable = true;

    homebrew.casks = [
      "iterm2"
      "firefox"
      "keepassxc"
    ];

    homebrew.brews = lib.optionals config.davids.emacs.enable [
      {
        name = "emacs-plus@${config.davids.emacs.version}";
        args = [ "with-native-comp" ];
      }
    ];

    homebrew.taps = lib.optionals config.davids.emacs.enable [ "d12frosted/emacs-plus" ];

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

    programs.gnupg = {
      agent.enable = true;
    };

    # Set Git commit hash for darwin-version.
    system.configurationRevision = self.rev or self.dirtyRev or null;

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    system.stateVersion = 4;
  };
}
