{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

# Jump Desktop viewer — repackaged from the signed, notarized macOS .app that
# upstream ships inside a .zip. `source.json` is regenerated from the Homebrew
# cask by scripts/update-from-cask.sh, so this file never needs hand-editing on
# a version bump.
let
  source = lib.importJSON ./source.json;
in
stdenvNoCC.mkDerivation {
  pname = "jump-desktop";
  version = source.version;

  src = fetchurl {
    inherit (source) url;
    hash = source.sha256;
  };

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";
  unpackPhase = ''
    runHook preUnpack
    unzip -q "$src"
    runHook postUnpack
  '';

  # The .app is Developer ID-signed and notarized. Nix's fixup phase would
  # strip / re-sign the Mach-O binaries and break that signature, so Gatekeeper
  # would refuse to launch it. Leave the bytes untouched.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/Applications"
    cp -R "Jump Desktop.app" "$out/Applications/Jump Desktop.app"
    runHook postInstall
  '';

  meta = {
    description = "Fast, fluid remote desktop client (RDP/VNC/Fluid) for macOS";
    homepage = "https://jumpdesktop.com/";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "aarch64-darwin" "x86_64-darwin" ];
    maintainers = [ ];
  };
}
