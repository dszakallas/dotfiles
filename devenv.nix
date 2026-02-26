{ ... }:
{
  git-hooks.hooks.nixfmt-rfc-style = {
    excludes = [ "pkgs/npm/_.*\\.nix" ];
  };
}
