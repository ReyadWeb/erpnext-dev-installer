# Changelog

## v0.7.0 Beta

### Added

- `network-status` command for VM IP/MAC/interface/gateway/access diagnostics.
- `hosts-command` command for host `/etc/hosts` mapping.
- `host-test` command for host-side curl/getent checks.
- `kvm-identify` command to find the matching libvirt VM by MAC address.
- `ssl-roadmap` command for future local and production HTTPS planning.
- Expanded Access submenu.
- Expanded Advanced menu networking options.
- ROADMAP guidance for local SSL and future production SSL.

### Improved

- KVM guidance now includes a `while read` loop that handles libvirt VM names with spaces.
- Network guidance clearly separates VM commands from host commands.
- Roadmap now defines local SSL, production SSL, and a future production installer track.

### Kept from v0.6.0

- Verified App Library baseline.
- Optional app status in doctor.
- Compact ERPNext Ready output.
- Public beta documentation structure.

### Not included yet

- No local SSL automation yet.
- No production SSL automation yet.
- No Nginx reverse proxy automation yet.
