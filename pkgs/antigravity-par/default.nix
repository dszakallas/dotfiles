{
  lib,
  stdenv,
  fetchurl,
  unzip,
  makeWrapper,
  autoPatchelfHook,
}:

let
  version = "1.2.1";

  platforms = {
    "aarch64-darwin" = {
      url = "https://dl.google.com/agy-extensions/releases/macos/agy-acp-server-${version}-darwin-arm64.zip";
      hash = "sha256-D6uZOIEuazKztUPmXk86ACXO73VUE9sTVC2am4HqgDw=";
      args = [ ];
    };
    "x86_64-darwin" = {
      url = "https://dl.google.com/agy-extensions/releases/macos/agy-acp-server-${version}-darwin-x86_64.zip";
      hash = "sha256-0Jv5m96nuCAh4a/P+CnaNeSqWD2PCYTvNk3Dp8Bk4H4=";
      args = [ ];
    };
    "aarch64-linux" = {
      url = "https://dl.google.com/agy-extensions/releases/linux/agy-acp-server-${version}-linux-arm64.zip";
      hash = "sha256-fn70CIvBheGvQgQCng9OxCEK8gck8/8mIYasC86mqg4=";
      args = [ "--uid=" ];
    };
    "x86_64-linux" = {
      url = "https://dl.google.com/agy-extensions/releases/linux/agy-acp-server-${version}-linux-x86_64.zip";
      hash = "sha256-n78L1YSiZHgWH2N8q9dRE/clQchC0Uj1eO8aap7cuEM=";
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
