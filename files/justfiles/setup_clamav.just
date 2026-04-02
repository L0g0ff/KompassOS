# Test this Just file: /usr/bin/just --justfile files/justfiles/setup_clamav.just --choose

# Setup ClamAV antivirus scanner (pulls official image and updates virus definitions)
[group('Security')]
setup-clamav:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    echo "${yellow}ClamAV Antivirus Scanner${normal}"
    echo "- Uses the official ClamAV container image via Podman"
    echo "- Scans your home directory on demand"
    echo ""

    if $(gum confirm "Install ClamAV?"); then
        echo "${blue}Pulling ClamAV image...${normal}"
        podman pull clamav/clamav:stable

        echo "${blue}Updating virus definitions...${normal}"
        podman run --rm \
            -v clamav_db:/var/lib/clamav \
            clamav/clamav:stable freshclam

        echo ""
        echo "${green}ClamAV ready!${normal}"
        echo "Run ${blue}just scan-clamav${normal} to scan your system."
    fi

# Scan with ClamAV (choose scan type)
[group('Security')]
scan-clamav:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    choice=$(gum choose \
        "Quick scan (/home, skips cache/containers/node_modules)" \
        "Full home scan (/home)" \
        "Full system scan (/)" \
        "Custom path")

    case "$choice" in
        "Quick scan (/home, skips cache/containers/node_modules)")
            mount_src="/home"
            extra_args=(
                --exclude-dir='/\.cache$'
                --exclude-dir='/\.var$'
                --exclude-dir='/\.local/share/containers$'
                --exclude-dir='/\.local/share/Steam$'
                --exclude-dir='/node_modules$'
                --exclude-dir='/\.git$'
                --exclude-dir='/CachedExtensionVSIXs$'
            )
            ;;
        "Full home scan (/home)")
            mount_src="/home"
            extra_args=()
            ;;
        "Full system scan (/)")
            mount_src="/"
            extra_args=()
            ;;
        "Custom path")
            mount_src=$(gum input --placeholder "/path/to/scan")
            if [[ -z "$mount_src" || ! -e "$mount_src" ]]; then
                echo "${red}Invalid path.${normal}"
                exit 1
            fi
            extra_args=()
            ;;
    esac

    echo "${yellow}ClamAV - Updating virus definitions...${normal}"
    podman run --rm \
        -v clamav_db:/var/lib/clamav \
        clamav/clamav:stable freshclam
    echo ""

    echo "${yellow}ClamAV - Scanning ${blue}${mount_src}${normal}"
    echo "Scan in progress — only infected files will be shown here."
    echo ""

    set +o pipefail
    podman run --rm --name clamav-scan \
        -v clamav_db:/var/lib/clamav \
        --security-opt label=disable \
        -v "${mount_src}:/scandir:ro" \
        clamav/clamav:stable \
        clamscan --recursive --verbose "${extra_args[@]}" /scandir 2>&1 \
    | while IFS= read -r line; do
        case "$line" in
            Scanning\ *)
                short="${line#Scanning /scandir/*/}"
                cols=$(tput cols 2>/dev/null || echo 80)
                limit=$((cols - 14))
                printf "\r\033[K  ${blue}%-${limit}.${limit}s${normal}" "Scanning $short" ;;
            *FOUND*)
                printf "\n${red}%s${normal}\n" "$line" ;;
            *": OK"|*"Empty file"*)
                ;;
            *"---"*|*"SCAN SUMMARY"*|"")
                printf "\n%s\n" "$line" ;;
            *)
                printf "\n%s" "$line" ;;
        esac
    done
    scan_exit=${PIPESTATUS[0]}
    set -o pipefail
    printf "\n"

    echo ""
    case "$scan_exit" in
        0) echo "${green}Scan complete. No threats found.${normal}" ;;
        1) echo "${red}Scan complete. Infected files found!${normal}" ;;
        *) echo "${red}Scan failed with exit code $scan_exit.${normal}"; exit "$scan_exit" ;;
    esac

# Update ClamAV virus definitions
[group('Security')]
update-clamav:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    echo "${blue}Updating ClamAV virus definitions...${normal}"
    podman run --rm \
        -v clamav_db:/var/lib/clamav \
        clamav/clamav:stable freshclam
    echo "${green}Virus definitions updated!${normal}"

# Remove ClamAV image and virus definition volume
[group('Security')]
remove-clamav:
    #!/usr/bin/env bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh

    if $(gum confirm "Remove ClamAV image and virus definitions?"); then
        podman rmi clamav/clamav:stable || true
        podman volume rm clamav_db || true
        echo "${green}ClamAV removed.${normal}"
    fi
