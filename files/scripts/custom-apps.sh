#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x

# Interesting Repo (Thanks man!) https://github.com/sneexy-boi/bluebuild-custom/blob/main/files/scripts/system-wuzetka.sh


# Your code goes here.
echo 'Download and Install Keeper'

#
# Keeper
#
curl -sL -o /tmp/keeper.rpm "https://download.keepersecurity.com/desktop_electron/Linux/repo/rpm/keeperpasswordmanager-16.11.3-1.x86_64.rpm"
rpm-ostree install /tmp/keeper.rpm