#!/bin/bash

set -e

# Note that these are packages installed to the Arch container used to build the ISO.
pacman-key --init
pacman --noconfirm -Sy archlinux-keyring
pacman --noconfirm -Sy archiso git sudo base-devel jq grub

# Install omarchy-keyring for package verification during build
# The [omarchy] repo is defined in /configs/pacman-online.conf with SigLevel = Optional TrustAll
pacman --config /configs/pacman-online.conf --noconfirm -Sy omarchy-keyring

# Create a dummy aura.gpg to satisfy any hooks looking for it
mkdir -p /usr/share/pacman/keyrings
touch /usr/share/pacman/keyrings/aura.gpg
touch /usr/share/pacman/keyrings/aura-trusted
touch /usr/share/pacman/keyrings/aura-revoked

pacman-key --populate omarchy 2>/dev/null || true

# Setup build locations
build_cache_dir="/var/cache"
offline_mirror_dir="$build_cache_dir/airootfs/var/cache/aura/mirror/offline"
mkdir -p $build_cache_dir/
mkdir -p $offline_mirror_dir/

# We base our ISO on the official arch ISO (releng) config
cp -r /archiso/configs/releng/* $build_cache_dir/
rm "$build_cache_dir/airootfs/etc/motd"

# Avoid using reflector for mirror identification as we are relying on the global CDN
rm -rf "$build_cache_dir/airootfs/etc/systemd/system/multi-user.target.wants/reflector.service"
rm -rf "$build_cache_dir/airootfs/etc/systemd/system/reflector.service.d"
rm -rf "$build_cache_dir/airootfs/etc/xdg/reflector"

# Bring in our configs
cp -r /configs/* $build_cache_dir/

# Setup Aura itself
if [[ -d /aura ]]; then
  cp -rp /aura "$build_cache_dir/airootfs/root/aura"
else
  git clone -b $AURA_INSTALLER_REF https://github.com/$AURA_INSTALLER_REPO.git "$build_cache_dir/airootfs/root/aura"
fi

# Make log uploader available in the ISO too
mkdir -p "$build_cache_dir/airootfs/usr/local/bin/"
cp "$build_cache_dir/airootfs/root/aura/bin/aura-upload-log" "$build_cache_dir/airootfs/usr/local/bin/aura-upload-log"

# Copy the Aura Plymouth theme to the ISO
mkdir -p "$build_cache_dir/airootfs/usr/share/plymouth/themes/aura"
cp -r "$build_cache_dir/airootfs/root/aura/default/plymouth/"* "$build_cache_dir/airootfs/usr/share/plymouth/themes/aura/"

# Download and verify Node.js binary for offline installation
NODE_DIST_URL="https://nodejs.org/dist/latest"

# Get checksums and parse filename and SHA
NODE_SHASUMS=$(curl -fsSL "$NODE_DIST_URL/SHASUMS256.txt")
NODE_FILENAME=$(echo "$NODE_SHASUMS" | grep "linux-x64.tar.gz" | awk '{print $2}')
NODE_SHA=$(echo "$NODE_SHASUMS" | grep "linux-x64.tar.gz" | awk '{print $1}')

# Download the tarball
curl -fsSL "$NODE_DIST_URL/$NODE_FILENAME" -o "/tmp/$NODE_FILENAME"

# Verify SHA256 checksum
echo "$NODE_SHA /tmp/$NODE_FILENAME" | sha256sum -c - || {
    echo "ERROR: Node.js checksum verification failed!"
    exit 1
}

# Copy to ISO
mkdir -p "$build_cache_dir/airootfs/opt/packages/"
cp "/tmp/$NODE_FILENAME" "$build_cache_dir/airootfs/opt/packages/"

# Add our additional packages to packages.x86_64
arch_packages=(linux linux-headers git gum jq openssl plymouth tzupdate omarchy-keyring)
printf '%s\n' "${arch_packages[@]}" >>"$build_cache_dir/packages.x86_64"

# Build list of all the packages needed for the offline mirror
all_packages=($(cat "$build_cache_dir/packages.x86_64"))
all_packages+=($(grep -v '^#' "$build_cache_dir/airootfs/root/aura/install/aura-base.packages" | grep -v '^$'))
all_packages+=($(grep -v '^#' "$build_cache_dir/airootfs/root/aura/install/aura-other.packages" | grep -v '^$'))
all_packages+=($(grep -v '^#' /builder/archinstall.packages | grep -v '^$'))

# Download official packages to the offline mirror
echo "Downloading packages from official repos..."
mkdir -p /tmp/offlinedb
pacman --config /configs/pacman-online.conf --noconfirm -Syw "${all_packages[@]}" --cachedir $offline_mirror_dir/ --dbpath /tmp/offlinedb

repo-add --new "$offline_mirror_dir/offline.db.tar.gz" "$offline_mirror_dir/"*.pkg.tar.zst

# Create a symlink to the offline mirror instead of duplicating it.
# mkarchiso needs packages at /var/cache/aura/mirror/offline in the container,
# but they're actually in $build_cache_dir/airootfs/var/cache/aura/mirror/offline
mkdir -p /var/cache/aura/mirror
ln -s "$offline_mirror_dir" "/var/cache/aura/mirror/offline"

# Copy the pacman.conf to the ISO's /etc directory so the live environment uses our
# same config when booted
cp $build_cache_dir/pacman.conf "$build_cache_dir/airootfs/etc/pacman.conf"

# Finally, we assemble the entire ISO
mkarchiso -v -w "$build_cache_dir/work/" -o "/out/" "$build_cache_dir/"

# Fix ownership of output files to match host user
if [ -n "$HOST_UID" ] && [ -n "$HOST_GID" ]; then
    chown -R "$HOST_UID:$HOST_GID" /out/
fi
