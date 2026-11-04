# Patches

`0001-gameplay-switches.patch` is the initial overlay. It is one patch because
the four switches share the same settings-page framework and the same
`game_patches.c` block; splitting it at file boundaries would produce patches
that do not compile on their own.

The `series` file lists the patches in order. The scripts apply them to a fresh
checkout of the upstream commit recorded in `../upstream.json`.

## Applying

```bash
cd ..
./scripts/bootstrap.sh
./scripts/apply.sh
```

## Regenerating

From a patched `.upstream/` checkout:

```bash
git -C .upstream diff HEAD > patches/0001-gameplay-switches.patch
```

or, after an upstream move:

```bash
./scripts/sync-upstream.sh <new-commit>
```

Do not edit `.upstream/` as a permanent source tree. Keep the patch as the
source of truth, and keep game files, keys, saves and built apps out of this
directory.
