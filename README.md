# Aura ISO

The aura ISO streamlines [the installation of Aura](https://github.com/CjLogic/Aura-Ambxst). It includes the aura Configurator as a front-end to archinstall and automatically launches the [Aura Installer](https://github.com/CjLogic/Aura-Ambxst) after base arch has been setup.

## System Requirements

if you have  Asus Hardware check this out [Asus Compatibility Guide](ASUS-COMPATIBILITY.md)

- **RAM**: 2GB minimum (4GB recommended)
- **Disk Space**: 20GB minimum
- **CPU**: x86_64 processor
- **Graphics**: GPU with Wayland support recommended
- **Boot**: UEFI or BIOS

## Creating the ISO

Run `./bin/aura-iso-make` and the output goes into `./release`. You can build from your local $aura_PATH for testing by using `--local-source` or from a checkout of the dev branch (instead of master) by using `--dev`.

### Environment Variables

You can customize the repositories used during the build process by passing in variables:

- `aura_INSTALLER_REPO` - GitHub repository for the installer (default: `cjlogic/aura`)
- `aura_INSTALLER_REF` - Git ref (branch/tag) for the installer (default: `master`)

Example usage:

```bash
aura_INSTALLER_REPO="cjlogic/aura" aura_INSTALLER_REF="some-feature" ./bin/aura-iso-make
```

## Testing the ISO

Run `./bin/aura-iso-boot [release/aura.iso]`.

## Signing the ISO

Run `./bin/aura-iso-sign [gpg-user] [release/aura.iso]`.

## Uploading the ISO

Run `./bin/aura-iso-upload [release/aura.iso]`. This requires you've configured rclone (use `rclone config`).

## Full release of the ISO

Run `./bin/aura-iso-release` to create, test, sign, and upload the ISO in one flow.
