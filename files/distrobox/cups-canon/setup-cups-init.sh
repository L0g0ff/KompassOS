#!/bin/bash
# Simple CUPS port configuration script

set -e

# Configure CUPS to use port 6631
sed -i 's/Listen localhost:631/Listen localhost:6631/g' /etc/cups/cupsd.conf
sed -i 's|Listen /run/cups/cups.sock|Listen localhost:6631|g' /etc/cups/cupsd.conf