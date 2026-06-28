# Changelog — v0.8.4

## Added

- Added `environment-check` command.
- Added `where-am-i` alias.
- Added VM-only safety guard for local SSL actions.
- Added clearer host-vs-VM command guidance.
- Added `install-local-ssl-cert` and `replace-local-ssl-cert` command support in the consolidated script.
- Added `browser-trust-guide` and `verify-ssl-rollback` support in the consolidated script.

## Changed

- Local SSL commands now refuse to run when the ERPNext VM context is not detected.
- SSL guide now makes host-side mkcert steps and VM-side install/configure steps clearer.
- Advanced and Access menus include environment-check and SSL workflow actions.

## Fixed

- Prevents confusing host-side `ssl-status` output when the script is accidentally run on Linux Mint host.
- Prevents accidental host-side Nginx/certificate changes from VM-only SSL commands.
- Corrected Advanced menu SSL numbering.

## Notes

This is still a developer VM installer, not a production installer.
