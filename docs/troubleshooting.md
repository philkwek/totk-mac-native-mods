# Troubleshooting

## `Install Mods.command` will not open

If the repository was downloaded as a ZIP, macOS may quarantine the script.
Right-click `Install Mods.command`, choose **Open**, then **Open** again. A
`git clone` does not have this problem.

You can also run it from Terminal:

```bash
./scripts/install.sh
```

## The installer says my app is not 1.0.0

These mods only work with Tears of the Kingdom **1.0.0**. On 1.1.2, 1.2.1 or
1.4.3 the Gameplay rows say “Not in this version”.

The installer can build a separate 1.0.0 app from your own 1.0.0 base game and
`prod.keys`. It needs 20–40 minutes and about 25 GB. Your current app and saves
stay where they are, but a 1.4.3 save may not open in the 1.0.0 app. Back up
your profile first.

## The installer asks for my game file and keys

The fast path does not need them. The installer asks only when it has to build a
separate 1.0.0 app, for example because your current app is 1.4.3 or its runtime
cannot be updated in place.

## The direct update did not work

The runtime updater accepts apps built by MacNativeGames' `build_app.py` whose
game data and rewritten code modules match the pinned upstream commit. It stops
without changing the app if they do not. The installer then offers the full
build path.

If the app is running, quit it and try again. If the app is in a folder your
user cannot write to, move it to `~/Applications` first.

## The installer cannot find `TOTK_build`

The fast path normally needs no work folder: the app carries the game data the
runtime update checks. A work folder is needed only for an app made before the
game-data folder existed, or when the startup shaders must be remade.

If the installer asks, select the `TOTK_build` folder from the build that made
the app (usually next to your game file). If you no longer have it, use the full
build path instead.

## The app opens but the switches do nothing

- Check that the Gameplay page shows the switches. “Not in this version” means
  the app is not 1.0.0.
- Turn a switch on, then **restart the game**. The patches are applied before
  the game starts; the panel says “(from the next launch)” until then.
- Check the runtime log with `TOTK_DEBUG_LOG=1`. A line saying `left off` means
  the instruction site did not match.

## Where is the installer log?

`~/Library/Logs/totk-mac-native-mods/install-<date>-<time>.log`

Attach the relevant lines when reporting an issue. Do not upload ROMs, keys,
saves, or screenshots of game content.

## The patch series does not apply

The overlay is pinned to one upstream commit. If upstream moved, run:

```bash
./scripts/sync-upstream.sh <new-commit>
```

and resolve any conflict in `.upstream/`. Do not edit `.upstream/` as your
long-term source tree; regenerate the patch instead.

## A switch says it is on but the game behaves as if it is off

Check the runtime log (set `TOTK_DEBUG_LOG=1`). A line such as:

```text
[totk] unlimited battery: main+0xb6b27c holds 00000000, expected 540000a8; left off
```

means the module did not match the 1.0.0 site — a different game version, a
build-time mod on the same instruction, or a different upstream commit. The
switch is deliberately left off instead of stopping the game.

## I enabled a switch but it has no effect yet

The patches are written before the guest starts. Restart the game. The settings
panel title says “(from the next launch)” until the switch is in force.

## The Gameplay page says “Not in this version”

The switches are only mapped for TOTK **1.0.0**. On 1.1.2, 1.2.1 or 1.4.3 the
rows are intentionally unavailable. Supporting another version requires a
separate site map and test pass.

## Arrows still run out

- With zero arrows the mod does not grant an arrow; it preserves the count you
  have.
- The gate is only on the bow consume call's `-1` delta. A different removal
  path, or a multishot bow that consumes a different amount, may not be gated.
- Check the log to confirm the veneer was applied.

## Battery stays full but a device still stops

That is the important open test. The current patch is a gauge-level refill; if a
real Zonai device still expires, the actual energy field is elsewhere and the
NOP is only cosmetic. Report the device, the shrine/dispenser, the time to stop,
and the gauge behavior; do not attach game files or saves.

## The build fails

- Confirm macOS 26 on Apple silicon and the Xcode command line tools.
- Confirm the Homebrew dependencies from [installing.md](installing.md).
- Confirm the ROM is the 1.0.0 base game and the keys are your own.
- The upstream build needs network access for its pinned SPIRV-Cross sources.
- A full build also needs a lot of disk space; see the upstream build log.

## I want to share the result

Do not share the built app or any file produced from your game and keys. The app
contains your game data. Share the overlay repository, not the app.

## Reporting an issue

Include the overlay release, upstream commit, TOTK version, macOS version,
Apple silicon model, the four settings files' states, and the relevant runtime
log lines. Do not upload ROMs, keys, saves, or screenshots of game content.
