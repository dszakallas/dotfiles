{ lib, ... }:
with lib; {
  # List immediate subdirectories of a directory
  subDirs = d:
    foldlAttrs
    (a: k: v: a // (if v == "directory" then { ${k} = d + "/${k}"; } else { }))
    { } (builtins.readDir d);
}
