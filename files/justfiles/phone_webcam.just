# Test this Just file: /usr/bin/just --justfile files/justfiles/phone_webcam.just --choose
# Justfile for using an Android phone camera as a virtual webcam (via scrcpy + v4l2loopback)

# Use an Android phone camera as webcam (scrcpy + v4l2loopback)
[group('Hardware')]
enable-phone-webcam:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/kompassos-phone-webcam"
    STATE_FILE="${STATE_DIR}/state"

    echo "${yellow}KompassOS Phone Webcam${normal}"
    echo "- Streams your phone camera to a virtual webcam (/dev/videoN)"
    echo "- Works with any app that uses PipeWire or V4L2 (Teams, Zoom, Firefox, OBS)"
    echo "- ${bold}Android only${normal} - iPhones are not supported (no ADB)"
    echo "- Video only: audio is not forwarded, use your laptop mic or headset"
    echo ""
    echo "Run 'just disable-phone-webcam' to stop and revert everything"
    echo ""
    echo "${bold}One-time phone setup:${normal}"
    echo "  1. Settings > About phone > tap 'Build number' 7 times (unlocks Developer options)"
    echo "  2. Settings > System > Developer options > enable 'USB debugging'"
    echo "  3. Connect the phone with a USB cable that supports data"
    echo "  4. Keep the phone unlocked during setup"
    echo ""

    # Check dependencies (offer to install missing ones via brew)
    if ! command -v adb >/dev/null; then
        echo "${yellow}adb is not installed.${normal}"
        if command -v brew >/dev/null && $(gum confirm "Install adb (android-platform-tools) via brew?"); then
            brew install android-platform-tools
        else
            echo "${red}adb is required${normal} - install it with: brew install android-platform-tools"
            exit 1
        fi
    fi
    if ! command -v scrcpy >/dev/null; then
        echo "${yellow}scrcpy is not installed.${normal}"
        if command -v brew >/dev/null && $(gum confirm "Install scrcpy via brew?"); then
            brew install scrcpy
        else
            echo "${red}scrcpy is required${normal} - install it with: brew install scrcpy"
            exit 1
        fi
    fi
    if ! modinfo v4l2loopback >/dev/null 2>&1 && ! ls /sys/devices/virtual/video4linux/ >/dev/null 2>&1; then
        echo "${red}v4l2loopback kernel module not available${normal}"
        exit 1
    fi

    if [ -f "$STATE_FILE" ]; then
        echo "${yellow}Phone webcam is already active.${normal}"
        echo "Run 'just disable-phone-webcam' first if you want to restart it."
        exit 0
    fi

    if ! $(gum confirm "Phone connected and USB debugging enabled?"); then
        exit 0
    fi

    # Wait for the phone to show up on ADB
    echo "${blue}Waiting for phone on ADB...${normal}"
    FOUND=0
    for _ in $(seq 1 30); do
        ADB_STATE=$(adb devices | sed -n '2p' | awk '{print $2}')
        case "${ADB_STATE:-absent}" in
            device)
                FOUND=1
                break
                ;;
            unauthorized)
                echo "Accept the 'Allow USB debugging?' popup on your phone..."
                ;;
            *)
                echo "Waiting for phone (check cable and USB debugging)..."
                ;;
        esac
        sleep 2
    done
    if [ "$FOUND" -ne 1 ]; then
        echo "${red}No authorized phone found after 60 seconds.${normal}"
        exit 1
    fi
    MODEL=$(adb shell getprop ro.product.model | tr -d '\r')
    echo "${green}Connected: ${MODEL}${normal}"
    echo ""

    # Read available cameras from the phone
    echo "${blue}Cameras on this phone:${normal}"
    scrcpy --list-cameras 2>/dev/null | grep -- '--camera-id' || true
    echo ""
    FACING=$(gum choose --header "Which camera do you want to use?" "front" "back")

    # Find an existing v4l2loopback device, or load the module ourselves
    MODULE_LOADED_BY_US=0
    LOOPBACK_DEV=""
    for d in /sys/devices/virtual/video4linux/*; do
        [ -e "$d" ] || continue
        LOOPBACK_DEV="/dev/$(basename "$d")"
        break
    done
    if [ -z "$LOOPBACK_DEV" ]; then
        echo "${blue}Loading v4l2loopback kernel module (needs sudo)...${normal}"
        sudo modprobe v4l2loopback exclusive_caps=1 card_label="Android Phone Camera"
        MODULE_LOADED_BY_US=1
        for d in /sys/devices/virtual/video4linux/*; do
            [ -e "$d" ] || continue
            LOOPBACK_DEV="/dev/$(basename "$d")"
            break
        done
    fi
    if [ -z "$LOOPBACK_DEV" ]; then
        echo "${red}Could not find or create a v4l2loopback device.${normal}"
        exit 1
    fi
    CARD_LABEL=$(cat "/sys/devices/virtual/video4linux/$(basename "$LOOPBACK_DEV")/name")
    echo "Using virtual webcam: ${LOOPBACK_DEV} (\"${CARD_LABEL}\")"

    # Start the camera stream in the background
    echo "${blue}Starting camera stream...${normal}"
    mkdir -p "$STATE_DIR"
    nohup scrcpy --video-source=camera "--camera-facing=${FACING}" \
        --max-size=1920 "--v4l2-sink=${LOOPBACK_DEV}" \
        --no-audio --no-window > "${STATE_DIR}/scrcpy.log" 2>&1 &
    SCRCPY_PID=$!
    sleep 4
    if ! kill -0 "$SCRCPY_PID" 2>/dev/null; then
        echo "${red}scrcpy failed to start:${normal}"
        tail -5 "${STATE_DIR}/scrcpy.log"
        exit 1
    fi

    # Restart WirePlumber so PipeWire (re)detects the now-active virtual camera.
    # With exclusive_caps the loopback device only advertises capture while a
    # producer is attached, so the node is often missing until a re-probe.
    echo "${blue}Restarting WirePlumber (brief audio interruption)...${normal}"
    systemctl --user restart wireplumber
    sleep 3

    printf 'SCRCPY_PID=%s\nLOOPBACK_DEV=%s\nMODULE_LOADED_BY_US=%s\n' \
        "$SCRCPY_PID" "$LOOPBACK_DEV" "$MODULE_LOADED_BY_US" > "$STATE_FILE"

    echo ""
    if wpctl status 2>/dev/null | grep -q "$CARD_LABEL"; then
        echo "${green}✓ Phone webcam is live!${normal}"
        echo ""
        echo "Select the camera \"${CARD_LABEL}\" in Teams/Zoom/Firefox/OBS."
        echo "It should now just work. If the app was already open, reopen its camera settings."
    else
        echo "${yellow}Stream is running, but PipeWire does not list the camera yet.${normal}"
        echo "Restart your video app, or check 'just check-phone-webcam' for diagnostics."
    fi
    echo ""
    echo "Stop and revert with: ${bold}just disable-phone-webcam${normal}"

# Stop the phone webcam and revert all changes
[group('Hardware')]
disable-phone-webcam:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/kompassos-phone-webcam"
    STATE_FILE="${STATE_DIR}/state"

    echo "${yellow}KompassOS Phone Webcam - Stop & revert${normal}"
    echo ""

    MODULE_LOADED_BY_US=0
    SCRCPY_PID=""
    [ -f "$STATE_FILE" ] && source "$STATE_FILE"

    # Stop the stream
    if [ -n "$SCRCPY_PID" ] && kill -0 "$SCRCPY_PID" 2>/dev/null; then
        echo "${blue}Stopping camera stream (pid ${SCRCPY_PID})...${normal}"
        kill "$SCRCPY_PID"
    else
        pkill -f 'scrcpy --video-source=camera' 2>/dev/null \
            && echo "${blue}Stopped a running camera stream.${normal}" \
            || echo "No camera stream was running."
    fi

    # Unload the module only if this script loaded it
    if [ "$MODULE_LOADED_BY_US" = "1" ]; then
        echo "${blue}Unloading v4l2loopback kernel module (needs sudo)...${normal}"
        sleep 1
        sudo modprobe -r v4l2loopback \
            || echo "${yellow}Module still in use - it will be gone after a reboot.${normal}"
    fi

    # Restart WirePlumber so the stale camera node disappears
    echo "${blue}Restarting WirePlumber (brief audio interruption)...${normal}"
    systemctl --user restart wireplumber

    rm -rf "$STATE_DIR"
    echo ""
    echo "${green}✓ Phone webcam stopped, all changes reverted.${normal}"
    echo "You can safely unplug your phone."

# Show phone webcam diagnostics
[group('Hardware')]
check-phone-webcam:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/kompassos-phone-webcam"

    echo "${blue}KompassOS Phone Webcam Diagnostics${normal}"
    echo ""
    echo "adb:        $(command -v adb >/dev/null && adb devices | sed -n '2p' | awk '{print $1" ("$2")"}' || echo 'not installed')"
    echo "scrcpy:     $(command -v scrcpy >/dev/null && scrcpy --version 2>/dev/null | head -1 || echo 'not installed')"
    echo "Stream:     $(pgrep -f 'scrcpy --video-source=camera' >/dev/null && echo 'running' || echo 'not running')"
    echo "State file: $([ -f "${STATE_DIR}/state" ] && cat "${STATE_DIR}/state" | tr '\n' ' ' || echo 'none')"
    echo ""
    echo "Virtual video devices (v4l2loopback):"
    for d in /sys/devices/virtual/video4linux/*; do
        [ -e "$d" ] || { echo "  none"; break; }
        echo "  /dev/$(basename "$d") - $(cat "$d/name")"
    done
    echo ""
    echo "PipeWire video sources (what your apps see):"
    wpctl status 2>/dev/null | sed -n '/^Video/,/^$/p' \
        | sed -n '/Sources:/,/Filters:\|Sinks:\|Streams:/p' \
        | grep -E '[0-9]+\.' || echo "  none"
