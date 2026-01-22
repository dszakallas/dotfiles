fix: prev: {
  fluxcd-operator = prev.fluxcd-operator.overrideAttrs (_: rec {
    subPackages = [
      "cmd/cli"
      "cmd/mcp"
    ];

    postInstall = fix.lib.optionalString (fix.stdenv.buildPlatform.canExecute fix.stdenv.hostPlatform) ''
      mv $out/bin/cli $out/bin/flux-operator
      mv $out/bin/mcp $out/bin/flux-operator-mcp
      for shell in bash fish zsh; do
        installShellCompletion --cmd flux-operator \
          --$shell <($out/bin/flux-operator completion $shell)
      done
    '';
  });
}
