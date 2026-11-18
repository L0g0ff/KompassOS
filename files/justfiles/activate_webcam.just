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
    echo "  HM1092 fix:     $([ -f /etc/modprobe.d/kompassos-ipu-bridge-hm1092.conf ] && echo 'enabled' || echo 'not enabled') (see 'just enable-webcam-hm1092-fix')"
    # The patched module is built out-of-tree, so it carries the O taint flag.
    echo "  Patched module: $(grep -q O /sys/module/ipu_bridge/taint 2>/dev/null && echo 'loaded' || echo 'not loaded (stock ipu_bridge or none)')"

# Fix IPU6 webcam on kernel 7.3+ when an HM1092 IR sensor is present (issue #117)
[group('Hardware')]
enable-webcam-hm1092-fix:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    MOD="/usr/lib/modules/$(uname -r)/kompassos/ipu-bridge.ko.kompassos"
    CERT=/usr/share/kompassos/mok/kompassos-mok.der
    CONF=/etc/modprobe.d/kompassos-ipu-bridge-hm1092.conf

    echo "${yellow}KompassOS Webcam Fix - HM1092 IR sensor (Issue #117)${normal}"
    echo "- Kernel 7.3+ lists the Windows Hello IR sensor (HM1092) in ipu-bridge"
    echo "  without having a driver for it, so the IPU6 webcam never shows up"
    echo "- Loads a KompassOS-built ipu-bridge without that entry"
    echo "- Falls back to the stock module if the patched one cannot be loaded"
    echo ""

    if ! ls /sys/bus/acpi/devices/ 2>/dev/null | grep -q '^HIMX1092:'; then
        echo "${green}No HM1092 IR sensor found; this fix is not needed on this device.${normal}"
        exit 0
    fi
    if [ ! -f "$MOD" ]; then
        echo "${red}No patched module for kernel $(uname -r) in this image.${normal}"
        echo "Either this kernel no longer needs the fix, or the image was built without it."
        exit 1
    fi

    if ! $(gum confirm "Enable the HM1092 webcam fix?"); then
        exit 0
    fi

    # With Secure Boot on, the module only loads once the KompassOS key is enrolled.
    NEED_REBOOT_ENROLL=false
    if mokutil --sb-state 2>/dev/null | grep -q 'SecureBoot enabled'; then
        if mokutil --test-key "$CERT" 2>/dev/null | grep -q 'is already enrolled'; then
            echo "${green}KompassOS signing key already enrolled.${normal}"
        else
            echo "${blue}Enrolling the KompassOS module signing key...${normal}"
            echo "Choose a one-time password. You need it once at the next boot."
            sudo mokutil --import "$CERT"
            NEED_REBOOT_ENROLL=true
        fi
    fi

    echo "${blue}Installing modprobe rule...${normal}"
    printf '%s\n' \
        '# KompassOS: ipu-bridge without the HIMX1092 entry (issue #117).' \
        '# Falls back to the stock module if the patched one is missing or rejected.' \
        'install ipu_bridge /usr/sbin/insmod /usr/lib/modules/$(uname -r)/kompassos/ipu-bridge.ko.kompassos $CMDLINE_OPTS 2>/dev/null || /usr/sbin/modprobe --ignore-install ipu_bridge $CMDLINE_OPTS' \
        | sudo tee "$CONF" >/dev/null

    echo ""
    echo "${green}Done. Reboot to activate.${normal}"
    if $NEED_REBOOT_ENROLL; then
        echo ""
        echo "${yellow}At the next boot a blue MOK Manager screen appears:${normal}"
        echo "  Enroll MOK -> Continue -> Yes -> enter the password -> Reboot"
    fi
    echo ""
    echo "After the reboot, check with: just check-webcam"
    echo "Expected in 'journalctl -k -b | grep -i connected': Connected 1 cameras"

# Disable the HM1092 webcam fix (rollback)
[group('Hardware')]
disable-webcam-hm1092-fix:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    CERT=/usr/share/kompassos/mok/kompassos-mok.der
    CONF=/etc/modprobe.d/kompassos-ipu-bridge-hm1092.conf

    if [ -f "$CONF" ]; then
        echo "${blue}Removing modprobe rule...${normal}"
        sudo rm -f "$CONF"
    else
        echo "HM1092 fix is not enabled."
    fi

    if mokutil --test-key "$CERT" 2>/dev/null | grep -q 'is already enrolled'; then
        if $(gum confirm --default=false "Also remove the KompassOS signing key from MOK?"); then
            echo "Choose a one-time password. You need it once at the next boot."
            sudo mokutil --delete "$CERT"
        fi
    fi

    echo ""
    echo "${green}Done. Reboot to load the stock ipu-bridge module again.${normal}"
