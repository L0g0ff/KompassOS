#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -euo pipefail
# If errors occur, this helps to identify where
set -x

# Download and install the Citrix workspace app
echo "Starting Citrix Workspace app download and installation process..."

# Download the latest version
url='https://www.citrix.com/downloads/workspace-app/linux/workspace-app-for-linux-latest.html'
echo "Retrieving download link from Citrix website..."
html_content=$(curl -sL "$url")
download_url=$(echo "$html_content" | grep -o "rel=\"//downloads.citrix.com/[^\"]*rhel[^\"]*rpm?__gda__[^\"]*\"" | sed 's/rel="//;s/"$//' | head -1)

# Check if download URL was found
if [ -z "$download_url" ]; then
    echo "ERROR: Couldn't find Citrix Workspace download URL. Website structure may have changed."
    exit 1
fi

# Extract the filename
filename=$(echo "$download_url" | grep -o "ICAClient-rhel-[^?]*")
if [ -z "$filename" ]; then
    echo "WARNING: Couldn't extract filename, using default name."
    filename="ICAClient-rhel.rpm"
fi

# Download the file
echo "Downloading Citrix Workspace from: https:$download_url"
curl -L "https:$download_url" -o "/tmp/$filename"

# Verify the download
if [ ! -f "/tmp/$filename" ]; then
    echo "ERROR: Download failed - file not found."
    exit 1
fi

# Install with rpm-ostree
echo "Installing Citrix Workspace..."
rpm-ostree install "/tmp/$filename"

# Clean up
echo "Cleaning up temporary files..."
rm -f "/tmp/$filename"

echo "Citrix Workspace installation completed successfully!"