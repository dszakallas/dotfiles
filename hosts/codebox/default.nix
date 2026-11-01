{
  bikeshed,
  bikeshed-homelab,
  homeModules,
  packages,
  ...
}:
{
  config,
  pkgs,
  lib,
  system,
  ...
}:
{
  imports = [
    bikeshed.homeModules.base
    bikeshed.homeModules.ssh
    bikeshed.homeModules.agents
    bikeshed.homeModules.github
    (import "${bikeshed-homelab}/modules/home/default/dszakallas.nix")
    (import "${bikeshed-homelab}/modules/home/default/dszakallas-kolobok.nix")
    (import "${bikeshed-homelab}/modules/home/default/github-user1.nix")
    homeModules.id
    homeModules.git-operator
  ];

  _module.args.bikeshed = bikeshed;

  targets.genericLinux.enable = true;

  programs.home-manager.enable = true;

  davids.id = {
    enable = true;
    identity = [ "sk1" ];
  };

  home.packages = with pkgs; [
    bzip2
    curl
    gnugrep
    gnutar
    gzip
    lbzip2
    procps
    xz
    poppler-utils
  ];

  bikeshed = {
    devenv.enable = true;
    direnv.enable = true;

    ssh = {
      enable = true;
    };

    git = {
      enable = true;
      userPresets = {
        github-user1.enable = true;
        dszakallas = {
          enable = true;
          sshIdentity = [ "sk1" ];
          credential = {
            enable = true;
            helper = bikeshed.lib.git.mkEnvCredentialHelper "GITHUB_PRIVATE_";
          };
        };
        dszakallas-kolobok = {
          enable = true;
          sshIdentity = [ "sk1" ];
          credential.enable = true;
        };
      };
    };

    github = {
      enable = true;
      ssh = {
        enable = true;
      };
      extensions = [ pkgs.gh-stack ];
    };

    agents = {
      enable = true;
      skills.enable = true;
      skills.entries = {
        inherit (bikeshed.packages.${system}.agentskills)
          anthropic-skills
          mattpocock-skills
          ;
      };
      harnesses.opencode.enable = true;
    };
  };
}
