{
  stdenvNoCC,
  fetchFromGitHub,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "spacemacs";
  version = "2024-01-20-develop";
  src = fetchFromGitHub {
    owner = "syl20bnr";
    repo = "spacemacs";
    rev = "11aaddf3ad7e5e3dd3b494d56221efe7b882fd72";
    hash = "sha256-uozaV6igLIufvFzPrbt9En1VStDZDkSRRyxH62elK+8=";
  };

  patches = [
    ./elpa-in-userdir.diff
  ];

  installPhase = ''
    mkdir -p $out/share/spacemacs
    cp -r * .lock $out/share/spacemacs
  '';
}
