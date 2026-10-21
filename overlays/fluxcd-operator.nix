_: fix: prev: {
  fluxcd-operator =
    let
      buildGoModule = fix.buildGo127Module;
      version = "0.61.0";
    in
    (prev.fluxcd-operator.override { inherit buildGoModule; }).overrideAttrs (_: rec {
      inherit version;

      src = fix.fetchFromGitHub {
        owner = "controlplaneio-fluxcd";
        repo = "flux-operator";
        tag = "v${version}";
        hash = "sha256-eVdzE6b6HcZx/KGxAzbzS1nlpsPQ0ne+xN66DWRmChY=";
      };

      vendorHash = "sha256-ms+mBhnpp9jZc9orPjhbCtQI3hmo5mug8wJczmIybOY=";

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
