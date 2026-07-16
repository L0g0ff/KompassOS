#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x

#
# Rebuild the font cache after overlaying the CBDT Noto Color Emoji font.
#
# Fedora 43 switched Noto Color Emoji to the COLRv1 (vector) format, which
# Chrome's Skia engine cannot render, so emoji show up as tofu boxes in Chrome
# and Chromium-based apps (e.g. the Outlook PWA). We ship the upstream CBDT
# (bitmap) build alongside it via files/system/. Both share the same family
# name ("Noto Color Emoji"), so each app picks the format it supports.
#
# See: https://vadkerti.net/posts/fixing-emoji-fonts-on-fedora-atomic/

fc-cache -f
