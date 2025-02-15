{ self, davids-dotfiles, ... }:
let
  myUsername = "dszakallas";
in
{
  imports = [
    davids-dotfiles.systemModules.default
    davids-dotfiles.darwinModules.default
    davids-dotfiles.darwinModules.p10y
    davids-dotfiles.users.${myUsername}
  ];

  davids.emacs = {
    enable = true;
    version = "29";
  };

  nix.settings.trusted-users = [
    "root"
    myUsername
  ];

  ids.gids.nixbld = 350;

  # TODO: Replace with fine-grained and mergable alternative
  nixpkgs.config.allowUnfree = true;
}
