{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs,
  makeWrapper,
}:

buildNpmPackage rec {
  pname = "happy-coder";
  version = "1.2.3";

  src = fetchurl {
    url = "https://registry.npmjs.org/happy/-/happy-${version}.tgz";
    hash = "sha256-cS9s+OPka2eAIK5IRPhDO0MNdnBQis7jCdLxzN74Omk=";
  };

  postPatch = ''
    cp ${./package-lock.json} ./package-lock.json
  '';

  npmDepsHash = "sha256-UB/eKNeFs5k7vgWeTQVLBOXnx5TrRIV3Ae2Gm9+gAqY=";

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
