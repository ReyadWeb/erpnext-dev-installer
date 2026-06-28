# ROADMAP v0.8.5

## Current milestone

v0.8.5 focuses on custom local site/domain selection and persistent config.

## Completed in v0.8.5

- User-selectable local site name.
- `.test` hostname guidance for multiple ERPNext VMs.
- Persistent config stored at `/home/frappe/erpnext-dev-config.env`.
- `site-config` command.
- `site-name-guide` command.
- Safer validation for hostname input.

## Next recommended work

### v0.8.6 Restore/uninstall hardening

- Regression-test database-only restore.
- Regression-test database + files restore.
- Confirm app registry remains clean after restore.
- Confirm uninstall/reset flows are safe and explicit.
- Add stronger warnings around destructive actions.

### v0.9.0 Production planning release

- Keep developer installer separate from production installer.
- Draft `install-erpnext-prod.sh` architecture.
- Production preflight design.
- Domain/DNS validation checklist.
- Let's Encrypt HTTP-01 plan.
- Cloudflare DNS-01 plan.
- Cloudflare Origin CA plan.
- Nginx/Supervisor/systemd production model.
- Firewall/security checklist.
- Backup, restore, update, and monitoring strategy.

### v1.0.0 Developer stable

- Fresh Ubuntu 24.04 validation.
- Fresh Ubuntu 26.04 validation.
- Optional app stack validation.
- Backup/restore validation.
- SSL validation.
- Reboot/autostart validation.
- Documentation cleanup.
