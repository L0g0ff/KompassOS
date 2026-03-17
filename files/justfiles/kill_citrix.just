# Test this Just file: /usr/bin/just --justfile files/justfiles/kill_citrix.just --choose
# Justfile for KompassOS Citrix Workspace management

# Kill all running Citrix processes and services
[group('Applications')]
kill-citrix:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    echo "${yellow}Citrix Workspace stoppen${normal}"
    echo ""

    # Stop systemd user service
    if systemctl --user is-active --quiet 'app-receiver@*.service' 2>/dev/null; then
        echo "${blue}Stoppen van Citrix Workspace Launcher service...${normal}"
        systemctl --user stop 'app-receiver@*.service' 2>/dev/null || true
    fi

    # Kill remaining Citrix processes
    PROCS=$(pgrep -f 'ICAClient|icasessionmgr|UtilDaemon|wfica|selfservice|AuthManager' 2>/dev/null || true)
    if [ -n "$PROCS" ]; then
        echo "${blue}Afsluiten van Citrix processen...${normal}"
        pkill -TERM -f 'ICAClient|icasessionmgr|UtilDaemon|wfica|selfservice|AuthManager' 2>/dev/null || true
        sleep 2
        # Force kill if still running
        pkill -KILL -f 'ICAClient|icasessionmgr|UtilDaemon|wfica|selfservice|AuthManager' 2>/dev/null || true
    fi

    echo ""
    echo "${green}Citrix is gestopt.${normal}"
