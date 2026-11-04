# Changelog

All notable changes to this overlay are recorded here. The mod release is
separate from the upstream MacNativeGames commit; see `upstream.json` and
`docs/compatibility.md`.

## v0.1.0 - 2026-11-04

Initial release for **Tears of the Kingdom 1.0.0** on the pinned upstream commit
`933b6a0d1438de160208a0a13eb5e8d7a2cb8094`.

- Gameplay page with four default-off switches:
  - Unlimited durability.
  - Unlimited health.
  - Unlimited arrows (consume gate; `+1` pickups and purchases still add).
  - Unlimited battery (gauge refill; beta, real Zonai-device drain not yet tested).
- Patch-site guards so a mismatched upstream instruction leaves the switch off
  instead of stopping the game.
- Settings files: `unlimited-durability.txt`, `unlimited-health.txt`,
  `unlimited-arrows.txt`, `unlimited-battery.txt`.
- Source tests for the reserved patch sites and a manual test record for the
  arrows and battery candidates.
- No game data, keys, saves, or built applications are included.
