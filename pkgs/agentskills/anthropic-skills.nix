{
  fetchFromGitHub,
  mkSkill,
}:
mkSkill {
  name = "anthropic-skills";
  version = "2026-07-25";
  src = fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    rev = "b29e7cf65e5cb78a5ac33d582270551bc74a14eb";
    hash = "sha256-RH2B03gj4kzw1j5LORezgUZPPu8mW+mWb+Kl2U7WUbY=";
  };
  include = [
    "pptx"
    "pdf"
    "docx"
    "xlsx"
    "mcp-builder"
    "skill-creator"
  ];
}
