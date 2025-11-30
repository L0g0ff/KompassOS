#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# if shit breaks i at least know where it is
set -x

# 
# install WSMan for PSRemoting
pwsh -Command 'Install-Module -Name PSWSMan' -Force
sudo pwsh -Command 'Install-WSMan'
