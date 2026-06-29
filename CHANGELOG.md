# Changelog v0.8.9

## Added

- Generic root storage status command:
  - `storage-status`
- Generic root storage expansion command:
  - `expand-root-storage`
- Storage verification command:
  - `verify-storage`
- Setup-time storage check for cloned/resized VMs where the virtual disk is larger than the root filesystem.
- Support for common Ubuntu storage layouts:
  - LVM root on a partition
  - direct ext4 root partition
  - direct XFS root partition
- `AUTO_EXPAND_ROOT=true|false|prompt` environment control.

## Improved

- Setup can now offer to expand root storage before ERPNext installation consumes disk space.
- The storage expansion logic is detector-based and avoids hardcoded devices such as `/dev/vda3`.
- Unknown/risky layouts are detected and skipped safely.

## Safety

- Automatic expansion only runs when the root disk layout is clearly detected.
- Unsupported layouts show a warning and make no changes.
- The command remains interactive unless `AUTO_EXPAND_ROOT=true` or `--yes` is used.
