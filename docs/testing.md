# Testing

No test in this repository boots the game. The source tests check that the
patch series applies and that the patched runtime reserves the expected 1.0.0
instruction sites. The gameplay checks below are manual and require your own
game, macOS 26 and Apple silicon.

## Source tests

```bash
./scripts/verify.sh
```

This runs:

- `scripts/apply.sh --check` against a fresh pinned upstream checkout.
- `tests/test_patch_series.py` (series and expected-site checks).
- the upstream `tests/test_patch_sites.py` with the overlay's additions.
- `tests/test_installer.sh` (installer shell syntax and `--help`; no macOS
  tools needed).
- `scripts/check-repo.sh` (forbidden game data, keys, saves, built apps, large
  files).

The installer's plan can be checked without changing anything:

```sh
./scripts/install.sh --dry-run \
  --app "/Applications/Tears of the Kingdom.app" \
  --work "$HOME/Games/TOTK_build"
```

## One-click installer record

On 2026-11-04, `scripts/install.sh` was run against a **copy** of a TOTK 1.0.0
app built from the pinned `933b6a0` commit:

- First run: 417 s. Second run: 152 s.
- `update_runtime.py` kept the app's game data, replaced the runtime, and the
  app passed its `--check`.
- `codesign --verify --strict` passed after the update.
- The updated runtime contains `unlimited-durability.txt`,
  `unlimited-health.txt`, `unlimited-arrows.txt` and `unlimited-battery.txt`.

The test copy, not the only installed app, was updated.

## Manual test record

Use a copied profile and a test settings folder. The 2026-11-04 candidate used:

- TOTK 1.0.0, build `082CE09B06E33A123CB1E2770F5F9147709033DB`.
- macOS 26, Apple silicon.
- `unlimited-arrows.txt` and `unlimited-battery.txt` set to `on`.

### Unlimited durability

- Hit a sword, a bow and a shield; each should stay at its maximum durability.
- Fused items share the same durability; the Master Sword's energy is a
  separate meter and is not covered.

### Unlimited health

- Take damage; the life gauge should refill to maximum.
- Gloom, drowning, void-outs and scripted deaths are intentionally left as the
  game has them.

### Unlimited arrows

- Read the count through the chain
  `[[[main+0x4646C60]+0x138]+0xBE8]+0` (the helper's data pointer), or watch the
  in-game total.
- Fire one or more arrows with the switch on: the count should not decrease.
- Pick up or buy arrows: the count should **increase** (`+1` is not gated).
- Use a material or collect a rupee: that count should still change.
- Fire down to one arrow, then fire again: the count should stay at one.
- If a multishot bow is available, test it.
- Known caveat: dropping or selling exactly one arrow may also be gated.

### Unlimited battery

- **Gauge test:** resolve the battery chain
  `[[[main+0x4663F08]+0x1E8]+0x58]+0xF8`, then read/write `+0x5C`. With the
  switch on, poking it from 3000.0 to 100.0 should snap back to 3000.0.
- **Device test (still open):** use the Ukouh Shrine fan (the first Great Sky
  Island shrine) or a device dispenser. Confirm the fan does not stop and the
  gauge stays full. If the gauge stays full but the fan still expires, the NOP
  is only cosmetic and the real energy field must be found.
- Battery upgrades: the patch stores the item's current maximum, so it should
  follow 3000.0 per cell up to 24000.0 at eight cells; only the one-cell state
  has been available so far.

### Arrows: why the gate is `-1` only

The bow consume path calls the generic value-array helper with the arrow
descriptor and `w1 = -1`. The veneer compares `x0` with
`[[main+0x4646C60]+0x138]+0xBC0` and zeroes only a `-1` delta. A `+1` pickup or
purchase still adds. Gating every delta on the descriptor would silently stop
arrow collection.

## Reading the log

With `TOTK_DEBUG_LOG=1`, the runtime log shows one line per switch:

```text
[totk] 1.0.0: unlimited arrows: ... on, veneer at main+0x2aa6c50
[totk] 1.0.0: unlimited battery: ... on, main+0xb6b27c 540000a8 -> d503201f
```

If a site does not match, the line says `holds …, expected …; left off` and the
game continues without that switch.
