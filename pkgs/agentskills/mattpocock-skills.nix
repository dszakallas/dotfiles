{
  fetchFromGitHub,
  mkSkill,
  exclude ? null,
  include ? null,
}:
mkSkill {
  name = "mattpocock-skills";
  version = "2026-07-25";
  src = fetchFromGitHub {
    owner = "mattpocock";
    repo = "skills";
    rev = "ed37663cc5fbef691ddfecd080dff42f7e7e350d";
    hash = "sha256-o/H9s3t6ahBqFwpkOMBOTwpsvb33pgvpI9n0PA+uLYM=";
  };
  include = [
    "code-review"
    "codebase-design"
    "resolving-merge-conflicts"
    "domain-modeling"
    "tdd"
    "prototype"
    "diagnosing-bugs"
  ];
  inherit exclude;
}
