# Adds withPlugins support to the fluxcd package, similar to azure-cli.withExtensions.
#
# Flux CLI plugins are standalone binaries (flux-<name>) discovered via the
# FLUXCD_PLUGINS environment variable. This overlay defines each catalog plugin
# as a nixpkgs derivation and provides a `withPlugins` function that produces a
# wrapped `flux` binary with the plugin directory baked in.
#
# Usage:
#   fluxcd.withPlugins (p: [ p.schema p.mirror p.operator ])
_: fix: prev:
let
  inherit (fix) lib stdenvNoCC;

  # Catalog of all available Flux CLI plugins built from source.
  plugins = {
    schema = fix.buildGo127Module rec {
      pname = "flux-schema";
      version = "0.17.0";

      src = fix.fetchFromGitHub {
        owner = "fluxcd";
        repo = "flux-schema";
        tag = "v${version}";
        hash = "sha256-nNkP0mB0n1RWPr8LbLSy6cUCeNlslV1qZx2BSb0mo78=";
      };

      vendorHash = "sha256-f0h6NNgqqcOyWXyx8t3URN0OKI0OGKMeGOhGCLwCr5s=";

      subPackages = [ "cmd/flux-schema" ];

      ldflags = [
        "-s"
        "-w"
        "-X main.VERSION=${version}"
      ];

      meta = {
        description = "Kubernetes schema extraction and manifests validation";
        homepage = "https://fluxcd.io";
        license = lib.licenses.asl20;
        mainProgram = "flux-schema";
      };
    };

    mirror = fix.buildGo127Module rec {
      pname = "flux-mirror";
      version = "0.10.0";

      src = fix.fetchFromGitHub {
        owner = "fluxcd";
        repo = "flux-mirror";
        tag = "v${version}";
        hash = "sha256-He5rWyhkIcsN4CxBJM2IXfF6Ok2E6FzvidBVry/pXpU=";
      };

      vendorHash = "sha256-qXnfiZFqBnBHXLX9ZEXegO6FHNJZ0+201uorQUepyuE=";

      subPackages = [ "cmd/flux-mirror" ];

      ldflags = [
        "-s"
        "-w"
        "-X main.VERSION=${version}"
      ];

      meta = {
        description = "Helm charts, OCI artifacts and container images mirroring";
        homepage = "https://fluxcd.io";
        license = lib.licenses.asl20;
        mainProgram = "flux-mirror";
      };
    };

    operator = lib.makeOverridable (
      { withMcp ? true }:
      fix.buildGo127Module rec {
        pname = "flux-operator";
        version = "0.62.0";

        src = fix.fetchFromGitHub {
          owner = "controlplaneio-fluxcd";
          repo = "flux-operator";
          tag = "v${version}";
          hash = "sha256-OxUSAC7Kl4uUDoRRTiYJipGLZJg6HeY2NfpYvMhVdV8=";
        };

        vendorHash = "sha256-NFFJeM7cPEMEDVfEYi7UMe3S2sJgoMc5o6HGHOO086Q=";

        subPackages = [ "cmd/cli" ] ++ lib.optional withMcp "cmd/mcp";

        nativeBuildInputs = [ fix.installShellFiles ];

        doCheck = false;

        ldflags = [
          "-s"
          "-w"
          "-X main.VERSION=${version}"
        ];

        postInstall = lib.optionalString (fix.stdenv.buildPlatform.canExecute fix.stdenv.hostPlatform) ''
          mv $out/bin/cli $out/bin/flux-operator
          if [ -f $out/bin/mcp ]; then
            mv $out/bin/mcp $out/bin/flux-operator-mcp
          fi
          for shell in bash fish zsh; do
            installShellCompletion --cmd flux-operator \
              --$shell <($out/bin/flux-operator completion $shell)
          done
        '';

        meta = {
          description = "Flux Operator CLI";
          homepage = "https://fluxoperator.dev/";
          license = lib.licenses.agpl3Only;
          mainProgram = "flux-operator";
        };
      }
    ) { };
  };

  # Wrap the fluxcd derivation with a withPlugins function.
  withPlugins =
    selector:
    let
      selectedPlugins = selector plugins;
      pluginDir = stdenvNoCC.mkDerivation {
        name = "fluxcd-plugins";
        dontUnpack = true;
        installPhase = ''
          mkdir -p $out
          ${lib.concatMapStringsSep "\n" (p: ''
            ln -s ${p}/bin/${p.meta.mainProgram or "*"} $out/
          '') selectedPlugins}
        '';
      };
    in
    fix.symlinkJoin {
      name = "fluxcd-with-plugins-${fix.fluxcd.version}";
      paths = [ fix.fluxcd ];
      nativeBuildInputs = [ fix.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/flux \
          --set FLUXCD_PLUGINS "${pluginDir}"
      '';
      passthru = fix.fluxcd.passthru // {
        inherit withPlugins plugins;
      };
      meta = fix.fluxcd.meta;
    };
in
{
  fluxcd-operator = plugins.operator;
  fluxcd = prev.fluxcd.overrideAttrs (old: {
    passthru = (old.passthru or { }) // {
      inherit withPlugins plugins;
    };
  });
}
