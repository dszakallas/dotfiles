{ ... }:
{
  git-hooks.hooks.nixfmt-rfc-style = {
    excludes = [ "pkgs/npm/_.*\\.nix" ];
  };

  git-hooks.hooks.markdownlint = {
    excludes = [ "^users/skills/.*" ];
  };
}
