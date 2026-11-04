# Compatibility

## Overlay releases

| Overlay | Upstream MacNativeGames commit | TOTK | Features |
|---|---|---|---|
| v0.1.0 | `933b6a0d1438de160208a0a13eb5e8d7a2cb8094` | 1.0.0 | durability, health, arrows (consume-gate verified), battery (gauge-verified, device test pending) |

The upstream commit is also recorded in `upstream.json`. The patch series is
generated against exactly that commit; `scripts/verify.sh` checks that it still
applies.

## Game versions

Only **Tears of the Kingdom 1.0.0** is covered. The settings page shows
“Not in this version” on 1.1.2, 1.2.1 and 1.4.3. Supporting another version
means finding and verifying its instruction sites and adding a version-specific
patch series; it is not a matter of reusing the 1.0.0 addresses.

## Existing apps

`Install Mods.command` updates the runtime of an existing 1.0.0 app in place
with upstream's `update_runtime.py`. It does not touch the game data, saves,
ROM or keys. Before changing anything it checks the app's rewritten code modules
and game data against the pinned upstream commit. An app from another upstream
version is refused safely; the installer then offers a separate 1.0.0 build.

## Feature status

| Feature | Source-verified | In-game verified |
|---|---|---|
| Unlimited durability | yes | 2026-11-04: sword, bow and shield |
| Unlimited health | yes | 2026-11-04: damage; gloom/drowning/void-outs left alone |
| Unlimited arrows | yes | candidate: count stayed 13 after a fired shot; no-patch control was 13 → 12 → 11 |
| Unlimited battery | yes | gauge 3000.0 → 100.0 → 3000.0 with the switch on; **real Zonai device not yet tested** |

“Source-verified” means the patch site and the 1.0.0 original word match the
retail module and the source tests pass. It does not mean the feature has been
played through every situation.

## Updating upstream

`scripts/sync-upstream.sh [commit]` updates the pinned commit, re-applies the
patch series with a 3-way merge, regenerates the patch, and runs verification.
If the upstream settings framework or `game_patches.c` moved, resolve the
conflict in `.upstream/` and regenerate the patch; do not edit `.upstream/` as a
long-term source tree.
