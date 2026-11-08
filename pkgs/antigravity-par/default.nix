{
  lib,
  stdenv,
  fetchurl,
  unzip,
  makeWrapper,
  autoPatchelfHook,
}:

let
  version = "1.4.5";

  platforms = {
    "aarch64-darwin" = {
      url = "https://dl.google.com/agy-extensions/releases/macos/agy-acp-server-${version}-darwin-arm64.zip";
      hash = "sha256-iG//d2fQiZTKOesCw9AadTLHMlqUqjOq9S1SBoczKE8=";
      args = [ ];
    };
    "x86_64-darwin" = {
      url = "https://dl.google.com/agy-extensions/releases/macos/agy-acp-server-${version}-darwin-x86_64.zip";
      hash = "sha256-s581c8A7msud8CiFP2R1J/HzEz8yvXfni3luSKIFEUo=";
      args = [ ];
    };
    "aarch64-linux" = {
      url = "https://dl.google.com/agy-extensions/releases/linux/agy-acp-server-${version}-linux-arm64.zip";
      hash = "sha256-fWQkZjOuCU9n47vNLWeeiQSPkTRtUzkxMzbnSD9A8FY=";
      args = [ "--uid=" ];
    };
    "x86_64-linux" = {
      url = "https://dl.google.com/agy-extensions/releases/linux/agy-acp-server-${version}-linux-x86_64.zip";
      hash = "sha256-kjkjoNfcgHP2bMb3hkejEH46fuK34aJN+LOSe1GIATs=";
      args = [ "--uid=" ];
    };
  };

  platform =
    platforms.${stdenv.hostPlatform.system}
      or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "antigravity-par";
  inherit version;

  src = fetchurl {
    inherit (platform) url hash;
  };

  nativeBuildInputs = [
    unzip
    makeWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  sourceRoot = ".";

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec/antigravity-par $out/bin
    cp -p agy_acp_server.par localharness_external $out/libexec/antigravity-par/
    chmod +x $out/libexec/antigravity-par/*

    makeWrapper $out/libexec/antigravity-par/agy_acp_server.par $out/bin/antigravity-par \
      --prefix PATH : "$out/libexec/antigravity-par" \
      ${lib.concatMapStringsSep " " (arg: "--add-flags " + lib.escapeShellArg arg) platform.args}

    ln -s antigravity-par $out/bin/agy_acp_server.par
    ln -s antigravity-par $out/bin/agy-acp-server
    ln -s ../libexec/antigravity-par/localharness_external $out/bin/localharness_external

    runHook postInstall
  '';

  meta = {
    description = "Google's AI coding agent";
    homepage = "https://antigravity.google/docs/ide/extensions";
    license = lib.licenses.unfree;
    mainProgram = "antigravity-par";
    platforms = builtins.attrNames platforms;
  };
}
