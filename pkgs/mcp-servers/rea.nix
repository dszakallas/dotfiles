{
  rea,
  ghidra-bin,
}:
{
  type = "stdio";
  command = "${rea}/bin/rea";
  args = [ "--mcp" ];
  env = {
    GHIDRA_INSTALL_DIR = "${ghidra-bin}/lib/ghidra";
  };
}
