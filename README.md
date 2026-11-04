# TOTK Mac Native Mods

Unofficial gameplay mods for [MacNativeGames](https://github.com/ly05010419/MacNativeGames),
the native Apple-silicon port of *The Legend of Zelda: Tears of the Kingdom*.

This is a **patch overlay**, not a fork and not a playable app. It pins one
upstream commit and adds four optional Gameplay switches to the runtime:

| Mod | Setting file | Status |
|---|---|---|
| Unlimited durability | `unlimited-durability.txt` | Verified on 2026-11-04 with a sword, bow and shield |
| Unlimited health | `unlimited-health.txt` | Verified; gloom, drowning, void-outs and scripted deaths are unchanged |
| Unlimited arrows | `unlimited-arrows.txt` | Consume gate verified; `+1` pickups and purchases still add |
| Unlimited battery | `unlimited-battery.txt` | **Beta**: gauge refill verified; real Zonai-device drain still needs testing |

**Tears of the Kingdom 1.0.0 only.** The settings rows say “Not in this version”
on 1.1.2, 1.2.1 and 1.4.3.

## What this repository does not include

- No game program, art, text, audio, shaders, ROMs, keys, firmware, saves,
  extracted or rewritten modules, or built applications.
- No `TOTK_build/`, extracted game files, shader caches, or screenshots.
- No prebuilt app. The build script uses **your** game file and **your** keys;
  the resulting app contains your game data and must not be shared.

## Requirements

- macOS 26 or later on Apple silicon.
- The Xcode command line tools.
- Homebrew with the upstream build dependencies (`opus`, `libvpx`, `python@3.14`).
- Your own Tears of the Kingdom 1.0.0 XCI or NSP and `prod.keys`.
- Enough free disk space for the upstream build (the game data is large).

## Quick start

```bash
git clone https://github.com/philkwek/totk-mac-native-mods
cd totk-mac-native-mods

./scripts/bootstrap.sh          # fetch the pinned upstream commit into .upstream
./scripts/apply.sh              # apply the overlay
./scripts/build.sh \
  --rom "/path/to/TOTK [0100F2C0115B6000][v0].xci" \
  --keys "$HOME/path/to/prod.keys"
```

The app is written to `.build/Tears of the Kingdom.app` by default. You can
choose another path with `--out` and another work folder with `--work`.

Before building, `./scripts/verify.sh` checks that the patch series applies to
the pinned upstream and that the expected instruction sites are reserved. It
needs no game data or keys.

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

## Compatibility

| Overlay | Upstream commit | TOTK | Status |
|---|---|---|---|
| v0.1.0 | `933b6a0d1438de160208a0a13eb5e8d7a2cb8094` | 1.0.0 | durability/health verified; arrows consume-gate verified; battery gauge-verified, device test pending |

See `docs/compatibility.md` for the full matrix and `docs/testing.md` for the
manual test record.

## Repository layout

```text
patches/      the overlay as one git patch and its series file
scripts/      bootstrap, apply, build, verify, sync-upstream, package
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
- The TOTK 1.0.0 research in `docs/findings/TOTK-arrows-battery-findings.md`.

## Contributing

One mod per pull request, default off, with an instruction-word guard and a
manual test record. Do not include game files, keys, saves, screenshots of game
content, or built apps. Do not edit upstream source directly; change the patch
series and run `./scripts/verify.sh`.
