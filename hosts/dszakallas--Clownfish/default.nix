{
  self,
  davids-dotfiles-common,
  darwinModules,
  systemModules,
  overlays,
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
    systemModules.default
    darwinModules.default
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
      "claude"
      "google-gemini"
      "ollama"
      "plexamp"
      "ukelele"
    ];

    ids.gids.nixbld = 350;

    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "vault"
        "terraform"
        "claude-code"
        "github-copilot-cli"
      ];
  };
}
