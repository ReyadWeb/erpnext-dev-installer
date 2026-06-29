# Changelog

## v0.8.17

Guided setup and access verification patch.

### Added

- `guided-setup` command for a clearer new-user workflow.
- `next-step` command to show the next recommended action based on current VM state.
- `verify-access` command to verify local ERPNext HTTP access from inside the VM and print host-side tests.
- Access submenu entry for ERPNext HTTP verification.
- Main menu entries for Guided Setup, Verify Access, and Next Step.

### Improved

- Post-install summary now points users to `verify-access` after setup.
- Help output now recommends `guided-setup -> verify-access -> next-step`.
- Guided setup separates ERPNext installation from later SSL and optional app work.

### Notes

- v0.8.17 does not change the proven storage expansion flow from v0.8.15/v0.8.16.
- v0.8.17 keeps the private log and safer credential handling from v0.8.16.

## v0.8.16

Security and reliability cleanup.

- Private installer logs with `600` permissions.
- Generated Administrator password no longer printed into terminal logs.
- Installer lock file to reduce overlapping task risk.
- Clean release ZIP without `.git`.
