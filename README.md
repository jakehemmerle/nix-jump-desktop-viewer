# nix-jump-desktop

Unofficial [Nix](https://nixos.org) flake for **Jump Desktop** (the macOS remote-desktop *viewer/client*), repackaged from its official upstream release and kept current automatically.

> **Platform:** `aarch64-darwin`, `x86_64-darwin` (universal macOS `.app`).
> **Unofficial & proprietary:** not affiliated with PhaseFive Systems. This flake fetches the official signed, notarized artifact, verifies its checksum and Developer ID, and installs it unmodified. Jump Desktop is commercial software under its own license.

This packages the **viewer** — the app you use to connect *out* to remote machines. To let a Mac *be* controlled, see the companion repo **nix-jump-desktop-connect**.

## Quick start

```sh
nix run github:jakehemmerle/nix-jump-desktop            # open the app
nix profile install github:jakehemmerle/nix-jump-desktop
```

`nix profile install` puts the `.app` in an un-indexed location; for a Spotlight-launchable GUI use `nix run` or the Home Manager / nix-darwin integration below.

## Use it in your config

The `inputs.nix-jump-desktop` line belongs in your **flake's** `inputs`; the rest goes in a module that receives your flake `inputs`.

```nix
# flake.nix
inputs.nix-jump-desktop.url = "github:jakehemmerle/nix-jump-desktop";

# Home Manager module (Jake's setup):
{ inputs, pkgs, ... }:
{
  home.packages = [ inputs.nix-jump-desktop.packages.${pkgs.system}.jump-desktop ];
}
```

Home Manager links the `.app` into `~/Applications/Home Manager Apps` (Spotlight-discoverable). nix-darwin: use `environment.systemPackages` instead.

Overlay for `pkgs.jump-desktop` everywhere: `nixpkgs.overlays = [ inputs.nix-jump-desktop.overlays.default ];`

## Gatekeeper

The `.app` stays byte-for-byte identical to upstream (`dontFixup = true`), so its Apple notarization survives the Nix store and Gatekeeper launches it without warnings. Verified in CI by `scripts/verify-signature.sh` (asserts Team ID `2HCKV38EEC` + notarization).

## Auto-update

A scheduled Action mirrors the upstream [Homebrew cask](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/j/jump-desktop.rb) into `pkgs/jump-desktop/source.json`, builds it, verifies the code signature, then commits the bump to `main` — so the Nix code never needs hand-editing. Update by hand:

```sh
./scripts/update-from-cask.sh && nix build .#jump-desktop
```

> GitHub disables scheduled workflows after 60 days with no repo activity; re-enable from the Actions tab if that happens.

## License

Packaging code here is MIT ([`LICENSE`](LICENSE)). Jump Desktop itself is proprietary; see https://jumpdesktop.com/.
