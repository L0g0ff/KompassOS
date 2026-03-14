# Test this Just file: /usr/bin/just --justfile files/justfiles/activate_webcam.just --choose
# Justfile for KompassOS webcam support (Issue #59)

# Enable FOSS IPU6 webcam (Dell XPS/Latitude/Precision)
[group('Hardware')]
enable-webcam:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    echo "${yellow}KompassOS Webcam Fix (Issue #59)${normal}"
    echo "- Enables FOSS libcamera stack for Intel IPU6 MIPI cameras"
    echo "- Configures WirePlumber, Firefox and Chrome"
    echo "- USB webcams remain functional"
    echo "- Known issue: image may be upside down (upstream kernel bug)"
    echo ""
    echo "Run 'just disable-webcam' to rollback"
    echo ""

    if $(gum confirm "Enable FOSS webcam support?"); then
        # WirePlumber: enable libcamera, disable only IPU6 V4L2 nodes
        echo "${blue}Configuring WirePlumber...${normal}"
        mkdir -p ~/.config/wireplumber/wireplumber.conf.d/
        printf '%s\n' \
            'wireplumber.profiles = {' \
            '  main = {' \
            '    monitor.libcamera = required' \
            '    monitor.v4l2 = required' \
            '  }' \
            '}' \
            '' \
            'monitor.v4l2.rules = [' \
            '  {' \
            '    matches = [' \
            '      { api.v4l2.cap.card = "ipu6" }' \
            '    ]' \
            '    actions = {' \
            '      update-props = {' \
            '        device.disabled = true' \
            '      }' \
            '    }' \
            '  }' \
            ']' \
            > ~/.config/wireplumber/wireplumber.conf.d/50-libcamera.conf

        # Firefox: enable PipeWire camera
        echo "${blue}Configuring Firefox...${normal}"
        PROFILES_DIR="$HOME/.mozilla/firefox"
        if [ -d "$PROFILES_DIR" ]; then
            for profile in "$PROFILES_DIR"/*.default* "$PROFILES_DIR"/*.default-release*; do
                if [ -d "$profile" ]; then
                    if ! grep -q 'media.webrtc.camera.allow-pipewire' "$profile/user.js" 2>/dev/null; then
                        echo 'user_pref("media.webrtc.camera.allow-pipewire", true);' >> "$profile/user.js"
                    fi
                fi
            done
        else
            echo "${yellow}Firefox profile not found. Set manually:${normal}"
            echo "about:config → media.webrtc.camera.allow-pipewire → true"
        fi

        # Chrome: enable PipeWire camera (append if not present)
        echo "${blue}Configuring Chrome...${normal}"
        sudo mkdir -p /etc/opt/chrome/
        sudo touch /etc/opt/chrome/chrome-flags.conf
        if ! grep -q 'WebRTCPipeWireCamera' /etc/opt/chrome/chrome-flags.conf 2>/dev/null; then
            echo '--enable-features=WebRTCPipeWireCamera' | sudo tee -a /etc/opt/chrome/chrome-flags.conf > /dev/null
        fi

        # Restart WirePlumber
        echo "${blue}Restarting WirePlumber...${normal}"
        systemctl --user restart wireplumber

        echo ""
        echo "${green}Webcam enabled!${normal}"
        echo "Restart Firefox and Chrome, then test:"
        echo "  firefox https://mozilla.github.io/webrtc-landing/gum_test.html"
    fi

# Disable FOSS IPU6 webcam (rollback)
[group('Hardware')]
disable-webcam:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    echo "${yellow}KompassOS Webcam Fix — Rollback${normal}"
    echo ""

    if $(gum confirm "Disable FOSS webcam and restore defaults?"); then
        # Remove WirePlumber config
        echo "${blue}Removing WirePlumber config...${normal}"
        rm -f ~/.config/wireplumber/wireplumber.conf.d/50-libcamera.conf

        # Remove Firefox user.js entry
        echo "${blue}Cleaning Firefox config...${normal}"
        PROFILES_DIR="$HOME/.mozilla/firefox"
        if [ -d "$PROFILES_DIR" ]; then
            for profile in "$PROFILES_DIR"/*.default* "$PROFILES_DIR"/*.default-release*; do
                if [ -f "$profile/user.js" ]; then
                    sed -i '/media.webrtc.camera.allow-pipewire/d' "$profile/user.js"
                fi
            done
        fi

        # Remove only our Chrome flag line
        echo "${blue}Cleaning Chrome config...${normal}"
        if [ -f /etc/opt/chrome/chrome-flags.conf ]; then
            sudo sed -i '/WebRTCPipeWireCamera/d' /etc/opt/chrome/chrome-flags.conf
        fi

        # Restart WirePlumber
        echo "${blue}Restarting WirePlumber...${normal}"
        systemctl --user restart wireplumber

        echo ""
        echo "${green}Rollback complete!${normal}"
        echo "Restart Firefox and Chrome to take effect."
    fi

# Check webcam status
[group('Hardware')]
check-webcam:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    echo "${blue}KompassOS Webcam Diagnostics${normal}"
    echo ""
    echo "Kernel:  $(uname -r)"
    echo "Sensor:  $(ls /sys/bus/i2c/devices/ 2>/dev/null | grep -E 'OV|HIM|INT' || echo 'none found')"
    echo "Modules: $(lsmod | grep -oE 'ov02c10|ov01a10|intel_ipu6_isys' | tr '\n' ' ' || echo 'none')"
    echo ""
    echo "libcamera:"
    cam --list 2>&1 | grep -E "Available|camera" || echo "  not detected"
    echo ""
    echo "WirePlumber video:"
    wpctl status 2>/dev/null | grep -E "libcamera|Front Camera|ov02c10" || echo "  no libcamera device"
    echo ""
    echo "Config:"
    echo "  WirePlumber: $([ -f ~/.config/wireplumber/wireplumber.conf.d/50-libcamera.conf ] && echo 'applied' || echo 'not applied')"
    echo "  Chrome:      $(grep -q 'WebRTCPipeWireCamera' /etc/opt/chrome/chrome-flags.conf 2>/dev/null && echo 'applied' || echo 'not applied')"
