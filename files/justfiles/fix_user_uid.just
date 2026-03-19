# Test this Just file: /usr/bin/just --justfile files/justfiles/fix_user_uid.just --choose
# Justfile for KompassOS UID fix — corrects UID/GID to 1000 after Anaconda install

# Fix user UID/GID to 1000 (Anaconda may assign 801 on ostree-based installs)
[group('System')]
fix-uid:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    username=$(whoami)
    new_uid=1000

    echo "${yellow}KompassOS UID Fix${normal}"
    echo ""

    if getent passwd $new_uid > /dev/null 2>&1; then
        existing=$(getent passwd $new_uid | cut -d: -f1)
        echo "${red}UID $new_uid is already in use by '$existing', aborting.${normal}"
        exit 1
    fi

    current_uid=$(id -u $username)
    if [ "$current_uid" -eq "$new_uid" ]; then
        echo "${green}$username already has UID $new_uid, nothing to do.${normal}"
        exit 0
    fi

    echo "Current UID of ${blue}$username${normal}: ${red}$current_uid${normal}"
    echo ""
    echo "A one-time service will be created to apply the fix on next boot."
    echo ""
    echo "  ${blue}usermod -u $new_uid $username && groupmod -g $new_uid $username${normal}"
    echo ""

    if $(gum confirm "Schedule fix and reboot?"); then
        {
            echo '[Unit]'
            echo 'Description=Fix user UID/GID to 1000 (one-time)'
            echo 'After=local-fs.target'
            echo 'Before=display-manager.service'
            echo ''
            echo '[Service]'
            echo 'Type=oneshot'
            echo "ExecStart=/bin/bash -c 'usermod -u $new_uid $username && groupmod -g $new_uid $username'"
            echo 'ExecStartPost=/bin/systemctl disable fix-uid-once.service'
            echo 'ExecStartPost=/bin/rm /etc/systemd/system/fix-uid-once.service'
            echo ''
            echo '[Install]'
            echo 'WantedBy=multi-user.target'
        } | sudo tee /etc/systemd/system/fix-uid-once.service > /dev/null

        sudo systemctl enable fix-uid-once.service
        echo ""
        echo "${green}Fix scheduled for next boot.${normal}"
        echo ""

        if $(gum confirm "Reboot now?"); then
            sudo systemctl reboot
        else
            echo "${yellow}Reboot manually when ready to apply the fix.${normal}"
        fi
    fi
