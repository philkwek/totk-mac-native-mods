# TOTK 1.0.0: unlimited arrows and Zonai battery — findings

Date: 2026-11-04. Build: `082CE09B06E33A123CB1E2770F5F9147709033DB` (1.0.0, native macOS).
Scope: research only. The game-patch source, installed app, and real profile were not modified. A
diagnostic read-only watchpoint mode in `games/totk/runtime/mem_scan.h` was used temporarily for the
investigation and reverted. All gameplay testing used byte-identical copies of the player's profile, and
the real profile was re-verified after the session (36 files, 14 dirs, `ok: true`).

## 1. Short answer

- **Unlimited arrows is implementable at the exact consume call.** The live count is confirmed at
  `[[[main+0x4646C60]+0x138]+0xBE8] + 0`. A real bow shot decrements it (13 → 12 → 11), and the write is
  `main+0x2393718` (`current += delta`), called from `main+0xEF02D0` with `w1 = −1`, `w2 = 0`, and `x0` =
  the arrow value-array descriptor. A descriptor-checked veneer at that call site can zero the delta for
  arrows only.
- **Unlimited Zonai battery is feasible as a gauge refill**, using the existing 1.0.0 pointer chain and a
  one-instruction change in the gauge update at `main+0xB6B27C` (`b.hi` → `nop`). This makes the update
  store the current maximum into the gauge's current-energy field every frame. It is the in-code equivalent
  of the community `Inf. Battery` pointer cheat, but scales with battery upgrades instead of hardcoding
  3000. **Actual device drain could not be tested because the available save has no Zonai devices.**

## 2. What already exists in the community

The 1.0.0 cheat list (same build ID) contains both features as **pointer writes**, not instruction patches:

```
998 Arrows
  580F0000 04646C60      ; F = [main+0x4646C60]
  580F1000 00000138      ; F = [F+0x138]
  580F1000 00000BE8      ; F = [F+0xBE8]
  780F0000 00000000      ; F += 0
  640F1000 00000000 000003E6   ; [F] = 998

Inf. Battery
  580F0000 04663F08      ; F = [main+0x4663F08]
  580F1000 000001E8      ; F = [F+0x1E8]
  580F1000 00000058      ; F = [F+0x58]
  580F1000 000000F8      ; F = [F+0xF8]
  780F0000 0000005C      ; F += 0x5C
  640F1000 00000000 453B8000   ; [F] = 3000.0f
```

Sources: the 1.0.0 list at `imwmi.com/cheats/716.html` (BID `082CE09B06E33A12`), and the same list carried
by `bad1dea/NXCheats`. The 1.1.0 list also has an instruction patch labelled **"bow and arrow do not
decrease"** (`main+0x15CE710` → `52800001`, `mov w1,#0`), which shows the game exposes a consume amount that
can be forced to zero. The 1.2.1 list uses different pointer chains (`main+0x4721B98` for arrows,
`main+0x4728538` for battery), so those addresses must not be used on 1.0.0.

## 3. Live confirmation on 1.0.0

Both chains were read and exercised in the existing candidate app with `TOTK_PROFILE_DIR` pointing at a
copy. The exact heap addresses below are session-specific; the offsets are the stable part.

### 3.1 Arrows

```
[main+0x4646C60]              = 0x00000003763E0868   (inventory manager)
[+0x138]                      = 0x00000003765441F8   (item-count container)
[+0xBE8]                      = 0x0000000376551F68   (arrow-count array)
[+0x0]                        = 13                   (normal arrows; HUD showed 13)
```

Holding ZR on a real bow and releasing consumed one arrow; the value went 13 → 12, then 12 → 11 on the next
draw. The record is an array of 32-bit counts: `13, -1, 13, -1, 0, -1, 0, -1` at full state. Index 0 is the
normal arrow count; the other slots are reserved/arrow-type values and should not be touched by a refill.

The count is read through generic inventory-array getters at `main+0x841168` (HUD) and `main+0x999D88`
(gameplay/inventory). The **consume write is now named**: a write watchpoint on the count array landed after
the timed shots, three hits for three shots, and the count went 13 → 10. The write is
`main+0x2393718`, called from `main+0xEF02D0`:

```
 EF02D0  bl 0x2393700            ; w1 = delta, w2 = index, x0 = value-array descriptor

 2393700  ldr  w8, [x0, #0x20]   ; array size
 2393704  cmp  w8, w2
 2393708  ldr  x9, [x0, #0x28]   ; data pointer
 239370c  csel w8, w2, wzr, hi
 2393710  ldr  w10, [x9, w8, sxtw #2]
 2393714  add  w10, w10, w1      ; current += delta
 2393718  str  w10, [x9, w8, sxtw #2]
```

At the three hits `w1 = 0xFFFFFFFF` (−1), `w2 = 0`, `x0 = 0x376544DB8` (the arrow value-array
descriptor) and `x9 = 0x376551F68` (the count array). The descriptor is `[manager+0x138] + 0xBC0`; its
`+0x20` is the array size (8) and `+0x28` is the data pointer. The same helper is used for other value
arrays, so a patch on `0x2393714`/`0x2393718` would freeze every inventory count. The safe gate belongs at
the call site and must compare `x0` with the arrow descriptor.

### 3.2 Battery

```
[main+0x4663F08]              = 0x0000000B33E626A8   (battery singleton)
[+0x1E8]                      = 0x0000000B650E1538   (energy parent)
[+0x58]                       = 0x0000000B650E17F8   (energy mid)
[+0xF8]                       = 0x0000000B6687D2D0   (gauge widget)
[+0x5C]                       = 3000.0f              (current energy shown by the gauge)
```

The battery item itself lives in the inventory under item ID `0xAFD01D68`:

```
inventory manager +0x198     -> item-stack array (stride 0x28)
item stack +0x18             = 3000.0f
item stack +0x1C             = 3000.0f   <-- maximum capacity (UI divides by 1000)
item stack +0x20             = 3000.0f
```

Live checks:

- Reading the gauge gave `3000.0` (one cell; the code also carries a `24000.0` maximum, i.e. 8 cells).
- Poking the gauge `+0x5C` to `100.0` made the HUD gauge animate down/up; poking the item `+0x1C` to `100.0`
  clamped the gauge to `100.0`. Restoring `+0x1C` to `3000.0` brought the gauge back to `3000.0`.
- Idle writes to the gauge were zero, so the gauge is not continuously rewritten when no device is active.

The gauge update is `main+0xB6B1D8`. It reads the item maximum into `s9` and clamps the gauge:

```
 B6B25C  ldr  s0, [x8, #0x1C]      ; item maximum
 B6B264  ldr  s9, [sp, #0x8]
 B6B270  ldr  s8, [x19, #0x44]     ; gauge current (widget +0x5C)
 B6B274  fcmp s9, s8
 B6B27C  b.hi B6B290               ; if maximum > current, skip the store
 B6B28C  str  s9, [x19, #0x44]     ; gauge = maximum
```

## 4. Implementation candidates

Both fit the existing pattern: read a settings file in `game_patches.c` before the guest starts, patch one
word, leave the installed app alone, default off. Neither has been added to the repository yet.

### 4.1 Battery (recommended candidate)

| Item | Value |
| --- | --- |
| Site | `main+0xB6B27C` |
| Original word | `0x540000A8` (`b.hi 0xB6B290`) |
| Replacement | `0xD503201F` (`nop`) |
| Effect | The gauge update falls through and stores `s9` (the item's current maximum, 3000.0 for one cell, 24000.0 at eight cells) into `[x19,#0x44]` (widget `+0x5C`) every frame. |
| Why this over the cheat | The community code hardcodes `3000.0`; this stores the real maximum, so it follows battery upgrades. |
| Verification without devices | Poke the gauge `+0x5C` to `100.0`; with the patch on it should snap back to the maximum within a frame. With the patch off it stays/moves gradually. |
| Risk | It is a **gauge-level** refill. If the power system reads the gauge every frame, it behaves as unlimited energy. That cannot be confirmed until a Zonai device is available. It must not be described as device-tested. |

A more invasive alternative is a veneer that writes `3000.0`/the current maximum to the gauge from a
per-frame hook. The one-word `nop` is smaller, reversible, and has no veneer-space cost.

### 4.2 Arrows

**Recommended: descriptor-checked delta gate at `main+0x2393714`.**

| Item | Value |
| --- | --- |
| Site | `main+0x2393714` |
| Original word | `0x0B01014A` (`add w10,w10,w1`) |
| Veneer | Compare `x0` with the arrow descriptor; zero `w1` only when it matches; perform the add; branch back to `0x2393718`. |

Veneer sketch (clobbers only `x16`, which is not used by the surrounding code):

```
  adrp x16, main+0x4646000
  ldr  x16, [x16, #0xC60]    ; inventory manager
  ldr  x16, [x16, #0x138]    ; item-count container
  add  x16, x16, #0xBC0      ; arrow value-array descriptor
  cmp  x0, x16
  b.ne 1f
  mov  w1, #0                ; delta 0 for arrows only
1:
  add  w10, w10, w1          ; the replaced instruction
  b    0x2393718             ; next instruction in the helper
```

Why this site: `0x2393700` is the generic “current += delta” helper for every value array. Zeroing `w1`
unconditionally would freeze rupees, materials and every other count. The descriptor check keeps the gate
on the normal-arrow array (index 0) and leaves every other array alone.

Verification: fire three arrows with the gate on; the count should stay at its pre-shot value. Then use a
material or collect a rupee and confirm that count still changes. The HUD keeps the real number; no 999
forcing is involved.

The old blunt option (per-frame write of 999 to index 0) remains a fallback but is no longer needed now
that the consume call is named.

## 5. What remains unverified

- **Actual Zonai device drain.** The save used for testing has no Zonai devices, by the user's own report.
  The battery candidate is therefore verified only at the gauge/energy-field level.
- **Arrow consume gate.** The call site and the descriptor check are known; the veneer has not been
  implemented or tested yet.
- **Battery upgrades.** The candidate reads the real maximum, but only the base 3000.0 state was available.
- **Long-session behaviour and save/reload.** The pointer chains are rebuilt on each boot; the existing
  candidate was relaunched several times and the chain resolved each time, but a save/reload cycle was not
  exercised.

## 6. Recommended next step

Implement the two switches as default-off settings in the candidate:

- `unlimited-battery.txt` → the `main+0xB6B27C` `nop` candidate, verified by poking the gauge.
- `unlimited-arrows.txt` → first try to finish the clean consume-site search; if it cannot be found
  safely, ship the index-0 refill with an explicit "HUD count is forced" note.

Do not replace `/Applications/Tears of the Kingdom.app` or enable either switch for normal play until the
battery candidate has been exercised with a real Zonai device. The real profile is unchanged; the real
settings folder still has `unlimited-durability.txt` and `unlimited-health.txt` set to `on`, so a normal
launch of the candidate would apply those two existing features to the real save.

## 7. Implementation status (2026-11-04)

Implemented in `work/MacNativeGames-update` and built into the candidate app only:

- `games/totk/runtime/game_patches.c`
  - `unlimited-arrows.txt`: an 11-word veneer at `main+0x2393714` compares `x0` with
    `[[main+0x4646C60]+0x138]+0xBC0` and zeroes `w1` only for the observed `-1` consume delta. `+1`
    pickups/purchases still add. The veneer sits at `main+0x2AA6C50` in this build; the layout guard now
    covers `base + 0x80`.
  - `unlimited-battery.txt`: the direct word patch `main+0xB6B27C` `0x540000A8` -> `0xD503201F` (`nop`),
    applied through a new single-word switch path alongside the existing veneer switches.
  - The active flags are now durability (0), health (1), arrows (2), battery (3).
- `games/totk/runtime/settings_panel.h`: four Gameplay switches, each default off and titled
  "(from the next launch)" while the saved value is not the one in force.
- `games/totk/runtime/runtime.h`: the active-index comment.
- Tests: `tests/settings_panel_probe.m` (four switches, row count 19), `tests/test_patch_sites.py`
  (new sites are 1.0.0-only), and a per-run `SETTINGS_TEST_DIR` in `tests/test_settings_panel.py` so the
  panel switches can read back their files.

Verified in the candidate:

- Runtime log: `unlimited arrows ... on, veneer at main+0x2aa6c50`; `unlimited battery ... on,
  main+0xb6b27c 540000a8 -> d503201f`.
- Arrows: with the switch on, the count at `[[[main+0x4646C60]+0x138]+0xBE8]+0` stayed at 13 across a
  fired bow shot (aim and post-release screenshots captured). The prior no-patch control already showed
  13 -> 12 -> 11.
- Battery: with the switch on, poking the gauge `+0x5C` from 3000.0 to 100.0 snapped back to 3000.0.
- `python3 tests/test_patch_sites.py`: 15 tests, OK.
- The new Gameplay assertions in the settings-panel probe pass. The full
  `test_settings_panel.py` then stops at an unrelated window-rounding check
  (1511x850 vs the expected 1513x851) on this display; the same check also stops the untouched 1.4.3 and
  BotW variants.

Still open:

- **Real Zonai device drain.** The switch is implemented and gauge-verified, but not device-tested. Use the
  Ukouh Shrine fan (first Great Sky Island shrine) or a device dispenser and confirm the fan does not stop.
  If the gauge stays full but the fan still expires, the NOP is only cosmetic and the actual energy field
  must be found.
- Battery upgrades (multi-cell save), save/reload, and a long-session run.
- Arrow edge cases: pickup/purchase still add (the code preserves `+1`), multishot bows, and dropping or
  selling exactly one arrow.

Safety: the verification used the copies `work/totk-gameplay-mods/profile-next` and
`work/totk-gameplay-mods/settings-next`; the candidate app at
`work/totk-gameplay-mods/Tears of the Kingdom.app` was updated, and the real profile and settings were not
modified.
