{
  lib,
  buildNpmPackage,
  fetchzip,
  nix-update-script,
  versionCheckHook,
}:

buildNpmPackage (finalAttrs: {
  pname = "open-pencil-mcp";
  version = "0.16.0";
  __structuredAttrs = true;

  src = fetchzip {
    url = "https://registry.npmjs.org/@open-pencil/mcp/-/mcp-${finalAttrs.version}.tgz";
    hash = "sha256-1ioYwDfjpleSshQj8LbzwEKfN4HkNRBlYU+aacav7VQ=";
  };

  npmDepsHash = "sha256-TQy0RMgOEC1PhH9rlt/+RMNAEIb9McZu8VgUzJK/11I=";

  postPatch = ''
    # npm tarball does not ship a lock file; vendor a generated one.
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;
  npmFlags = [ "--ignore-scripts" ];

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Model Context Protocol server for OpenPencil";
    homepage = "https://github.com/open-pencil/open-pencil";
    downloadPage = "https://www.npmjs.com/package/@open-pencil/mcp";
    license = lib.licenses.mit;
    mainProgram = "openpencil-mcp";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
