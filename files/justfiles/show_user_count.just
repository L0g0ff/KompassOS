# Test this Just file: /usr/bin/just --justfile files/justfiles/show_user_count.just --choose

# Show weekly active KompassOS device count from Fedora countme data
[group('System')]
show-user-count:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    VARIANT_ID=$(grep '^VARIANT_ID=' /etc/os-release | cut -d= -f2)
    CSV_URL="https://data-analysis.fedoraproject.org/csv-reports/countme/totals.csv"
    TMP=$(mktemp /tmp/countme.XXXXXX.csv)
    trap 'rm -f "$TMP"' EXIT

    echo "${blue}Downloading Fedora countme data...${normal}"
    curl -sf -o "$TMP" "$CSV_URL"

    awk -F, -v variant="$VARIANT_ID" '
        NR == 1 { next }
        $6 == variant {
            if ($1 > latest_week) latest_week = $1
            weeks[$1] += $3
        }
        END {
            if (latest_week == "") {
                print "No data found for variant: " variant
                exit 1
            }
            printf "Active devices (week of %s): %d\n", latest_week, weeks[latest_week]
        }
    ' "$TMP"
