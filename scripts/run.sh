#!/usr/bin/env bash
# Build the app for the iOS simulator on this machine, then install and launch it on one or more
# simulators, either here or on another Mac over ssh.
#
#   scripts/run.sh                    build here, pick simulator(s) here
#   RUN_HOST=me@laptop scripts/run.sh build here, rsync the .app to the laptop, pick + launch there
#   SIM="iPhone 17 Pro" scripts/run.sh  skip the picker, launch on the named (or UDID) simulator
#
# The picker is an arrow-key multi-select: ↑↓ move, space toggle, enter confirm. It preselects
# booted simulators and whatever was picked last time (cached in .build/sim-selection.txt).
# Remote mode needs passwordless ssh, Xcode and rsync 3.x (brew) on both ends.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$PROJECT_DIR/Ubiquiti Assignment.xcodeproj"
SCHEME="Ubiquiti Assignment"
CONFIGURATION="${CONFIGURATION:-Debug}"
BUILD_DIR="$PROJECT_DIR/.build"
DERIVED_DATA="$BUILD_DIR/DerivedData"
APP_PATH="$DERIVED_DATA/Build/Products/$CONFIGURATION-iphonesimulator/$SCHEME.app"
SELECTION_CACHE="$BUILD_DIR/sim-selection.txt"
RUN_HOST="${RUN_HOST:-}"
REMOTE_APP_DIR="/tmp/ubiquiti-run"
RSYNC="${RSYNC:-/opt/homebrew/bin/rsync}"

# --- ssh plumbing: one multiplexed connection shared by every remote call ---------------------
SSH_OPTS=()
if [[ -n "$RUN_HOST" ]]; then
    mkdir -p "$HOME/.cache/ubiquiti-ssh"
    SSH_OPTS=(-o ControlMaster=auto -o "ControlPath=$HOME/.cache/ubiquiti-ssh/%C" -o ControlPersist=5m
              -o BatchMode=yes -o ConnectTimeout=10)
    ssh "${SSH_OPTS[@]}" "$RUN_HOST" true 2>/dev/null \
        || { echo "ERROR: cannot ssh to '$RUN_HOST' (needs passwordless auth)."; exit 1; }
fi
# Args are shell-quoted for the remote side so paths with spaces survive the hop.
remote() { ssh "${SSH_OPTS[@]}" "$RUN_HOST" "$(printf "%q " "$@")"; }
# simctl runs where the simulators are: remote when RUN_HOST is set, otherwise here.
sim()    { if [[ -n "$RUN_HOST" ]]; then remote xcrun simctl "$@"; else xcrun simctl "$@"; fi; }
where()  { echo "${RUN_HOST:-this machine}"; }

# --- 1. build ---------------------------------------------------------------------------------
echo "==> Building $SCHEME ($CONFIGURATION, simulator) on this machine..."
xcodebuild build \
    -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIGURATION" \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED_DATA" \
    -quiet 2>&1 | grep -E "error:|warning:" || true
[[ -d "$APP_PATH" ]] || { echo "ERROR: build failed, no app at $APP_PATH"; exit 1; }
BUNDLE_ID=$(defaults read "$APP_PATH/Info" CFBundleIdentifier)

# --- 2. ship ----------------------------------------------------------------------------------
if [[ -n "$RUN_HOST" ]]; then
    echo "==> Syncing .app to $RUN_HOST:$REMOTE_APP_DIR ..."
    remote mkdir -p "$REMOTE_APP_DIR"
    "$RSYNC" -a -s --delete --checksum --rsync-path="$RSYNC" -e "ssh ${SSH_OPTS[*]}" \
        "$APP_PATH/" "$RUN_HOST:$REMOTE_APP_DIR/$SCHEME.app/"
    INSTALL_PATH="$REMOTE_APP_DIR/$SCHEME.app"
else
    INSTALL_PATH="$APP_PATH"
fi

# --- 3. pick simulator(s) ---------------------------------------------------------------------
# One line per available iPhone/iPad: udid <tab> name <tab> state <tab> label
DEVICES=$(sim list devices available --json | python3 -c '
import json, sys
data = json.load(sys.stdin)["devices"]
for runtime, devs in sorted(data.items(), reverse=True):
    ver = runtime.rsplit(".", 1)[-1].replace("-", " ", 1).replace("-", ".")
    for d in devs:
        if not d["name"].startswith(("iPhone", "iPad")):
            continue
        udid, name, state = d["udid"], d["name"], d["state"]
        booted = " [Booted]" if state == "Booted" else ""
        print(f"{udid}\t{name}\t{state}\t{name} ({ver}){booted}")
')
[[ -n "$DEVICES" ]] || { echo "ERROR: no iPhone/iPad simulators on $(where)."; exit 1; }

IDS=(); NAMES=(); LABELS=(); PRESELECT=()
CACHED=$(cat "$SELECTION_CACHE" 2>/dev/null || true)
while IFS=$'\t' read -r udid name state label; do
    IDS+=("$udid"); NAMES+=("$name"); LABELS+=("$label")
    if [[ "$state" == "Booted" || "$CACHED" == *"$udid"* ]]; then PRESELECT+=(1); else PRESELECT+=(0); fi
done <<< "$DEVICES"

PICKED=()
if [[ -n "${SIM:-}" ]]; then
    for i in "${!IDS[@]}"; do
        [[ "${IDS[$i]}" == "$SIM" || "${NAMES[$i]}" == "$SIM" ]] && { PICKED=("$i"); break; }
    done
    [[ ${#PICKED[@]} -gt 0 ]] || { echo "ERROR: no simulator '$SIM' on $(where)."; exit 1; }
else
    echo "==> Select simulator(s) on $(where) [↑↓ move, space toggle, enter confirm]:"
    cursor=0
    draw() {
        for i in "${!LABELS[@]}"; do
            local mark="[ ]"; [[ "${PRESELECT[$i]}" == 1 ]] && mark="[x]"
            if (( i == cursor )); then printf "\r\033[K\033[7m  > %s %s\033[0m\n" "$mark" "${LABELS[$i]}"
            else printf "\r\033[K    %s %s\n" "$mark" "${LABELS[$i]}"; fi
        done
    }
    tput civis 2>/dev/null || true; trap 'tput cnorm 2>/dev/null || true' EXIT
    draw
    while IFS= read -rsn1 key; do
        case "$key" in
            $'\x1b') IFS= read -rsn2 seq
                     [[ "$seq" == '[A' && cursor -gt 0 ]] && cursor=$((cursor - 1))
                     [[ "$seq" == '[B' && cursor -lt ${#IDS[@]}-1 ]] && cursor=$((cursor + 1)) ;;
            ' ')     PRESELECT[$cursor]=$(( 1 - PRESELECT[cursor] )) ;;
            '')      break ;;
        esac
        printf "\033[%dA" "${#LABELS[@]}"; draw
    done
    tput cnorm 2>/dev/null || true
    for i in "${!IDS[@]}"; do [[ "${PRESELECT[$i]}" == 1 ]] && PICKED+=("$i"); done
    [[ ${#PICKED[@]} -gt 0 ]] || PICKED=("$cursor")
fi
mkdir -p "$BUILD_DIR"; : > "$SELECTION_CACHE"
for i in "${PICKED[@]}"; do echo "${IDS[$i]}" >> "$SELECTION_CACHE"; done

# --- 4. boot, install, launch -----------------------------------------------------------------
for i in "${PICKED[@]}"; do
    udid="${IDS[$i]}"; name="${NAMES[$i]}"
    echo "==> $name: booting, installing, launching $BUNDLE_ID"
    sim boot "$udid" >/dev/null 2>&1 || true
    sim install "$udid" "$INSTALL_PATH"
    sim launch --terminate-running-process "$udid" "$BUNDLE_ID" >/dev/null
done
# Bring the simulator window forward. Xcode 26 ships Simulator.app, Xcode 27 replaced it with DeviceHub.
show_simulator() { open -a Simulator 2>/dev/null || open -a DeviceHub 2>/dev/null || true; }
if [[ -n "$RUN_HOST" ]]; then remote bash -c "$(declare -f show_simulator); show_simulator"; else show_simulator; fi
