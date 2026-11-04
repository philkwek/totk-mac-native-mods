# Troubleshooting

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
