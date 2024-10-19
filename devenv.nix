{ ... }: {
  languages.nix.enable = true;
  pre-commit.hooks.nixfmt-classic.enable = true;
}
