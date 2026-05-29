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

        # Nvidia: force Mesa EGL for libcamera GPU debayering.
        # Without this, libcamera picks the Nvidia EGL provider which fails
        # with GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT and produces no frames.
        echo ""
        if $(gum confirm --default=false "Are you on an Nvidia GPU system? (Apply Mesa EGL fix for WirePlumber)"); then
            echo "${blue}Applying Nvidia Mesa EGL fix...${normal}"
            mkdir -p ~/.config/systemd/user/wireplumber.service.d/
            printf '[Service]\nEnvironment=__EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json\n' \
                > ~/.config/systemd/user/wireplumber.service.d/50-libcamera-egl.conf
            systemctl --user daemon-reload
        fi

        # Restart WirePlumber
        echo "${blue}Restarting WirePlumber...${normal}"
        systemctl --user restart wireplumber

        echo ""
        echo "${green}WirePlumber configured!${normal}"
        echo ""
        echo "${yellow}Now enable PipeWire camera in your browser:${normal}"
        echo ""
        echo "  Firefox:"
        echo "    1. Open about:config"
        echo "    2. Search: media.webrtc.camera.allow-pipewire"
        echo "    3. Set to: true"
        echo "    4. Restart Firefox"
        echo ""
        echo "  Chrome:"
        echo "    1. Open chrome://flags/#enable-webrtc-pipewire-camera"
        echo "    2. Set to: Enabled"
        echo "    3. Relaunch Chrome"
        echo ""
        echo "  Teams for Linux (Flatpak):"
        echo "    Edit ~/.var/app/com.github.IsmaelMartinez.teams_for_linux/config/teams-for-linux/config.json"
        echo '    Add: { "electronCLIFlags": [["enable-features", "WebRtcPipeWireCamera"]] }'
        echo "    Restart Teams for Linux"
        echo ""
        echo "Test: firefox https://mozilla.github.io/webrtc-landing/gum_test.html"
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
        rm -f ~/.config/systemd/user/wireplumber.service.d/50-libcamera-egl.conf
        systemctl --user daemon-reload

        # Restart WirePlumber
        echo "${blue}Restarting WirePlumber...${normal}"
        systemctl --user restart wireplumber

        echo ""
        echo "${green}WirePlumber restored!${normal}"
        echo ""
        echo "${yellow}Don't forget to revert browser settings manually:${normal}"
        echo ""
        echo "  Firefox:"
        echo "    about:config → media.webrtc.camera.allow-pipewire → false"
        echo ""
        echo "  Chrome:"
        echo "    chrome://flags/#enable-webrtc-pipewire-camera → Default"
        echo ""
        echo "  Teams for Linux (Flatpak):"
        echo "    Remove the WebRtcPipeWireCamera entry from:"
        echo "    ~/.var/app/com.github.IsmaelMartinez.teams_for_linux/config/teams-for-linux/config.json"
        echo "    Restart Teams for Linux"
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
    echo "  WirePlumber:    $([ -f ~/.config/wireplumber/wireplumber.conf.d/50-libcamera.conf ] && echo 'applied' || echo 'not applied')"
    echo "  Nvidia EGL fix: $([ -f ~/.config/systemd/user/wireplumber.service.d/50-libcamera-egl.conf ] && echo 'applied' || echo 'not applied')"
    echo "  Firefox:        about:config → media.webrtc.camera.allow-pipewire (set manually)"
    echo "  Chrome:         chrome://flags/#enable-webrtc-pipewire-camera (set manually)"
