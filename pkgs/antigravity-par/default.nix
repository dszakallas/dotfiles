{
  lib,
  stdenv,
  fetchurl,
  unzip,
  makeWrapper,
  autoPatchelfHook,
}:

let
  registry = builtins.fromJSON (
    builtins.readFile (
      builtins.fetchurl {
        url = "https://cdn.agentclientprotocol.com/registry/v1/latest/registry.json";
        sha256 = "sha256-cV9dGo5O4BXMKyZ2yWjslPlrbVKXGQHGAyMy78d5A1c=";
      }
    )
  );

  agentData = lib.findFirst (
    a: a.id == "antigravity-acp"
  ) (throw "antigravity-acp not found in ACP registry") registry.agents;

  platformMap = {
    "aarch64-darwin" = "darwin-aarch64";
    "x86_64-darwin" = "darwin-x86_64";
    "aarch64-linux" = "linux-aarch64";
    "x86_64-linux" = "linux-x86_64";
  };

  platformKey =
    platformMap.${stdenv.hostPlatform.system}
      or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

  dist =
    agentData.distribution.binary.${platformKey}
      or (throw "No binary distribution for ${platformKey} in antigravity-acp");

  hashes = {
    "darwin-aarch64" = "sha256-D6uZOIEuazKztUPmXk86ACXO73VUE9sTVC2am4HqgDw=";
    "darwin-x86_64" = "sha256-0Jv5m96nuCAh4a/P+CnaNeSqWD2PCYTvNk3Dp8Bk4H4=";
    "linux-aarch64" = "sha256-fn70CIvBheGvQgQCng9OxCEK8gck8/8mIYasC86mqg4=";
    "linux-x86_64" = "sha256-n78L1YSiZHgWH2N8q9dRE/clQchC0Uj1eO8aap7cuEM=";
  };

  defaultArgs = dist.args or [ ];
in
stdenv.mkDerivation {
  pname = "antigravity-par";
  inherit (agentData) version;

  src = fetchurl {
    url = dist.archive;
    hash = hashes.${platformKey};
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
      ${lib.concatMapStringsSep " " (arg: "--add-flags " + lib.escapeShellArg arg) defaultArgs}

    ln -s antigravity-par $out/bin/agy_acp_server.par
    ln -s antigravity-par $out/bin/agy-acp-server
    ln -s ../libexec/antigravity-par/localharness_external $out/bin/localharness_external

    runHook postInstall
  '';

  meta = {
    inherit (agentData) description;
    homepage = agentData.website;
    license = lib.licenses.unfree;
    mainProgram = "antigravity-par";
    platforms = builtins.attrNames platformMap;
  };
}
