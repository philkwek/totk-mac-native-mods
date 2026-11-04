# Unlimited arrows

**Setting:** `unlimited-arrows.txt`  
**Site:** `main+0x2393714` (`add w10,w10,w1`)  
**Status:** consume gate verified in the candidate; count stayed at 13 across a
fired shot. The no-patch control was 13 → 12 → 11.

The bow consume path calls the generic “current += delta” value-array helper
with:

- `x0` = the arrow value-array descriptor, `[[main+0x4646C60]+0x138]+0xBC0`
- `w1` = `-1`
- `w2` = `0`

The veneer compares `x0` with that descriptor and zeroes `w1` **only for the
`-1` consume delta**. A `+1` pickup or purchase still adds, and every other item
array is untouched. The veneer uses `x16`, which the helper does not use.

## Known limits

- With **zero** arrows, the mod does not grant an arrow; it preserves the count
  you already have.
- Dropping or selling exactly one arrow may also be gated because the same
  `-1` delta can be used there.
- A multishot bow that consumes a different amount is not covered by the `-1`
  gate; test it if you have one.
- The HUD keeps the real count; this is not a 999 refill.

The switch is off by default. If the site word does not match, the patch is
left off and the game continues.
