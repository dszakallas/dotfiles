{ ... }:
{
  languages.python.enable = true;
  languages.python.uv.enable = true;

  git-hooks.hooks.nixfmt-rfc-style = {
    excludes = [ "pkgs/npm/_.*\\.nix" ];
  };

  git-hooks.hooks.markdownlint = {
    settings.configuration = {
      # instructions in certain folders will be merged into a single file
      MD041 = false;
    };
  };
}
