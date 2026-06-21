#!/bin/bash
set -e

# Fetch latest version tag from GitHub API
LATEST_VER=$(curl -s https://api.github.com/repos/AprilNEA/OpenLogi/releases/latest | jq -r '.tag_name')

# Extract current version from PKGBUILD
CURRENT_VER=$(source ./PKGBUILD && echo "$pkgver")

echo "Current version: $CURRENT_VER"
echo "Latest version:  $LATEST_VER"

if [ "$CURRENT_VER" = "$LATEST_VER" ]; then
    echo "Already up to date."
    exit 0
fi

echo "Updating PKGBUILD..."
# Update pkgver and reset pkgrel
sed -i "s/^pkgver=.*/pkgver=$LATEST_VER/" PKGBUILD
sed -i "s/^pkgrel=.*/pkgrel=1/" PKGBUILD

# Get new checksums using makepkg -g
echo "Generating new checksums..."
NEW_SUMS=$(makepkg -g)

# Replace the sha256sums line in PKGBUILD
sed -i "s/^sha256sums=.*/$NEW_SUMS/" PKGBUILD

# Regenerate .SRCINFO
echo "Updating .SRCINFO..."
makepkg --printsrcinfo > .SRCINFO

# Clean up downloaded deb files
rm -f openlogi-*.deb

echo "Update complete!"
