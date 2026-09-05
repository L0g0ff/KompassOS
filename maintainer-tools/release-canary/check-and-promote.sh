#!/usr/bin/bash
# Maintainer-only tool, not shipped in the image (see maintainer-tools/release-canary/README.md).
#
# Fired once per boot, 1 hour after boot, by release-canary.timer. If the
# booted deployment is a release-candidate build, asks whether to promote it
# to :latest. Promoting copies the exact digest that has now run for an hour
# (not whatever :release-candidate currently points at), so a newer RC build
# landing in the meantime can't get silently promoted instead. Approving
# also promotes the other 2 variants' build from that exact same build.yml
# run (found via the GitHub Actions run history, not their current
# :release-candidate tag, which a same-commit scheduled rebuild could have
# already overwritten) - see .github/workflows/promote.yml.
set -euo pipefail

REPO="L0g0ff/KompassOS"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/release-canary"
mkdir -p "$STATE_DIR"

booted=$(rpm-ostree status --json | jq -c '.deployments[] | select(.booted == true)')
ref=$(jq -r '."container-image-reference"' <<<"$booted")
digest=$(jq -r '."container-image-reference-digest"' <<<"$booted")

# ref looks like: ostree-image-signed:docker://ghcr.io/l0g0ff/kompassos-dx-hwe-nvidia:release-candidate
image="${ref#*docker://}"
tag="${image##*:}"
image="${image%:*}"

if [[ "$tag" != "release-candidate" ]]; then
    exit 0
fi

state_file="$STATE_DIR/asked-$digest"
if [[ -e "$state_file" ]]; then
    exit 0
fi
touch "$state_file"

if kdialog --title "KompassOS release candidate" \
    --yesno "$image is running as release-candidate ($digest) and has been up for 1 hour.\n\nPromote to :latest? This also promotes the hwe and surface builds from this same commit - they haven't been canary-tested separately yet."; then
    gh workflow run promote.yml --repo "$REPO" -f "tested_image=$image" -f "tested_digest=$digest"
    kdialog --title "KompassOS release candidate" --passivepopup "Promotion triggered for $image@$digest (+ other variants)" 10
fi
