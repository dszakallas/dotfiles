{
  lib,
  python3Packages,
  fetchPypi,
}:

python3Packages.buildPythonApplication rec {
  pname = "notebooklm-py";
  version = "0.8.1";
  pyproject = true;

  src = fetchPypi {
    pname = "notebooklm_py";
    inherit version;
    hash = "sha256-Q7pRqWCalTC/zZrQbBA17erEsOQBVqWn7n7jAmIWZs0=";
  };

  build-system = with python3Packages; [
    hatchling
    hatch-fancy-pypi-readme
  ];

  dependencies = with python3Packages; [
    httpx
    click
    rich
    filelock
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

  # Disable tests since they require network access and API keys
  doCheck = false;

  meta = with lib; {
    description = "Unofficial Python library for automating Google NotebookLM";
    homepage = "https://github.com/teng-lin/notebooklm-py";
    license = licenses.mit;
    mainProgram = "notebooklm";
  };
}
