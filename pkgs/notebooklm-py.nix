{
  lib,
  python3Packages,
  fetchPypi,
  installAgentSkills,
}:

python3Packages.buildPythonApplication rec {
  pname = "notebooklm-py";
  version = "0.8.6";
  pyproject = true;

  src = fetchPypi {
    pname = "notebooklm_py";
    inherit version;
    hash = "sha256-UaUKi0y5QlFHk+zSdoIonbme/OR1jRyzC+Is9SouSSU=";
  };

  build-system = with python3Packages; [
    hatchling
    hatch-fancy-pypi-readme
  ];

  nativeBuildInputs = [
    installAgentSkills
  ];

  dontInstallAgentSkills = true;

  dependencies = with python3Packages; [
    httpx
    idna
    click
    rich
    filelock
    typing-extensions
  ];

  optional-dependencies = with python3Packages; {
    markdown = [ markdownify ];
    browser = [ playwright ];
    impersonate = [ curl-cffi ];
    headless = [ gpsoauth ];
    mcp = [ fastmcp ];
    server = [
      fastapi
      uvicorn
      python-multipart
    ];
  };

  postInstall = ''
    mkdir -p "$TMPDIR/skills/notebooklm"
    cp SKILL.md "$TMPDIR/skills/notebooklm/SKILL.md"
    installSkill "$TMPDIR/skills/notebooklm" notebooklm-py
  '';

  # Disable tests since they require network access and API keys
  doCheck = false;

  meta = with lib; {
    description = "Unofficial Python library for automating Google NotebookLM";
    homepage = "https://github.com/teng-lin/notebooklm-py";
    license = licenses.mit;
    mainProgram = "notebooklm";
  };
}
