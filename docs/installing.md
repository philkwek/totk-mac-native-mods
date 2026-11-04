# Installing the mods

There are two ways to get the mods:

- **Fast path:** update the runtime of an existing **Tears of the Kingdom
  1.0.0** app in place. No game file or keys are needed, and it takes a few
  minutes.
- **Full build:** build a separate 1.0.0 app from your own base game and
  `prod.keys`. This takes 20–40 minutes and about 25 GB of free space.

Both are started by double-clicking **`Install Mods.command`** in the
repository folder.

## Fast path: update an existing 1.0.0 app

### 1. Check the version

In Finder, select `Tears of the Kingdom.app`, press **Command-I**, and read
**Version**. It must be **1.0.0**.

You can also open the game, press **1**, and look at the **Gameplay** page. If
it says “Not in this version”, this release does not support your game version.

### 2. Run the installer

Double-click `Install Mods.command`. If macOS blocks it, right-click it, choose
**Open**, then **Open** again.

The installer finds the app in the usual places (`/Applications`,
`~/Applications`, `~/Games`, `~/Desktop`). If it cannot, it asks you to select
the app.

### 3. Confirm and wait

Click **Update** when the installer asks, then wait a few minutes. The
installer:

1. Fetches the pinned MacNativeGames source into `.upstream/` and applies the
   patch series.
2. Uses upstream's `update_runtime.py` to build the patched runtime and replace
   only the runtime inside your app.
3. Checks the app's game data and code modules, runs a loader probe, signs the
   app, and rolls back if anything fails.

Your game data, saves, ROM and keys are not touched. The app remains a 1.0.0
app. The four switches are off until you turn them on.

### 4. Turn the switches on

Open the game, press **1**, choose **Gameplay**, and turn on the switches you
want. Then **restart the game**; the patches are applied before the game starts.

### If the fast path refuses the app

The runtime updater accepts apps whose game data and rewritten code modules
match the pinned upstream commit. If your app was built from a different
MacNativeGames version, or with code mods that change those modules, it stops
without changing the app. The installer then offers the full build path.

## Full build: a separate 1.0.0 app

Use this when you do not have a 1.0.0 app, or when the fast path refuses the app
you have.

### What you need

- macOS 26 or later on Apple silicon.
- The Xcode command line tools (`xcode-select --install`).
- Homebrew and the upstream dependencies:

```bash
brew install opus libvpx python@3.14
```

- Your own Tears of the Kingdom **1.0.0** XCI or NSP (the base game, not the
  update).
- `prod.keys` dumped from your own console.
- Free disk space for the upstream build (about 25 GB).

### Run the installer's build option

1. Double-click `Install Mods.command`.
2. Choose **Build** when the installer offers.
3. Select the base game 1.0.0 file and `prod.keys`.
4. Wait 20–40 minutes. Do not close the lid or stop the Terminal window.

The app is written to `~/Applications/Tears of the Kingdom (Mods).app` by
default. Your current app and saves stay where they are.

**Version warning:** a 1.4.3 save may not open in a 1.0.0 app. Back up your
profile before testing:
`~/Library/Application Support/MacNativeGames/TOTK/profile`.

### Manual build

```bash
git clone https://github.com/philkwek/totk-mac-native-mods
cd totk-mac-native-mods
./scripts/bootstrap.sh
./scripts/apply.sh
./scripts/build.sh \
  --rom "/path/to/TOTK [0100F2C0115B6000][v0].xci" \
  --keys "$HOME/path/to/prod.keys"
```

The default output is `.build/Tears of the Kingdom.app`; use `--out` and
`--work` to change the app and build folder. The app contains your game data and
must not be shared.

For an NSP that needs a separate font source, run upstream's `build_app.py`
directly with the same patched `.upstream/` checkout, adding its `--shared-fonts`
or `--firmware` option.

## Enable the switches

Open the app, press **1** for the settings panel and choose the **Gameplay**
page. The four switches are off by default. They are written into the runtime
before the game starts, so a change is kept for the next launch; the title adds
“(from the next launch)” until then.

You can also write the files directly next to `controls.txt`:

```text
unlimited-durability.txt   on
unlimited-health.txt       on
unlimited-arrows.txt       on
unlimited-battery.txt      on
```

`on`, `1` or `true` enable a switch; `off`, a blank file or a missing file
leaves it off.

## Testing safely

Use a **copy** of your profile for testing. The mods change gameplay and can
alter a save in ways the vanilla game does not. Back up the profile first. The
manual test plan is in [testing.md](testing.md).

## Updating or removing

- **Update the mods:** run `Install Mods.command` again. It replaces the
  runtime; your game data and saves stay.
- **Disable a mod:** set its file to `off` or remove it, then restart.
- **Remove the overlay:** run upstream's `update_runtime.py` from an unpatched
  MacNativeGames checkout. That replaces the patched runtime with a vanilla one;
  your game data and saves stay. Rebuilding the app from unpatched upstream also
  works. Setting all four files to `off` also leaves the game vanilla. The
  overlay does not install anything outside the app runtime and the settings
  files.

## If something goes wrong

See [troubleshooting.md](troubleshooting.md). The installer writes a log to
`~/Library/Logs/totk-mac-native-mods/install-<date>-<time>.log`.
