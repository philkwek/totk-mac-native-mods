# Unlimited battery

**Setting:** `unlimited-battery.txt`  
**Site:** `main+0xB6B27C` (`b.hi`)  
**Status:** **beta** — gauge refill verified; a real Zonai device drain test is
still pending.

The battery gauge update (`main+0xB6B1D8`) loads the battery item's current
maximum into `s9` and the gauge's current energy from `[x19,#0x44]`, then skips
the store while maximum > current. The patch replaces the `b.hi` with `nop`, so
the update falls through and stores the real maximum every frame.

The patch follows battery upgrades: 3000.0 for one cell, up to 24000.0 at eight
cells. It is not the community cheat's hardcoded 3000.0.

## Verification

- Candidate: poking the gauge `+0x5C` from 3000.0 to 100.0 snapped back to
  3000.0 with the switch on.
- **Open:** use the Ukouh Shrine fan (first Great Sky Island shrine) or a device
  dispenser and confirm the fan does not stop. If the gauge stays full but the
  fan still expires, this is only a cosmetic refill and the actual energy field
  must be found.

The switch is off by default. A mismatched site word leaves the patch off.
