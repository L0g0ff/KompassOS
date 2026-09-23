# Test this Just file: /usr/bin/just --justfile files/justfiles/generate_iso.just --choose

# Generate ISO for KompassOS DX HWE
[group('Apps')]
generate-iso-kompassos-dx-hwe:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Creating ISO directory..."
    mkdir -p ~/iso
    echo "Changing to ISO directory..."
    cd ~/iso
    echo "Generating ISO..."
    rm -f kompassos-dx-hwe.iso kompassos-dx-hwe.iso-CHECKSUM
    # Calls the installer container directly: bluebuild generate-iso pins v1.4.0,
    # whose lorax templates strip /usr/sbin/load_policy (anaconda 44.30 exit crash).
    sudo podman run --rm --privileged \
        -v "$PWD":/build-container-installer/build \
        -v dnf-cache:/cache/dnf/ \
        ghcr.io/jasonn3/build-container-installer:v1.5.0 \
        VARIANT=Kinoite \
        ISO_NAME=build/kompassos-dx-hwe.iso \
        DNF_CACHE=/cache/dnf \
        SECURE_BOOT_KEY_URL=https://github.com/ublue-os/bazzite/raw/main/secure_boot.der \
        ENROLLMENT_PASSWORD=universalblue \
        WEB_UI=false \
        IMAGE_NAME=kompassos-dx-hwe \
        IMAGE_REPO=ghcr.io/l0g0ff \
        IMAGE_TAG=latest \
        VERSION=44
    echo "ISO generated successfully in ~/iso/"

# Generate ISO for KompassOS DX HWE Nvidia
[group('Apps')]
generate-iso-kompassos-dx-hwe-nvidia:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Creating ISO directory..."
    mkdir -p ~/iso
    echo "Changing to ISO directory..."
    cd ~/iso
    echo "Generating ISO..."
    rm -f kompassos-dx-hwe-nvidia.iso kompassos-dx-hwe-nvidia.iso-CHECKSUM
    # Calls the installer container directly: bluebuild generate-iso pins v1.4.0,
    # whose lorax templates strip /usr/sbin/load_policy (anaconda 44.30 exit crash).
    sudo podman run --rm --privileged \
        -v "$PWD":/build-container-installer/build \
        -v dnf-cache:/cache/dnf/ \
        ghcr.io/jasonn3/build-container-installer:v1.5.0 \
        VARIANT=Kinoite \
        ISO_NAME=build/kompassos-dx-hwe-nvidia.iso \
        DNF_CACHE=/cache/dnf \
        SECURE_BOOT_KEY_URL=https://github.com/ublue-os/bazzite/raw/main/secure_boot.der \
        ENROLLMENT_PASSWORD=universalblue \
        WEB_UI=false \
        IMAGE_NAME=kompassos-dx-hwe-nvidia \
        IMAGE_REPO=ghcr.io/l0g0ff \
        IMAGE_TAG=latest \
        VERSION=44
    echo "ISO generated successfully in ~/iso/"

# Generate ISO for KompassOS DX Surface
[group('Apps')]
generate-iso-kompassos-dx-surface:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Creating ISO directory..."
    mkdir -p ~/iso
    echo "Changing to ISO directory..."
    cd ~/iso
    echo "Generating ISO..."
    rm -f kompassos-dx-surface.iso kompassos-dx-surface.iso-CHECKSUM
    # Calls the installer container directly: bluebuild generate-iso pins v1.4.0,
    # whose lorax templates strip /usr/sbin/load_policy (anaconda 44.30 exit crash).
    sudo podman run --rm --privileged \
        -v "$PWD":/build-container-installer/build \
        -v dnf-cache:/cache/dnf/ \
        ghcr.io/jasonn3/build-container-installer:v1.5.0 \
        VARIANT=Kinoite \
        ISO_NAME=build/kompassos-dx-surface.iso \
        DNF_CACHE=/cache/dnf \
        SECURE_BOOT_KEY_URL=https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.cer \
        ENROLLMENT_PASSWORD=universalblue \
        WEB_UI=false \
        IMAGE_NAME=kompassos-dx-surface \
        IMAGE_REPO=ghcr.io/l0g0ff \
        IMAGE_TAG=latest \
        VERSION=44
    echo "ISO generated successfully in ~/iso/"

# Install and validate an ISO in a local KVM VM
[group('Apps')]
test-iso iso='':
    #!/usr/bin/env bash
    set -euo pipefail

    iso_arg={{quote(iso)}}
    if [[ -z "$iso_arg" ]]; then
        command -v gum >/dev/null || { echo "Missing command: gum" >&2; exit 1; }
        isos=()
        for name in kompassos-dx-hwe kompassos-dx-hwe-nvidia kompassos-dx-surface; do
            [[ -f "$HOME/iso/$name.iso" ]] && isos+=("$HOME/iso/$name.iso")
        done
        ((${#isos[@]})) || { echo "No KompassOS ISOs found in ~/iso" >&2; exit 1; }
        iso_arg=$(printf '%s\n' "${isos[@]}" | gum choose --header "Choose a KompassOS ISO")
    fi
    iso="$(realpath -- "$iso_arg")"
    test -f "$iso" || { echo "ISO not found: $iso" >&2; exit 1; }
    exec {iso_fd}<"$iso"
    expected=$(basename "$iso" .iso)
    case "$expected" in
        kompassos-dx-hwe|kompassos-dx-hwe-nvidia|kompassos-dx-surface) ;;
        *) echo "Unsupported KompassOS ISO name: $expected.iso" >&2; exit 1 ;;
    esac
    for command in virsh virt-install xorriso python3 timeout; do
        command -v "$command" >/dev/null || { echo "Missing command: $command" >&2; exit 1; }
    done

    sudo -v
    vm=kompassos-iso-test
    pool=/var/lib/libvirt/images/$vm
    disk=$pool/$vm.qcow2
    staged_iso=$pool/installer.iso
    seed=$pool/oemdrv.iso
    work=${XDG_STATE_HOME:-$HOME/.local/state}/kompassos-iso-test
    screenshot=$work/final-screen.ppm
    mkdir -p "$work"

    # A new run replaces the previous test VM; a completed run preserves it.
    if sudo virsh -c qemu:///system dominfo "$vm" >/dev/null 2>&1; then
        sudo virsh -c qemu:///system destroy "$vm" >/dev/null 2>&1 || true
        sudo virsh -c qemu:///system undefine "$vm" --nvram >/dev/null 2>&1 \
            || sudo virsh -c qemu:///system undefine "$vm" >/dev/null
    fi
    sudo install -d -m 0755 "$pool"
    sudo rm -f "$disk" "$staged_iso" "$seed"
    sudo cp --reflink=auto "/proc/$$/fd/$iso_fd" "$staged_iso"

    cat > "$work/ks.cfg" <<'KS'
    #version=F44
    text
    eula --agreed
    lang en_US.UTF-8
    keyboard us
    timezone UTC --utc
    network --bootproto=dhcp --device=link --activate --hostname=kompassos-iso-test
    zerombr
    clearpart --all --initlabel
    autopart --type=btrfs
    rootpw --lock
    selinux --enforcing
    firewall --enabled
    services --enabled=qemu-guest-agent
    poweroff
    %post
    # Text-mode Anaconda otherwise changes the installed default to multi-user.
    ln -sf /usr/lib/systemd/system/graphical.target /etc/systemd/system/default.target
    %end
    %include /usr/share/anaconda/interactive-defaults.ks
    KS
    xorriso -as mkisofs -quiet -V OEMDRV -o "$work/oemdrv.iso" "$work/ks.cfg"
    exec {seed_fd}<"$work/oemdrv.iso"
    sudo install -m 0644 "/proc/$$/fd/$seed_fd" "$seed"
    sudo chmod 0644 "$staged_iso"
    sudo restorecon -R "$pool" 2>/dev/null || true

    if ! timeout --foreground --kill-after=30s 2h sudo virt-install --connect qemu:///system \
        --name "$vm" --memory 8192 --vcpus "$(( $(nproc) > 4 ? $(nproc) - 2 : 2 ))" --cpu host-passthrough \
        --disk "path=$disk,size=40,format=qcow2,bus=virtio" \
        --cdrom "$staged_iso" --disk "path=$seed,device=cdrom,bus=sata" \
        --network network=default,model=virtio \
        --channel unix,target.type=virtio,target.name=org.qemu.guest_agent.0 \
        --graphics vnc,listen=127.0.0.1 --video virtio \
        --boot uefi --osinfo detect=on,require=off --check disk_size=off \
        --noautoconsole --wait -1 --noreboot; then
        echo "virt-install failed or timed out after 2 hours" >&2
        exit 1
    fi

    test "$(sudo virsh -c qemu:///system domstate "$vm" | tr -d '\r')" = "shut off"
    while read -r target; do
        sudo virsh -c qemu:///system detach-disk "$vm" "$target" --config
    done < <(sudo virsh -c qemu:///system domblklist "$vm" --details \
        | awk '$2 == "cdrom" {print $3}')
    sudo virsh -c qemu:///system start "$vm"

    qga_virsh() {
        timeout --foreground --kill-after=5s 10s sudo virsh -c qemu:///system qemu-agent-command "$vm" "$1"
    }

    agent_deadline=$((SECONDS + 600))
    until qga_virsh '{"execute":"guest-ping"}' >/dev/null 2>&1; do
        if (( SECONDS >= agent_deadline )); then
            echo "QEMU guest agent did not become ready within 10 minutes" >&2
            exit 1
        fi
        sleep 5
    done

    qga_exec() {
        local payload reply pid status exec_deadline exited=
        payload=$(QGA_COMMAND="$1" python3 -c 'import json,os; print(json.dumps({"execute":"guest-exec","arguments":{"path":"/usr/bin/bash","arg":["-c",os.environ["QGA_COMMAND"]],"capture-output":True}}))')
        if ! reply=$(qga_virsh "$payload"); then
            echo "Failed to start QEMU guest command" >&2
            return 1
        fi
        pid=$(REPLY="$reply" python3 -c 'import json,os; print(json.loads(os.environ["REPLY"])["return"]["pid"])')
        exec_deadline=$((SECONDS + 300))
        while (( SECONDS < exec_deadline )); do
            if status=$(qga_virsh "{\"execute\":\"guest-exec-status\",\"arguments\":{\"pid\":$pid}}") \
                && STATUS="$status" python3 -c 'import json,os,sys; sys.exit(0 if json.loads(os.environ["STATUS"])["return"].get("exited") else 1)'; then
                exited=1
                break
            fi
            sleep 2
        done
        test "$exited" || { echo "QEMU guest-exec did not finish within 5 minutes" >&2; return 1; }
        STATUS="$status" python3 -c 'import base64,json,os,sys; r=json.loads(os.environ["STATUS"])["return"]; sys.stdout.buffer.write(base64.b64decode(r.get("out-data", ""))); sys.stderr.buffer.write(base64.b64decode(r.get("err-data", ""))); sys.exit(r.get("exitcode", 1))'
    }

    qga_exec "set -e; test -z \"\$(getent passwd 1000)\"; grep -Fq \"VARIANT_ID=\\\"kompassos\\\"\" /etc/os-release; grep -F \"container-image-reference=ostree-image-signed:docker://ghcr.io/l0g0ff/$expected:latest\" /sysroot/ostree/deploy/*/deploy/*.origin"
    sudo virsh --quiet -c qemu:///system screenshot "$vm" /dev/stdout > "$screenshot"

    echo "ISO installation and boot checks passed."
    echo "VM preserved for manual testing: $vm"
    echo "Open it with: virt-viewer --connect qemu:///system $vm"
    echo "Screenshot: $screenshot"