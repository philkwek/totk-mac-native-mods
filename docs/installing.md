# Installing and building

This overlay does not ship a playable app. You build one from your own game
file and keys, exactly as the upstream project does.

## 1. Check the prerequisites

- macOS 26 or later on Apple silicon.
- Xcode command line tools (`xcode-select --install`).
- Homebrew and the upstream dependencies:

```bash
brew install opus libvpx python@3.14
```

- Your own Tears of the Kingdom **1.0.0** XCI or NSP.
- `prod.keys` dumped from your own console.
- Free disk space for the upstream build.

## 2. Fetch and patch upstream

```bash
git clone https://github.com/philkwek/totk-mac-native-mods
cd totk-mac-native-mods
./scripts/bootstrap.sh
./scripts/apply.sh
./scripts/verify.sh
```

`bootstrap.sh` fetches the pinned commit into `.upstream/`. `apply.sh` applies
`patches/series`. `verify.sh` re-fetches, re-applies, runs the source tests and
the repository hygiene check. It needs no game data or keys.

## 3. Build

```bash
./scripts/build.sh \
  --rom "/path/to/TOTK [0100F2C0115B6000][v0].xci" \
  --keys "$HOME/path/to/prod.keys"
```

The default output is `.build/Tears of the Kingdom.app`; use `--out` and
`--work` to change the app and build folder. The app contains your game data
and must not be shared.

`build.sh` targets the common XCI path. For an NSP that needs a separate font
source, run upstream's `build_app.py` directly with the same patched
`.upstream/` checkout, adding its `--shared-fonts` or `--firmware` option.

## 4. Enable the switches

Open the app, press **1** for the settings panel and choose the **Gameplay**
page. The four switches are off by default. They are written into the runtime
before the game starts, so a change is kept for the next launch; the title adds
“(from the next launch)” until then.

You can also write the files directly next to `controls.txt`:

```text
unlimited-durability.txt   on
unlimited-health.txt       on
unlimited-arrows.txt       on
unlimited-battery.txt      on
```

`on`, `1` or `true` enable a switch; `off`, a blank file or a missing file
leaves it off.

## 5. Testing safely

Use a **copy** of your profile for testing. The mods change gameplay and can
alter a save in ways the vanilla game does not. Back up the profile first. The
manual test plan is in [testing.md](testing.md).

## 6. Updating or removing

- To move to a newer upstream commit: `./scripts/sync-upstream.sh <commit>` and
  resolve any conflicts.
- To disable a mod: set its file to `off` or remove it, then restart.
- To remove the overlay: rebuild from an unpatched upstream checkout, or set all
  four files to `off`. The overlay does not install anything outside the app
  runtime and the settings files.
