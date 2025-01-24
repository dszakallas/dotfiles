{ lib, ... }:
with lib;
{
  # List immediate subdirectories of a directory
  subDirs =
    d:
    foldlAttrs (
      a: k: v:
      a // (if v == "directory" then { ${k} = d + "/${k}"; } else { })
    ) { } (builtins.readDir d);

  # Annotate a region of text for simpler identification of origin
  textRegion =
    {
      name,
      content,
      comment-char ? "#",
    }:
    ''
      ${comment-char} +begin ${name}
      ${content}
      ${comment-char} +end ${name}
    '';
}
