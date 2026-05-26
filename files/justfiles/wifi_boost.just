# Test this Just file: /usr/bin/just --justfile files/justfiles/wifi_boost.just --choose

# Temporarily boost WiFi transmit power beyond regulatory limits
[group('Network')]
wifi-boost-on:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    echo "${yellow}WiFi Power Boost${normal}"
    echo ""
    echo "${red}⚠  WARNING: This sets the regulatory domain to Bolivia (BO) to bypass"
    echo "   the default transmit power limits of your country."
    echo "   Using elevated WiFi transmit power may be illegal in your country.${normal}"
    echo ""

    if ! $(gum confirm "I understand this may be illegal in my country. Proceed?"); then
        exit 0
    fi

    echo ""

    # Detect WiFi interface
    mapfile -t IFACES < <(iw dev | awk '/Interface/ {print $2}')
    COUNT=${#IFACES[@]}
    if [ "$COUNT" -eq 0 ]; then
        echo "${red}No WiFi adapter found.${normal}"; exit 1
    elif [ "$COUNT" -gt 1 ]; then
        IFACE=$(printf '%s\n' "${IFACES[@]}" | gum choose --header "Select WiFi adapter:")
    else
        IFACE="${IFACES[0]}"
    fi

    PHY=$(iw dev "$IFACE" info | awk '/wiphy/ {print "phy" $2}')
    PHY_SECTION="phy#${PHY#phy}"
    echo "Adapter: ${blue}${IFACE}${normal} (${PHY})"
    echo ""

    # Snapshot before
    BEFORE_POWER=$(iw dev "$IFACE" info | awk '/txpower/ {print $2, $3}')
    BEFORE_REG=$(iw reg get | awk "/^${PHY_SECTION}$/{f=1;next} /^(phy#|global)/{f=0} f && /^country /{gsub(/:/, \"\", \$2); print \$2; exit}")
    [ -z "$BEFORE_REG" ] && BEFORE_REG=$(iw reg get | awk '/^global$/{f=1;next} /^phy#/{f=0} f && /^country /{gsub(/:/, "", $2); print $2; exit}')
    BEFORE_REG="${BEFORE_REG:-unknown}"

    # Save for restore
    echo "$BEFORE_REG" | sudo tee /tmp/wifi-boost-orig-reg > /dev/null
    echo "$IFACE"      | sudo tee /tmp/wifi-boost-iface    > /dev/null
    echo "$PHY"        | sudo tee /tmp/wifi-boost-orig-phy > /dev/null

    # Regulatory + txpower changes only take full effect at interface up/reconnect
    echo "${blue}Setting regulatory domain to BO (Bolivia)...${normal}"
    sudo iw reg set BO

    echo "${blue}Bringing interface down...${normal}"
    sudo ip link set "$IFACE" down

    echo "${blue}Setting txpower to maximum (30 dBm)...${normal}"
    sudo iw dev "$IFACE" set txpower fixed 3000

    echo "${blue}Bringing interface back up...${normal}"
    sudo ip link set "$IFACE" up
    sleep 1

    echo "${blue}Disabling power saving...${normal}"
    sudo iw dev "$IFACE" set power_save off

    echo ""

    # Snapshot after
    AFTER_POWER=$(iw dev "$IFACE" info | awk '/txpower/ {print $2, $3}')
    AFTER_REG=$(iw reg get | awk "/^${PHY_SECTION}$/{f=1;next} /^(phy#|global)/{f=0} f && /^country /{gsub(/:/, \"\", \$2); print \$2; exit}")
    [ -z "$AFTER_REG" ] && AFTER_REG=$(iw reg get | awk '/^global$/{f=1;next} /^phy#/{f=0} f && /^country /{gsub(/:/, "", $2); print $2; exit}')
    AFTER_REG="${AFTER_REG:-unknown}"
    POWER_SAVE=$(iw dev "$IFACE" get power_save 2>/dev/null | awk '{print $NF}' || echo "unknown")

    echo "${green}✓ Boost applied${normal}"
    echo ""

    # Reg domain: show before → after
    if [ "$BEFORE_REG" != "$AFTER_REG" ]; then
        echo "  Reg domain:  ${blue}${BEFORE_REG}${normal} → ${green}${AFTER_REG}${normal}"
    else
        echo "  Reg domain:  ${blue}${AFTER_REG}${normal} (unchanged)"
    fi

    # TX power: show before → after
    if [ "$BEFORE_POWER" != "$AFTER_POWER" ]; then
        echo "  TX power:    ${blue}${BEFORE_POWER}${normal} → ${green}${AFTER_POWER}${normal}"
    else
        echo "  TX power:    ${blue}${AFTER_POWER}${normal} (unchanged)"
    fi

    echo "  Power save:  ${green}${POWER_SAVE}${normal}"
    echo ""
    echo "Run ${yellow}just wifi-boost-off${normal} to restore defaults."

# Restore WiFi adapter to default power settings
[group('Network')]
wifi-boost-off:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    echo "${yellow}WiFi Power Boost — Restore${normal}"
    echo ""

    # Use saved interface or detect
    if [ -f /tmp/wifi-boost-iface ]; then
        IFACE=$(cat /tmp/wifi-boost-iface)
        PHY=$(cat /tmp/wifi-boost-orig-phy 2>/dev/null || iw dev "$IFACE" info | awk '/wiphy/ {print "phy" $2}')
    else
        mapfile -t IFACES < <(iw dev | awk '/Interface/ {print $2}')
        COUNT=${#IFACES[@]}
        if [ "$COUNT" -eq 0 ]; then
            echo "${red}No WiFi adapter found.${normal}"; exit 1
        elif [ "$COUNT" -gt 1 ]; then
            IFACE=$(printf '%s\n' "${IFACES[@]}" | gum choose --header "Select WiFi adapter:")
        else
            IFACE="${IFACES[0]}"
        fi
        PHY=$(iw dev "$IFACE" info | awk '/wiphy/ {print "phy" $2}')
    fi

    echo "Adapter: ${blue}${IFACE}${normal} (${PHY})"
    echo ""

    # Restore regulatory domain — fall back to world (00) if saved value is not a valid 2-letter code
    ORIG_REG=$(cat /tmp/wifi-boost-orig-reg 2>/dev/null || echo "00")
    if ! echo "$ORIG_REG" | grep -qE '^[A-Z]{2}$'; then
        ORIG_REG="00"
    fi
    echo "${blue}Restoring regulatory domain (${ORIG_REG})...${normal}"
    sudo iw reg set "$ORIG_REG"

    echo "${blue}Bringing interface down...${normal}"
    sudo ip link set "$IFACE" down

    echo "${blue}Restoring txpower to auto...${normal}"
    sudo iw dev "$IFACE" set txpower auto

    echo "${blue}Bringing interface back up...${normal}"
    sudo ip link set "$IFACE" up
    sleep 1

    echo "${blue}Re-enabling power saving...${normal}"
    sudo iw dev "$IFACE" set power_save on

    sudo rm -f /tmp/wifi-boost-orig-reg /tmp/wifi-boost-iface /tmp/wifi-boost-orig-phy

    echo ""
    echo "${green}✓ WiFi power restored to defaults.${normal}"

# Show current WiFi power and regulatory status
[group('Network')]
wifi-boost-status:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh

    echo "${bold}WiFi Power Status${normal}"
    echo ""

    mapfile -t IFACES < <(iw dev | awk '/Interface/ {print $2}')
    COUNT=${#IFACES[@]}
    if [ "$COUNT" -eq 0 ]; then
        echo "${red}No WiFi adapter found.${normal}"; exit 1
    elif [ "$COUNT" -gt 1 ]; then
        IFACE=$(printf '%s\n' "${IFACES[@]}" | gum choose --header "Select WiFi adapter:")
    else
        IFACE="${IFACES[0]}"
    fi

    PHY=$(iw dev "$IFACE" info | awk '/wiphy/ {print "phy" $2}')
    PHY_SECTION="phy#${PHY#phy}"
    CURRENT_POWER=$(iw dev "$IFACE" info | awk '/txpower/ {print $2, $3}')
    POWER_SAVE=$(iw dev "$IFACE" get power_save 2>/dev/null | awk '{print $NF}' || echo "unknown")
    REG=$(iw reg get | awk "/^${PHY_SECTION}$/{f=1;next} /^(phy#|global)/{f=0} f && /^country /{gsub(/:/, \"\", \$2); print \$2; exit}")
    [ -z "$REG" ] && REG=$(iw reg get | awk '/^global$/{f=1;next} /^phy#/{f=0} f && /^country /{gsub(/:/, "", $2); print $2; exit}')
    REG="${REG:-unknown}"

    if [ -f /tmp/wifi-boost-iface ]; then
        BOOST_STATUS="${green}active${normal}"
    else
        BOOST_STATUS="${yellow}inactive${normal}"
    fi

    echo "  Adapter:     ${blue}${IFACE}${normal} (${PHY})"
    echo "  TX power:    ${blue}${CURRENT_POWER}${normal}"
    echo "  Power save:  ${blue}${POWER_SAVE}${normal}"
    echo "  Reg domain:  ${blue}${REG}${normal}"
    echo "  Boost:       ${BOOST_STATUS}"
