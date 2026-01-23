{ self, davids-dotfiles-common, ... }:
{ lib, ... }:
{

  home = {
    # Let's put the keys into to the SSH folder so we have a stable
    # identity for the macOS Keychain
    file.".ssh/sk1".source = ./sk1;
    file.".ssh/sk1.pub".source = ./sk1.pub;
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
            identityFile = "~/.ssh/sk1";
            isFIDO2 = true;
          };
        };
      };
    };
  };
}
