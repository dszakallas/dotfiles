{
  self,
  darwinModules,
  davids-dotfiles-common,
  users,
  ...
}:
{
  lib,
  ...
}:
let
  primaryUser = "dszakallas";
in
{
  imports = [
    davids-dotfiles-common.systemModules.default
    darwinModules.base
    darwinModules.podman
    users.${primaryUser}
  ];

  config = {
    system = { inherit primaryUser; };

    services.openssh.extraConfig = ''
      PasswordAuthentication no
      ChallengeResponseAuthentication no
    '';

    nix = {
      settings.trusted-users = [
        primaryUser
      ];
    };

    homebrew.casks = [
      "logseq"
      "ukelele"
    ];

    ids.gids.nixbld = 350;

    # TODO: Replace with fine-grained and mergable alternative
    nixpkgs.config.allowUnfree = true;
  };
}
