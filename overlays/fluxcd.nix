# Adds withPlugins support to the fluxcd package, similar to azure-cli.withExtensions.
#
# Flux CLI plugins are standalone binaries (flux-<name>) discovered via the
# FLUXCD_PLUGINS environment variable. This overlay defines each catalog plugin
# as a nixpkgs derivation and provides a `withPlugins` function that produces a
# wrapped `flux` binary with the plugin directory baked in.
#
# Usage:
#   fluxcd.withPlugins (p: [ p.schema p.mirror ])
_: fix: prev:
let
  inherit (fix) lib stdenvNoCC;

  # Map nix system strings to the (os, arch) pairs used by the Flux plugin
  # catalog manifests.
  platformFor =
    system:
    let
      parts = builtins.match "([^-]+)-([^-]+)" system;
      arch = builtins.elemAt parts 0;
      kernel = builtins.elemAt parts 1;
    in
    {
      os =
        {
          darwin = "darwin";
          linux = "linux";
        }
        .${kernel} or (throw "Unsupported kernel: ${kernel}");
      arch =
        {
          x86_64 = "amd64";
          aarch64 = "arm64";
        }
        .${arch} or (throw "Unsupported arch: ${arch}");
    };

  # Build a single plugin binary from a release tarball.
  mkFluxPlugin =
    {
      pname,
      version,
      bin,
      description,
      homepage,
      src,
      extraMeta ? { },
    }:
    stdenvNoCC.mkDerivation {
      inherit pname version src;
      dontConfigure = true;
      dontBuild = true;
      sourceRoot = ".";
      installPhase = ''
        install -Dm755 ${bin} $out/bin/${bin}
      '';
      meta = {
        inherit description homepage;
        inherit (fix.fluxcd.meta) platforms;
        mainProgram = bin;
      }
      // extraMeta;
    };

  # Catalog of all available Flux CLI plugins. Each attribute produces
  # a derivation that extracts the plugin binary for the current platform.
  plugins =
    let
      plat = platformFor stdenvNoCC.hostPlatform.system;
    in
    {
      schema = mkFluxPlugin {
        pname = "flux-schema";
        version = "0.11.0";
        bin = "flux-schema";
        description = "Kubernetes schema extraction and manifests validation";
        homepage = "https://fluxcd.io";
        src = fix.fetchurl (
          {
            "darwin-amd64" = {
              url = "https://github.com/fluxcd/flux-schema/releases/download/v0.11.0/flux-schema_0.11.0_darwin_amd64.tar.gz";
              hash = "sha256-DsVTl+SaKsdqNK4E+Zzf0m7IFP0UdfotghYRvhYpRUg=";
            };
            "darwin-arm64" = {
              url = "https://github.com/fluxcd/flux-schema/releases/download/v0.11.0/flux-schema_0.11.0_darwin_arm64.tar.gz";
              hash = "sha256-fvAX+m0SPn+pgFZo/Oote6yiph4abwi7IaSK5X8FW5Y=";
            };
            "linux-amd64" = {
              url = "https://github.com/fluxcd/flux-schema/releases/download/v0.11.0/flux-schema_0.11.0_linux_amd64.tar.gz";
              hash = "sha256-8gipnoKcW7HfGuKQQ4Fhp7w84dLKrZSaipwJv7Kklqw=";
            };
            "linux-arm64" = {
              url = "https://github.com/fluxcd/flux-schema/releases/download/v0.11.0/flux-schema_0.11.0_linux_arm64.tar.gz";
              hash = "sha256-YCMl0nsDar10wWbIV3BaV4M4vy0eragZKKwxkuOhQK4=";
            };
          }
          ."${plat.os}-${plat.arch}"
        );
        extraMeta.license = lib.licenses.asl20;
      };

      mirror = mkFluxPlugin {
        pname = "flux-mirror";
        version = "0.8.0";
        bin = "flux-mirror";
        description = "Helm charts, OCI artifacts and container images mirroring";
        homepage = "https://fluxcd.io";
        src = fix.fetchurl (
          {
            "darwin-amd64" = {
              url = "https://github.com/fluxcd/flux-mirror/releases/download/v0.8.0/flux-mirror_0.8.0_darwin_amd64.tar.gz";
              hash = "sha256-UvAoqg1gozUhn+mwbxgojSoIIWPOBmGvTWbXEzx+2/A=";
            };
            "darwin-arm64" = {
              url = "https://github.com/fluxcd/flux-mirror/releases/download/v0.8.0/flux-mirror_0.8.0_darwin_arm64.tar.gz";
              hash = "sha256-TkqXT2rKoV6Ag4HX+hnKA84rBVZnXambUfUVmdODmDY=";
            };
            "linux-amd64" = {
              url = "https://github.com/fluxcd/flux-mirror/releases/download/v0.8.0/flux-mirror_0.8.0_linux_amd64.tar.gz";
              hash = "sha256-SGLpxKLJrGv+SXZ2bsQlsBXy5nMK3rz5UYTR2UvrWzU=";
            };
            "linux-arm64" = {
              url = "https://github.com/fluxcd/flux-mirror/releases/download/v0.8.0/flux-mirror_0.8.0_linux_arm64.tar.gz";
              hash = "sha256-cSIqe8/gcV2pSBhFs0tg32gDTBvjhtWcPDzvjHb8pvM=";
            };
          }
          ."${plat.os}-${plat.arch}"
        );
        extraMeta.license = lib.licenses.asl20;
      };

      operator = mkFluxPlugin {
        pname = "flux-operator";
        version = "0.56.0";
        bin = "flux-operator";
        description = "Flux Operator CLI";
        homepage = "https://fluxoperator.dev/";
        src = fix.fetchurl (
          {
            "darwin-amd64" = {
              url = "https://github.com/controlplaneio-fluxcd/flux-operator/releases/download/v0.56.0/flux-operator_0.56.0_darwin_amd64.tar.gz";
              hash = "sha256-byRRbdu5KNbLUifGv9s4HBIN6plFfq5vzWnaf85aEDY=";
            };
            "darwin-arm64" = {
              url = "https://github.com/controlplaneio-fluxcd/flux-operator/releases/download/v0.56.0/flux-operator_0.56.0_darwin_arm64.tar.gz";
              hash = "sha256-JpwMz6vJhmC5nw38qAzh7vs87SvEQgenxIWPuh0/KfM=";
            };
            "linux-amd64" = {
              url = "https://github.com/controlplaneio-fluxcd/flux-operator/releases/download/v0.56.0/flux-operator_0.56.0_linux_amd64.tar.gz";
              hash = "sha256-AvZ9FbJGsK8BFQzXKsLctJ5yWo8bT6lpq+8UcDOANAQ=";
            };
            "linux-arm64" = {
              url = "https://github.com/controlplaneio-fluxcd/flux-operator/releases/download/v0.56.0/flux-operator_0.56.0_linux_arm64.tar.gz";
              hash = "sha256-4FGQuX9c+LjoDA7OLNxbfUn0zwkgaACtrfW58vY1xIY=";
            };
          }
          ."${plat.os}-${plat.arch}"
        );
        extraMeta.license = lib.licenses.agpl3Only;
      };
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
            ln -s ${p}/bin/flux-* $out/
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
  fluxcd = prev.fluxcd.overrideAttrs (old: {
    passthru = (old.passthru or { }) // {
      inherit withPlugins plugins;
    };
  });
}
