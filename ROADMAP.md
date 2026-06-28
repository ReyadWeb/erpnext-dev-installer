# Roadmap — ERPNext Developer Installer

## Completed beta milestones

- v0.5.x: App Library, backups, service/autostart, repair tooling
- v0.6.0: Public beta documentation baseline
- v0.7.0: VM/networking diagnostics and SSL roadmap
- v0.8.0: Local HTTPS reverse proxy foundation
- v0.8.1: SSL diagnostics and self-signed workflow
- v0.8.2: Trusted local SSL polish
- v0.8.3: Local SSL replacement/rollback workflow
- v0.8.4: Host/VM safety guard for SSL actions

## v0.8.4 focus

- Add `environment-check` / `where-am-i`
- Block VM-only SSL commands when run on the host by mistake
- Clarify which steps belong on the host vs inside the VM
- Keep direct Bench access unchanged
- Keep local HTTPS unchanged

## Next: v0.9.0 production planning

v0.9.0 should be a planning/design release, not a production automation release yet.

Production planning topics:

- Separate `install-erpnext-prod.sh` direction
- Production preflight checklist
- Domain/DNS verification
- Let’s Encrypt HTTP-01 planning
- Let’s Encrypt DNS-01 with Cloudflare planning
- Cloudflare Origin CA planning
- Firewall model
- Backup/restore strategy
- Update strategy
- Monitoring and recovery

## v1.0.0 criteria

- Fresh VM setup passes
- Reinstall/idempotency passes
- App Library passes
- Backup and restore pass
- Local HTTPS passes
- VM/networking diagnostics pass
- Documentation is complete
