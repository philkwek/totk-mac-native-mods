# Unlimited durability

**Setting:** `unlimited-durability.txt`  
**Site:** `main+0x7C37A8` (`ldr w1,[x8,#8]`)  
**Status:** verified on 2026-11-04 with a sword, a bow and a shield.

The equipment state publisher reads the equipped item's current durability. The
veneer copies the separate maximum record at `[x8,#0x18]` over `[x8,#8]` before
running the original read, so the value never falls. One read serves the weapon,
the bow and the shield (equipment slots 0, 3 and 4).

Fused items use the same durability. The Master Sword's energy is a separate
meter and is not covered. The third record the function publishes is a
different statistic and is left alone.

The switch is off by default. If the original instruction does not match, the
site is left unchanged and the log says `left off`.
