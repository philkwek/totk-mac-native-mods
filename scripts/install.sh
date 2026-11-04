#!/bin/bash
# Install the TOTK Mac Native Mods into a Tears of the Kingdom 1.0.0 app.
#
# Fast path: upstream's update_runtime.py builds the patched runtime from this
# repository and replaces only the runtime inside the app. The game data, saves,
# ROM and keys are not touched, and no game file is needed. This works when the
# app was built by MacNativeGames' build_app.py from the pinned upstream commit
# (or one whose rewritten modules match it).
#
# Fallback: if the app is not 1.0.0, or the runtime update refuses it, build a
# separate 1.0.0 app from the user's own base game and prod.keys.
set -euo pipefail

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
UPSTREAM_DIR=${UPSTREAM_DIR:-"$ROOT/.upstream"}
CONFIG_DIR="$HOME/Library/Application Support/totk-mac-native-mods"
CONFIG="$CONFIG_DIR/settings"
LOG_DIR="$HOME/Library/Logs/totk-mac-native-mods"
APP_NAME="Tears of the Kingdom.app"
MODS_APP_NAME="Tears of the Kingdom (Mods).app"
LOG=

MODE=auto
ASSUME_YES=0
NO_DIALOG=0
OPEN_APP=1
DRY_RUN=0
APP_FROM_ARG=0
ROM_FROM_ARG=0
KEYS_FROM_ARG=0
APP=${APP:-}
WORK=${WORK:-}
ROM=${ROM:-}
KEYS=${KEYS:-}
OUT=${OUT:-}

usage() {
    cat <<'EOF'
TOTK Mac Native Mods installer

Double-click "Install Mods.command" in the repository folder, or run:

  ./scripts/install.sh [options]

The fast path updates the runtime of an existing Tears of the Kingdom 1.0.0
app in place. It needs no game file and no prod.keys, and your game data and
saves are not changed. The gameplay switches are off until you turn them on.

Options:
  --app PATH      the Tears of the Kingdom.app to update (1.0.0)
  --work PATH     build/work folder (TOTK_build); found automatically
  --build         build a separate 1.0.0 app instead of updating in place
  --rom PATH      base game 1.0.0 XCI or NSP (for --build)
  --keys PATH     your prod.keys (for --build)
  --out PATH      output app for --build
  --yes, -y       do not ask; install missing Homebrew packages
  --no-open       do not open the app at the end
  --dry-run       print what would happen; change nothing
  -h, --help      show this help
EOF
}

say()  { printf '\n==> %s\n' "$*"; }
note() { printf '    %s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }

alert() {
    [ "${NO_DIALOG:-0}" = 1 ] && return 0
    command -v osascript >/dev/null 2>&1 || return 0
    osascript - "$1" >/dev/null 2>&1 <<'APPLESCRIPT' || true
on run argv
  display dialog (item 1 of argv) buttons {"OK"} default button "OK" with title "TOTK Mac Native Mods" with icon note
end run
APPLESCRIPT
}

ask_yes_no() {
    local question=$1 label=${2:-Continue} result
    if [ "${ASSUME_YES:-0}" = 1 ] || [ "${NO_DIALOG:-0}" = 1 ]; then
        return 0
    fi
    result=$(osascript - "$question" "$label" 2>/dev/null <<'APPLESCRIPT' || true
on run argv
  set r to display dialog (item 1 of argv) buttons {"Cancel", (item 2 of argv)} default button (item 2 of argv) with title "TOTK Mac Native Mods"
  return button returned of r
end run
APPLESCRIPT
)
    [ "$result" = "$label" ]
}

die() {
    printf '\nERROR: %s\n' "$*" >&2
    alert "$*"
    exit 1
}

choose_file() {
    local prompt=$1 start=${2:-$HOME}
    [ -d "$start" ] || start=$HOME
    osascript - "$prompt" "$start" 2>/dev/null <<'APPLESCRIPT'
on run argv
  set p to POSIX path of (choose file with prompt (item 1 of argv) default location (POSIX file (item 2 of argv)))
  return p
end run
APPLESCRIPT
}

choose_folder() {
    local prompt=$1 start=${2:-$HOME}
    [ -d "$start" ] || start=$HOME
    osascript - "$prompt" "$start" 2>/dev/null <<'APPLESCRIPT'
on run argv
  set p to POSIX path of (choose folder with prompt (item 1 of argv) default location (POSIX file (item 2 of argv)))
  return p
end run
APPLESCRIPT
}

load_config() {
    if [ -f "$CONFIG" ]; then
        # shellcheck disable=SC1090
        . "$CONFIG" 2>/dev/null || true
    fi
    APP=${APP:-}
    WORK=${WORK:-}
    ROM=${ROM:-}
    KEYS=${KEYS:-}
    OUT=${OUT:-}
}

save_config() {
    mkdir -p "$CONFIG_DIR"
    {
        printf 'APP=%q\n' "${APP:-}"
        printf 'WORK=%q\n' "${WORK:-}"
        printf 'ROM=%q\n' "${ROM:-}"
        printf 'KEYS=%q\n' "${KEYS:-}"
        printf 'OUT=%q\n' "${OUT:-}"
    } > "$CONFIG"
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --app) APP=${2:-}; APP_FROM_ARG=1; shift 2 ;;
            --work) WORK=${2:-}; shift 2 ;;
            --rom) ROM=${2:-}; ROM_FROM_ARG=1; shift 2 ;;
            --keys) KEYS=${2:-}; KEYS_FROM_ARG=1; shift 2 ;;
            --out) OUT=${2:-}; shift 2 ;;
            --build) MODE=build; shift ;;
            --update) MODE=update; shift ;;
            --yes|-y) ASSUME_YES=1; NO_DIALOG=1; shift ;;
            --no-open) OPEN_APP=0; shift ;;
            --dry-run) DRY_RUN=1; shift ;;
            -h|--help) usage; exit 0 ;;
            *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
        esac
    done
    if [ -n "$ROM" ] || [ -n "$KEYS" ]; then
        [ "$MODE" = update ] || MODE=build
    fi
}

app_version() {
    plutil -extract CFBundleShortVersionString raw -o - "$1/Contents/Info.plist" 2>/dev/null || true
}

have_common_app() {
    [ -d "/Applications/$APP_NAME" ] \
        || [ -d "$HOME/Applications/$APP_NAME" ] \
        || [ -d "$HOME/Applications/$MODS_APP_NAME" ] \
        || [ -d "$HOME/Games/$APP_NAME" ] \
        || [ -d "$HOME/Desktop/$APP_NAME" ]
}

find_apps() {
    local p
    for p in \
        "/Applications/$APP_NAME" \
        "$HOME/Applications/$APP_NAME" \
        "$HOME/Applications/$MODS_APP_NAME" \
        "$HOME/Games/$APP_NAME" \
        "$HOME/Desktop/$APP_NAME"
    do
        [ -d "$p" ] && printf '%s\n' "$p"
    done
    return 0
}

pick_app() {
    if [ -n "$APP" ]; then
        if [ -d "$APP" ]; then
            return 0
        fi
        if [ "$APP_FROM_ARG" = 1 ]; then
            die "App not found: $APP"
        fi
        APP=
    fi

    local apps=()
    local p
    while IFS= read -r p; do
        if [ -d "$p" ]; then
            case "$p" in
                *.app) apps+=("$p") ;;
            esac
        fi
    done < <(
        {
            find_apps
            if command -v mdfind >/dev/null 2>&1; then
                mdfind "kMDItemCFBundleIdentifier == 'org.macnativegames.totk'" 2>/dev/null || true
            fi
        } | sort -u
    )

    if [ ${#apps[@]} -eq 1 ]; then
        APP=${apps[0]}
        return 0
    fi

    if [ ${#apps[@]} -gt 1 ]; then
        local joined chosen
        joined=$(for p in "${apps[@]}"; do printf '%s\t%s\n' "$p" "$(app_version "$p")"; done)
        if ! chosen=$(osascript - "$joined" 2>/dev/null <<'APPLESCRIPT'
on run argv
  set theItems to paragraphs of (item 1 of argv)
  set chosen to choose from list theItems with prompt "Select the Tears of the Kingdom app to update:" with title "TOTK Mac Native Mods"
  if chosen is false then error number -128
  return item 1 of chosen
end run
APPLESCRIPT
); then
            return 1
        fi
        APP=$(printf '%s\n' "$chosen" | cut -f1)
        return 0
    fi

    if ! APP=$(choose_file "Select your Tears of the Kingdom.app" "/Applications"); then
        return 1
    fi
    [ -d "$APP" ] || die "Not an app bundle: $APP"
    return 0
}

check_app_for_update() {
    [ -d "$APP" ] || die "Not an app: $APP"
    [ -f "$APP/Contents/Info.plist" ] || die "Not a macOS app bundle: $APP"
    local version
    version=$(app_version "$APP")
    [ -n "$version" ] || die "Could not read the app version from $APP/Contents/Info.plist"
    if [ "$version" != "1.0.0" ]; then
        return 1
    fi
    [ -x "$APP/Contents/MacOS/TOTK" ] || die "This is not a MacNativeGames Tears of the Kingdom app (no TOTK executable)."
    [ -d "$APP/Contents/Resources/totk/rewritten/v0" ] || die "This app was not built for TOTK 1.0.0 (no rewritten/v0)."
    return 0
}

app_is_running() {
    pgrep -f -- "$1/Contents/MacOS/TOTK" >/dev/null 2>&1
}

quit_app() {
    local i
    # Ask the app to quit first, so it can save. Fall back to SIGTERM after
    # 15 seconds; the caller has already asked the user to quit.
    osascript -e 'tell application id "org.macnativegames.totk" to quit' >/dev/null 2>&1 || true
    for i in $(seq 1 15); do
        app_is_running "$1" || return 0
        sleep 1
    done
    pkill -TERM -f -- "$1/Contents/MacOS/TOTK" >/dev/null 2>&1 || true
    for i in $(seq 1 15); do
        app_is_running "$1" || return 0
        sleep 1
    done
    return 1
}

ensure_prerequisites() {
    [ "$(uname -s)" = Darwin ] || die "This installer runs on macOS only."
    [ "$(uname -m)" = arm64 ] || die "Tears of the Kingdom native needs an Apple-silicon Mac."
    local macos major
    macos=$(sw_vers -productVersion)
    major=${macos%%.*}
    if [ "$major" -lt 26 ] 2>/dev/null; then
        die "macOS 26 or later is required; this Mac has macOS $macos."
    fi

    if ! xcrun --find clang >/dev/null 2>&1; then
        if ask_yes_no "The Xcode Command Line Tools are missing. Start the installer now? Finish it, then open this installer again." "Install"; then
            xcode-select --install >/dev/null 2>&1 || true
        fi
        die "Xcode Command Line Tools are missing. Run 'xcode-select --install' and try again."
    fi

    if [ ! -x /opt/homebrew/bin/brew ]; then
        alert "Homebrew is missing. The installer will open brew.sh; install Homebrew, then run this again."
        open "https://brew.sh" >/dev/null 2>&1 || true
        die "Homebrew is missing."
    fi

    local missing=()
    [ -d /opt/homebrew/opt/opus/lib ] || missing+=(opus)
    [ -d /opt/homebrew/opt/libvpx/lib ] || missing+=(libvpx)
    command -v python3.14 >/dev/null 2>&1 || missing+=("python@3.14")
    if [ ${#missing[@]} -gt 0 ]; then
        if ask_yes_no "The build needs these Homebrew packages: ${missing[*]}. Install them now?" "Install"; then
            /opt/homebrew/bin/brew install "${missing[@]}"
        else
            die "Missing Homebrew packages: ${missing[*]}"
        fi
    fi
    command -v python3.14 >/dev/null 2>&1 || die "python3.14 is still missing after the Homebrew install."
}

prepare_upstream() {
    say "Preparing the patched MacNativeGames source"
    sh "$ROOT/scripts/bootstrap.sh"
    sh "$ROOT/scripts/apply.sh"
}

choose_work_for_update() {
    if [ -n "$WORK" ]; then
        [ "$DRY_RUN" = 1 ] || mkdir -p "$WORK"
        return 0
    fi

    local appdir p
    appdir=$(dirname "$APP")
    for p in \
        "$appdir/TOTK_build" \
        "$HOME/TOTK_build" \
        "$HOME/Games/TOTK_build" \
        "$HOME/Downloads/TOTK_build" \
        "$HOME/Documents/TOTK_build"
    do
        if [ -d "$p/totk" ] || [ -d "$p/rewritten" ]; then
            WORK=$p
            return 0
        fi
    done

    if [ -f "$APP/Contents/Resources/totk/build/game-data/v0/runtime-tables.bin" ]; then
        WORK="$CONFIG_DIR/work"
        [ "$DRY_RUN" = 1 ] || mkdir -p "$WORK"
        return 0
    fi

    if WORK=$(choose_folder "Select the TOTK_build folder from when you built the game" "$HOME"); then
        [ -d "$WORK" ] || die "Work folder not found: $WORK"
        return 0
    fi
    return 1
}

confirm_update() {
    say "Ready to update:"
    note "$APP"
    note "Game data, saves, ROM and keys are not touched."
    note "Work folder: $WORK"
    if [ "$ASSUME_YES" = 1 ] || [ "$DRY_RUN" = 1 ]; then
        return 0
    fi
    ask_yes_no "Update this app's runtime now? It takes a few minutes. Your game data and saves stay as they are." "Update"
}

run_update() {
    say "Installing the modded runtime into:"
    note "$APP"
    note "Game data, saves, ROM and keys are not touched."
    note "Work folder: $WORK"

    if app_is_running "$APP"; then
        if ask_yes_no "The game is running. Quit it and continue?" "Quit and continue"; then
            quit_app "$APP" || die "The game did not quit. Quit it and try again."
        else
            die "Quit the game first."
        fi
    fi

    if [ ! -w "$(dirname "$APP")" ]; then
        die "The folder that holds the app is not writable: $(dirname "$APP"). Move the app to ~/Applications, or fix its permissions, then try again."
    fi
    if [ ! -w "$APP/Contents" ]; then
        die "The app is not writable by your user: $APP. Move it to ~/Applications, or fix its permissions, then try again."
    fi

    if [ "$DRY_RUN" = 1 ]; then
        say "Would run:"
        note "python3.14 \"$UPSTREAM_DIR/update_runtime.py\" \"$APP\" --work \"$WORK\""
        return 0
    fi

    local out
    out=$(mktemp)
    if python3.14 "$UPSTREAM_DIR/update_runtime.py" "$APP" --work "$WORK" 2>&1 | tee "$out"; then
        rm -f "$out"
        return 0
    fi

    # A changed shader translation chain needs --seed. The overlay does not
    # change it, but an app from a different upstream commit might.
    if grep -q "Pass --seed" "$out" 2>/dev/null \
        && [ -f "$WORK/totk/extracted/v0/romfs/index.json" ] \
        && ask_yes_no "The app needs its startup shaders remade from its build folder (a few more minutes). Continue?" "Remake shaders"; then
        if python3.14 "$UPSTREAM_DIR/update_runtime.py" "$APP" --work "$WORK" --seed 2>&1 | tee -a "$out"; then
            rm -f "$out"
            return 0
        fi
    fi
    rm -f "$out"
    return 1
}

pick_rom() {
    if [ -n "$ROM" ] && [ -f "$ROM" ]; then
        return 0
    fi
    if [ -n "$ROM" ] && [ "$ROM_FROM_ARG" = 1 ]; then
        die "Game file not found: $ROM"
    fi
    ROM=
    if ! ROM=$(choose_file "Select your Tears of the Kingdom 1.0.0 base game (XCI or NSP), not the update" "$HOME/Downloads"); then
        die "No game file selected."
    fi
    case "$ROM" in
        *.xci|*.XCI|*.nsp|*.NSP) ;;
        *) die "Choose an .xci or .nsp file: $ROM" ;;
    esac
    [ -f "$ROM" ] || die "Game file not found: $ROM"
    case "$(basename "$ROM")" in
        *0100F2C0115B6800*) warn "That file looks like the 1.4.3 update. Choose the base 1.0.0 game (title ID 0100F2C0115B6000)." ;;
    esac
}

pick_keys() {
    if [ -n "$KEYS" ] && [ -f "$KEYS" ]; then
        return 0
    fi
    if [ -n "$KEYS" ] && [ "$KEYS_FROM_ARG" = 1 ]; then
        die "Keys file not found: $KEYS"
    fi
    KEYS=
    if ! KEYS=$(choose_file "Select your prod.keys file" "$HOME"); then
        die "No keys file selected."
    fi
    [ -f "$KEYS" ] || die "Keys file not found: $KEYS"
}

run_build() {
    say "Building a separate 1.0.0 app with the mods"
    if [ "$ASSUME_YES" = 1 ] && { [ -z "$ROM" ] || [ -z "$KEYS" ]; }; then
        die "The full build needs --rom and --keys when --yes is used."
    fi
    pick_rom
    pick_keys

    OUT=${OUT:-"$HOME/Applications/$MODS_APP_NAME"}
    [ "$DRY_RUN" = 1 ] || mkdir -p "$(dirname "$OUT")"

    if [ -d "$OUT" ] && app_is_running "$OUT"; then
        if ask_yes_no "The modded app is running. Quit it and continue?" "Quit and continue"; then
            quit_app "$OUT" || die "The app did not quit. Quit it and try again."
        else
            die "Quit the app first."
        fi
    fi

    if [ -z "$WORK" ]; then
        local romdir
        romdir=$(dirname "$ROM")
        if [ -d "$romdir/TOTK_build" ]; then
            WORK="$romdir/TOTK_build"
        else
            WORK="$CONFIG_DIR/work-full"
            [ "$DRY_RUN" = 1 ] || mkdir -p "$WORK"
        fi
    fi

    note "Game file: $ROM"
    note "Keys:      $KEYS"
    note "App:       $OUT"
    note "Work:      $WORK"
    note "This takes 20-40 minutes. Do not close the lid or stop this window."

    if [ "$DRY_RUN" = 1 ]; then
        say "Would run:"
        note "\"$ROOT/scripts/build.sh\" --rom \"$ROM\" --keys \"$KEYS\" --out \"$OUT\" --work \"$WORK\""
        return 0
    fi

    sh "$ROOT/scripts/build.sh" --rom "$ROM" --keys "$KEYS" --out "$OUT" --work "$WORK"
}

finish() {
    local target=$1
    if [ "$DRY_RUN" = 1 ]; then
        say "Dry run complete"
        return 0
    fi
    say "Done"
    note "App: $target"
    note "Open the game, press 1, choose Gameplay, turn on the switches you want, then restart the game."
    note "The switches are off by default."
    note "Log: $LOG"

    if [ "$OPEN_APP" = 1 ] && [ "$DRY_RUN" = 0 ]; then
        if ask_yes_no "Open the game now?" "Open"; then
            open "$target" >/dev/null 2>&1 || true
        fi
    fi
}

main() {
    load_config
    parse_args "$@"

    mkdir -p "$LOG_DIR"
    LOG="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
    exec > >(tee -a "$LOG") 2>&1

    say "TOTK Mac Native Mods installer"
    note "Log: $LOG"

    if [ "$DRY_RUN" = 0 ]; then
        ensure_prerequisites
    else
        note "Dry run: skipping prerequisite checks and file changes."
    fi

    if [ "$MODE" = auto ]; then
        if [ "$ASSUME_YES" = 1 ] && [ -z "$APP" ] && [ -z "$ROM" ] && [ -z "$KEYS" ]; then
            die "Pass --app (to update an app) or --build (with --rom and --keys) when --yes is used."
        fi
        if [ -n "$APP" ] && [ ! -d "$APP" ] && [ "$APP_FROM_ARG" = 0 ]; then
            APP=
        fi
        if [ -n "$APP" ] || have_common_app || { [ -z "$ROM" ] && [ -z "$KEYS" ]; }; then
            pick_app || true
        fi
        if [ -n "$APP" ] && [ -d "$APP" ]; then
            if check_app_for_update; then
                MODE=update
            else
                local version
                version=$(app_version "$APP")
                if [ "$ASSUME_YES" = 1 ] || ask_yes_no "Your app is Tears of the Kingdom $version. These mods only work with 1.0.0. Build a separate 1.0.0 app from your own 1.0.0 game file and prod.keys? It takes 20-40 minutes. Your current app and saves stay where they are, but a $version save may not open in the 1.0.0 app." "Build"; then
                    MODE=build
                else
                    die "These mods need Tears of the Kingdom 1.0.0."
                fi
            fi
        elif [ -n "$ROM" ] || [ -n "$KEYS" ]; then
            MODE=build
        else
            if ask_yes_no "No Tears of the Kingdom 1.0.0 app was found. Build a separate 1.0.0 app with the mods? You will need your 1.0.0 game file and prod.keys; it takes 20-40 minutes." "Build"; then
                MODE=build
            else
                die "No app selected and no build requested."
            fi
        fi
    fi

    if [ "$MODE" = update ]; then
        pick_app || die "No app selected."
        if ! check_app_for_update; then
            local version
            version=$(app_version "$APP")
            if [ "$ASSUME_YES" = 1 ] || ask_yes_no "Your app is Tears of the Kingdom $version. These mods only work with 1.0.0. Build a separate 1.0.0 app from your own 1.0.0 game file and prod.keys? It takes 20-40 minutes. Your current app and saves stay where they are, but a $version save may not open in the 1.0.0 app." "Build"; then
                MODE=build
            else
                die "These mods need Tears of the Kingdom 1.0.0."
            fi
        fi
    fi

    if [ "$MODE" = update ]; then
        if ! choose_work_for_update; then
            if ask_yes_no "The app has no game-data folder and no build folder was selected. A full build is needed instead. Build a separate 1.0.0 app with the mods now? It takes 20-40 minutes and needs your 1.0.0 game file and prod.keys." "Build"; then
                MODE=build
            else
                die "The direct update needs the TOTK_build folder from the app's build."
            fi
        fi
    fi

    if [ "$MODE" = update ]; then
        confirm_update || die "Cancelled."
    fi

    if [ "$DRY_RUN" = 0 ]; then
        prepare_upstream
    fi

    if [ "$MODE" = update ]; then
        if ! run_update; then
            if [ "$ASSUME_YES" = 1 ] || ask_yes_no "The direct runtime update did not work. The app was not changed. This usually means it was built from a different MacNativeGames version. Build a separate 1.0.0 app with the mods now? It takes 20-40 minutes and needs your 1.0.0 game file and prod.keys." "Build"; then
                MODE=build
            else
                die "The app was not changed. See the log: $LOG"
            fi
        else
            [ "$DRY_RUN" = 0 ] && save_config
            finish "$APP"
            return 0
        fi
    fi

    if [ "$MODE" = build ]; then
        run_build
        [ "$DRY_RUN" = 0 ] && save_config
        finish "$OUT"
    fi
}

trap 'status=$?; trap - ERR; printf "\nERROR: the installer stopped (exit %s).\nLog: %s\n" "$status" "${LOG:-}" >&2; alert "The installer stopped. See the Terminal window or the log at:\n${LOG:-}"; exit "$status"' ERR

main "$@"
