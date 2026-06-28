# ERPNext Developer Installer Roadmap

## Current release: v0.7.0 Beta

Focus: VM/networking foundation and access diagnostics.

### Completed through v0.7.0

- Fresh ERPNext developer install workflow.
- Frappe v16 + ERPNext v16 setup.
- systemd service for local developer startup.
- Autostart on VM boot.
- Readiness waiting for ports 8000, 9000, 11000, and 13000.
- Status and doctor reports.
- Backup and backup-with-files commands.
- App Library installs for CRM, HRMS, Telephony, Helpdesk, and Insights.
- App registry repair for `sites/apps.txt`.
- Optional app status checks in doctor.
- VM network diagnostics.
- KVM fixed-IP and VM-identification guidance.
- Future SSL roadmap command.

## v0.7.x stabilization

- Test `network-status`, `hosts-command`, `host-test`, and `kvm-identify` on multiple VM names, including names with spaces.
- Improve host-side instructions for Linux Mint, Ubuntu, and bridged networking.
- Add clearer warnings when the VM IP changes.
- Add optional environment variable examples for multiple sites.

## v0.8.0 Local HTTPS planning / implementation

Goal: local HTTPS for developer VMs without making the project production-only.

Planned architecture:

```text
Browser HTTPS :443
  -> Nginx reverse proxy inside VM
    -> Bench web 127.0.0.1:8000
    -> Socket.io 127.0.0.1:9000
```

Planned commands:

```bash
./install-erpnext-dev.sh ssl-status
./install-erpnext-dev.sh local-ssl-guide
./install-erpnext-dev.sh configure-local-ssl
./install-erpnext-dev.sh disable-local-ssl
```

Recommended local certificate approach:

- mkcert or local CA workflow.
- Trust the local CA on the host browser machine.
- Keep Redis and internal services private.

## v0.9.0 Production planning branch

Production should likely become a separate script or mode.

Candidate production features:

- Production preflight checks.
- Domain/DNS validation.
- Nginx production config.
- Supervisor or production systemd units.
- Let's Encrypt HTTP-01.
- Let's Encrypt DNS-01 with Cloudflare.
- Cloudflare Origin CA workflow.
- Firewall setup.
- Backup and restore policy.
- Monitoring and update strategy.

## v1.0.0 Stable developer installer criteria

- Fresh Ubuntu 24.04 VM install passes.
- Fresh Ubuntu 26.04 VM install passes.
- Reboot/autostart passes.
- Start/stop/restart passes.
- Doctor/status passes.
- Backup/list-backups passes.
- Restore database passes.
- Restore full backup passes.
- CRM install passes.
- HRMS install passes.
- Helpdesk + Telephony install passes.
- Insights install passes.
- Uninstall/reset passes on disposable VM.
- README and TESTING guide complete.
