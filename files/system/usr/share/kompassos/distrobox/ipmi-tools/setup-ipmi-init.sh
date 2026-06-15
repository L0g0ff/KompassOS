#!/usr/bin/env bash
# Installs vendor management tools that are not available via apt.
# Runs inside the ipmi-tools distrobox as an init_hook. Idempotent: it only
# acts on vendor archives that are actually present in this directory, and
# skips anything already installed.
set -euo pipefail

VENDOR_DIR="/usr/share/kompassos/distrobox/ipmi-tools"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

log() { echo ">> $*"; }

# --- Dell iDRAC racadm -------------------------------------------------------
# Installed from Dell's OpenManage apt repo (community/openmanage/11010, the
# newest release with Ubuntu jammy support). Release is signed by Dell key
# 0x1285491434D8786F. The srvadmin-idracadm7 package ships the racadm binary
# used for ALL iDRAC generations (7/8/9); srvadmin-idracadm8 is an empty
# support package the user asked to include alongside it.
DELL_KEYRING="/usr/share/keyrings/dell-openmanage.gpg"
DELL_LIST="/etc/apt/sources.list.d/dell-openmanage.list"
DELL_REPO="https://linux.dell.com/repo/community/openmanage/11010/jammy"
RACADM="/opt/dell/srvadmin/bin/idracadm7"
LIBDIR="/usr/lib/x86_64-linux-gnu"

if [ -x "$RACADM" ] && [ -x /usr/local/bin/idracadm7 ]; then
    log "Dell racadm already installed, skipping."
else
    log "Configuring Dell OpenManage repo and installing racadm..."
    curl -fsSL https://linux.dell.com/repo/pgp_pubkeys/0x1285491434D8786F.asc \
        | gpg --dearmor --yes -o "$DELL_KEYRING"
    echo "deb [signed-by=$DELL_KEYRING] $DELL_REPO jammy main" > "$DELL_LIST"
    apt-get update

    # Dell maintainer scripts run `systemctl enable ...` for in-band services
    # that cannot run in this init-less container (and aren't needed for remote
    # management). There is no systemd here, so drop a no-op systemctl into
    # /usr/sbin (which is on the PATH dpkg gives maintainer scripts) so package
    # configuration completes, then remove it again.
    shim="/usr/sbin/systemctl"
    printf '#!/bin/sh\nexit 0\n' > "$shim"
    chmod +x "$shim"
    apt-get install -y srvadmin-idracadm7 srvadmin-idracadm8 || true
    dpkg --configure -a
    rm -f "$shim"

    # Expose the racadm binary on PATH. Dell ships a single binary (idracadm7)
    # that drives all iDRAC generations; srvadmin-idracadm8 contains no binary
    # of its own, so idracadm8 is a convenience alias to the same tool.
    ln -sf "$RACADM" /usr/local/bin/idracadm7
    ln -sf "$RACADM" /usr/local/bin/idracadm8

    # racadm looks for an unversioned libssl.so/libcrypto.so; Ubuntu ships only
    # the versioned .so.3, so racadm fails with RAC1170 without these links.
    [ -e "$LIBDIR/libssl.so.3" ]    && ln -sf libssl.so.3    "$LIBDIR/libssl.so"
    [ -e "$LIBDIR/libcrypto.so.3" ] && ln -sf libcrypto.so.3 "$LIBDIR/libcrypto.so"
    ldconfig
    log "Dell racadm ready: idracadm7 -r <idrac-ip> -u <user> -p <pass> getsysinfo"
fi

# --- Supermicro SUM ----------------------------------------------------------
# Drop Supermicro's SUM tarball (sum_*_Linux_x86_64*.tar.gz) into this directory.
if command -v sum >/dev/null 2>&1; then
    log "Supermicro SUM already installed, skipping."
else
    sum_tar="$(find "$VENDOR_DIR" -maxdepth 1 -iname 'sum_*Linux*.tar.gz' | head -n1 || true)"
    if [ -n "$sum_tar" ]; then
        log "Installing Supermicro SUM from $(basename "$sum_tar")..."
        tar -xzf "$sum_tar" -C "$WORK"
        sum_bin="$(find "$WORK" -type f -name sum | head -n1 || true)"
        if [ -n "$sum_bin" ]; then
            install -m 0755 "$sum_bin" /usr/local/bin/sum
            log "Installed /usr/local/bin/sum"
        else
            log "No 'sum' binary found inside the tarball."
        fi
    else
        log "No Supermicro SUM tarball found; skipping sum."
    fi
fi

# --- HP/HPE (optional) -------------------------------------------------------
# hponcfg / ssacli / ilorest come from HPE's SDR repos. ipmitool already covers
# generic iLO management. Uncomment and adapt if you need the HPE-specific tools:
#
#   curl -fsSL https://downloads.linux.hpe.com/SDR/hpePublicKey2048_key1.pub | apt-key add -
#   echo "deb http://downloads.linux.hpe.com/SDR/repo/mcp jammy/current non-free" \
#       > /etc/apt/sources.list.d/hpe-mcp.list
#   apt-get update && apt-get install -y hponcfg ssacli

log "IPMI toolbox setup complete."
