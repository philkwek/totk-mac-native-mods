# Unlimited health

**Setting:** `unlimited-health.txt`  
**Site:** `main+0x650414` (`ldr x8,[x0]`)  
**Status:** verified on 2026-11-04 for ordinary damage.

The life gauge's per-frame update starts by reading the object's type. The
veneer copies `[x0,#0x18]` (the maximum life, in quarter hearts) over `[x0,#8]`
(the current life) before running the original load.

Gloom, drowning, void-outs and scripted deaths do not go through this value and
are left as the game has them. The switch is off by default; a mismatched
instruction leaves the site unchanged.
