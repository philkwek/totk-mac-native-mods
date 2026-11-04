# TOTK Mac Native Mods

Unofficial gameplay mods for [MacNativeGames](https://github.com/ly05010419/MacNativeGames),
the native Apple-silicon port of *The Legend of Zelda: Tears of the Kingdom*.

This is a **patch overlay**, not a fork and not a playable app. It adds four
optional Gameplay switches to the MacNativeGames runtime:

| Mod | Setting file | Status |
|---|---|---|
| Unlimited durability | `unlimited-durability.txt` | Verified on 2026-11-04 with a sword, bow and shield |
| Unlimited health | `unlimited-health.txt` | Verified; gloom, drowning, void-outs and scripted deaths are unchanged |
| Unlimited arrows | `unlimited-arrows.txt` | Consume gate verified; `+1` pickups and purchases still add |
| Unlimited battery | `unlimited-battery.txt` | **Beta**: gauge refill verified; real Zonai-device drain still needs testing |

**Tears of the Kingdom 1.0.0 only.** The settings rows say “Not in this version”
on 1.1.2, 1.2.1 and 1.4.3.

## Before you start

### 1. Check your game version

In Finder, select your `Tears of the Kingdom.app`, press **Command-I**, and read
**Version**. These mods work with **1.0.0**.

You can also open the game, press **1**, and look at the **Gameplay** page. If
it says “Not in this version”, this release does not support your game version.

### 2. What you need

- An existing MacNativeGames **Tears of the Kingdom 1.0.0** app.
- macOS 26 on Apple silicon, the Xcode command line tools, and Homebrew with
  `opus`, `libvpx` and `python@3.14` — the same tools you used to build TOTK.
- A few GB free for the runtime build.

The fast path needs **no game file, no `prod.keys`, and no second copy of the
game**. It changes only the runtime inside your existing app.

If your app is not 1.0.0, see [If you do not have a 1.0.0 app](#if-you-do-not-have-a-100-app).

## Quick start

1. Download this repository. A `git clone` is best; a ZIP also works.
2. Double-click **`Install Mods.command`** in the repository folder.
   - If macOS blocks it, right-click it, choose **Open**, then **Open** again.
3. If the installer asks, select your `Tears of the Kingdom.app`.
4. Click **Update** when asked, then wait a few minutes. The installer builds
   the patched runtime and installs it into the app. Your game data, saves, ROM
   and keys are not touched.
5. When it finishes, open the game, press **1**, choose **Gameplay**, and turn
   on the switches you want.
6. **Restart the game.** The switches are applied before the game starts.

The switches are off by default. The installer runs the app's own check before
it finishes, so a normal launch follows.

### What the installer does

- Fetches the pinned MacNativeGames source into `.upstream/` and applies the
  patch series.
- Uses upstream's `update_runtime.py` to build the patched runtime and install
  it into the existing app. It checks the app's game data and code modules
  first, runs a probe, signs the app, and rolls back if anything fails.
- Takes a few minutes, not the 20–40 minutes of a full game build.

## If you do not have a 1.0.0 app

The installer can build a **separate 1.0.0 app** with the mods from your own
1.0.0 base game and `prod.keys`:

1. Double-click `Install Mods.command` and choose **Build** when it offers.
2. Select your **base game 1.0.0** XCI or NSP — not the 1.4.3 update.
3. Select your `prod.keys`.
4. Wait 20–40 minutes. The app is written to
   `~/Applications/Tears of the Kingdom (Mods).app` by default.

An NSP base also needs a firmware or shared-fonts folder. The installer will
stop and show the upstream error; use the manual `build_app.py` command with
`--firmware` or `--shared-fonts` in that case.

This does not change your current app or saves, but a 1.4.3 save may not open
in a 1.0.0 app. Back up your profile first:
`~/Library/Application Support/MacNativeGames/TOTK/profile`.

## Manual install (developers)

<details>
<summary>Commands and requirements</summary>

Fast path (existing 1.0.0 app, no game file):

```sh
git clone https://github.com/philkwek/totk-mac-native-mods
cd totk-mac-native-mods
./scripts/bootstrap.sh
./scripts/apply.sh
python3.14 .upstream/update_runtime.py "/Applications/Tears of the Kingdom.app" \
  --work "$HOME/Library/Application Support/totk-mac-native-mods/work"
```

The work folder can be any writable folder; the installer uses that one. If the
app predates the game-data folder, pass the `TOTK_build` folder from the build
that made the app instead.

Full build (separate app, needs your game file and keys):

```sh
./scripts/build.sh \
  --rom "/path/to/TOTK [0100F2C0115B6000][v0].xci" \
  --keys "$HOME/path/to/prod.keys"
```

The app is written to `.build/Tears of the Kingdom.app` by default; `--out` and
`--work` change the app and work folder. `./scripts/verify.sh` applies and tests
the patch series without a game.

Requirements: macOS 26 on Apple silicon, the Xcode command line tools, Homebrew
with `opus`, `libvpx`, `python@3.14`, and free disk space for the build. The
full build also needs your own TOTK 1.0.0 XCI or NSP and `prod.keys`.
</details>

## Enabling the mods

The switches appear on the settings panel's **Gameplay** page, or you can write
the files next to `controls.txt` in your game data folder:

```text
unlimited-durability.txt   on
unlimited-health.txt       on
unlimited-arrows.txt       on
unlimited-battery.txt      on
```

Each file defaults to off when absent; `on`, `1` or `true` enables it, and any
other word disables it. The patches are applied before the guest starts, so a
change takes effect on the **next launch**; the settings panel adds
“(from the next launch)” while the saved choice is not the one in force.

## Patch-site safety

Each switch checks the original 1.0.0 instruction word before writing. If the
upstream module does not match — a different game version, a build-time mod on
the same site, or a newer upstream commit — that switch is left off with a
message in the log instead of stopping the game. The patch series itself is
pinned, so a newer upstream commit may need `scripts/sync-upstream.sh` and a
manual conflict resolution.

## What this repository does not include

- No game program, art, text, audio, shaders, ROMs, keys, firmware, saves,
  extracted or rewritten modules, or built applications.
- No `TOTK_build/`, extracted game files, shader caches, or screenshots.
- No prebuilt app. The installer builds the patched runtime on your Mac. The
  full-build path uses **your** game file and **your** keys; the resulting app
  contains your game data and must not be shared.

## Compatibility

| Overlay | Upstream commit | TOTK | Status |
|---|---|---|---|
| v0.1.0 | `933b6a0d1438de160208a0a13eb5e8d7a2cb8094` | 1.0.0 | durability/health verified; arrows consume-gate verified; battery gauge-verified, device test pending |

See `docs/compatibility.md` for the full matrix and `docs/testing.md` for the
manual test record.

## Repository layout

```text
Install Mods.command  double-click installer
patches/      the overlay as one git patch and its series file
scripts/      bootstrap, apply, install, build, verify, sync-upstream, package
docs/         compatibility, installing, testing, troubleshooting, mod notes
docs/findings the original TOTK arrows/battery research document
tests/        source-level checks that need no game data
```

## Legal

You must own the game. Use this only with a copy you bought and with keys and
system files dumped from your own console. This is an independent,
non-commercial project. It is not affiliated with, endorsed by, or sponsored by
MacNativeGames, Nintendo, or Apple. See [DISCLAIMER.md](DISCLAIMER.md).

The upstream project is MIT-licensed. This overlay retains the upstream
copyright and adds the mod overlay's copyright; see [LICENSE](LICENSE) and
[NOTICE](NOTICE).

## Credits

- [MacNativeGames](https://github.com/ly05010419/MacNativeGames) — the native
  port, build system, settings framework and the instruction sites this overlay
  builds on. Pinned at `933b6a0d1438de160208a0a13eb5e8d7a2cb8094`.
- MacNativeGames' `update_runtime.py`, which makes the in-place one-click update
  possible without a game file or keys.
- The TOTK 1.0.0 research in `docs/findings/TOTK-arrows-battery-findings.md`.

## Contributing

One mod per pull request, default off, with an instruction-word guard and a
manual test record. Do not include game files, keys, saves, screenshots of game
content, or built apps. Do not edit upstream source directly; change the patch
series and run `./scripts/verify.sh`.
