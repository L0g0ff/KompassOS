# Test this Just file: /usr/bin/just --justfile files/justfiles/install_ipmi_tools.just --choose

# Install IPMI / server management toolbox in Distrobox
[group('Apps')]
install-ipmi-tools:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    echo "${green}Creating IPMI tools distrobox...${normal}"
    distrobox-assemble create --file /usr/share/kompassos/distrobox/ipmi-tools/ipmi-distrobox.ini --replace
    echo "${green}IPMI toolbox ready!${normal}"
    echo "Enter the box:        distrobox enter ipmi-tools"
    echo "Out-of-band example:  ipmitool -I lanplus -H <bmc-ip> -U <user> -P <pass> sensor"
    echo "Dell iDRAC example:   idracadm7 -r <idrac-ip> -u <user> -p <pass> getsysinfo"
    echo "                      (idracadm7 is the racadm tool for iDRAC 7/8/9)"
    echo "In-band needs the host modules: sudo modprobe ipmi_si ipmi_devintf"
    echo "Supermicro SUM: drop the SUM tarball in"
    echo "  /usr/share/kompassos/distrobox/ipmi-tools/ and re-run this recipe."

# Enter the IPMI tools distrobox
[group('Apps')]
enter-ipmi-tools:
    #!/usr/bin/env bash
    set -euo pipefail
    distrobox enter ipmi-tools

# Remove the IPMI tools distrobox
[group('Apps')]
remove-ipmi-tools:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    if $(gum confirm "Remove the IPMI tools distrobox?"); then
        distrobox stop ipmi-tools || true
        distrobox rm ipmi-tools || true
        echo "${green}IPMI tools distrobox removed.${normal}"
    fi
