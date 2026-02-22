#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="aura"
iso_label="AURA_$"
iso_publisher="Aura Linux <https://github.com/CjLogic/Aura-Ambxst>"
iso_application="Aura Installer"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
# Boot modes: Legacy BIOS + UEFI (systemd-boot prioritized for ASUS compatibility, GRUB as fallback)
bootmodes=('bios.syslinux' 'uefi.grub' 'uefi.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/.gnupg"]="0:0:700"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/root/configurator"]="0:0:755"
  ["/var/cache/aura/mirror/offline/"]="0:0:775"
  ["/usr/local/bin/aura-upload-log"]="0:0:755"
)
