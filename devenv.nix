{ ... }:
{
  git-hooks.hooks.nixfmt-rfc-style = {
    excludes = [ "node2nix-pkgs/.*\\.nix" ];
  };
}
