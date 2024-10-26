{ ... }: {
  languages.nix.enable = true;
  pre-commit.hooks = {
    nixfmt-classic.enable = true;
    markdownlint = {
      enable = true;
      settings.configuration = { MD013.line_length = 120; };
    };
    shellcheck.enable = true;
  };
}
