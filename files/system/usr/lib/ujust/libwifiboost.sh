# Shared helpers for wifi_boost.just — avoids repeating the same
# interface-detection and regulatory-domain parsing in each recipe.

# Print the WiFi interface to use, prompting if there's more than one.
wifi_pick_iface() {
    mapfile -t ifaces < <(iw dev | awk '/Interface/ {print $2}')
    local count=${#ifaces[@]}
    if [ "$count" -eq 0 ]; then
        echo "${red}No WiFi adapter found.${normal}" >&2
        return 1
    elif [ "$count" -gt 1 ]; then
        printf '%s\n' "${ifaces[@]}" | gum choose --header "Select WiFi adapter:"
    else
        echo "${ifaces[0]}"
    fi
}

# Print the phy name (e.g. "phy0") for a given interface.
wifi_get_phy() {
    iw dev "$1" info | awk '/wiphy/ {print "phy" $2}'
}

# Print the regulatory domain for a phy, falling back to the global one.
wifi_get_regdomain() {
    local phy_section="phy#${1#phy}"
    local reg
    reg=$(iw reg get | awk "/^${phy_section}\$/{f=1;next} /^(phy#|global)/{f=0} f && /^country /{gsub(/:/, \"\", \$2); print \$2; exit}")
    if [ -z "$reg" ]; then
        reg=$(iw reg get | awk '/^global$/{f=1;next} /^phy#/{f=0} f && /^country /{gsub(/:/, "", $2); print $2; exit}')
    fi
    echo "${reg:-unknown}"
}
