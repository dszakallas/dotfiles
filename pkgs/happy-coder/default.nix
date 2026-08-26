{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs,
  makeWrapper,
}:

buildNpmPackage rec {
  pname = "happy-coder";
  version = "1.2.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/happy/-/happy-${version}.tgz";
    hash = "sha256-/Fm/nKYAOoFuybwokqEozyUucs5gFQTj1U9Lif7zM80=";
  };

  postPatch = ''
    cp ${./package-lock.json} ./package-lock.json
  '';

  npmDepsHash = "sha256-9WP+ahGxHpaYnDwKITSXhDAW9xtT2AdqIa/pvUgJqQ0=";

  dontNpmBuild = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  postInstall = ''
    wrapProgram $out/bin/happy \
      --prefix PATH : ${lib.makeBinPath [ nodejs ]}
    wrapProgram $out/bin/happy-mcp \
      --prefix PATH : ${lib.makeBinPath [ nodejs ]}
  '';

  meta = {
    description = "Mobile and web client wrapper for Claude Code and Codex with end-to-end encryption";
    homepage = "https://happy.engineering";
    license = lib.licenses.mit;
    mainProgram = "happy";
  };
}
