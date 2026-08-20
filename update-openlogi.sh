#!/bin/bash
set -euo pipefail

# Fetch the latest upstream release tag.
LATEST_VER=$(curl -fsSL https://api.github.com/repos/AprilNEA/OpenLogi/releases/latest | jq -r '.tag_name')
if [ -z "$LATEST_VER" ] || [ "$LATEST_VER" = "null" ]; then
    echo "Could not determine the latest OpenLogi release."
    exit 1
fi

# Extract the current version without evaluating PKGBUILD.
CURRENT_VER=$(grep -m1 '^pkgver=' PKGBUILD | cut -d= -f2-)
if [ -z "$CURRENT_VER" ]; then
    echo "Could not determine the current package version."
    exit 1
fi

echo "Current version: $CURRENT_VER"
echo "Latest version:  $LATEST_VER"

if [ "$CURRENT_VER" = "$LATEST_VER" ]; then
    echo "Already up to date."
    exit 0
fi

# Do not replace a package with an older (or non-newer) upstream release.
if [ "$(printf '%s\n%s\n' "$CURRENT_VER" "$LATEST_VER" | sort -V | tail -n1)" != "$LATEST_VER" ]; then
    echo "Current package version is newer than the latest upstream release."
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
