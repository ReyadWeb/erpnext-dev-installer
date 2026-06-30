# ERPNext Developer Installer Roadmap

## Current baseline: v0.8.19

v0.8.19 focuses on optional app checkpointing and safer app installation workflows.

Completed:

- Ubuntu 24.04 / 26.04 support
- Frappe v16 + ERPNext v16 install
- Custom `.test` site name support
- Systemd service and autostart
- Runtime and doctor checks
- Generic root storage expansion
- Private installer logs
- Safer credential output
- Guided setup flow
- Verify access workflow
- Next-step workflow
- Local SSL wizard
- Optional app install wizard
- Pre-app backup checkpoint prompt
- Post-app validation summary
- Optional app rollback guide

## Next recommended patch: v0.8.20

Focus: final polish before v0.9 planning.

Targets:

- Improve host/VM IP hinting in guard messages
- Add a compact `release-check` command
- Add shellcheck-oriented cleanup
- Improve app install failure recovery notes
- Add final guided workflow documentation pass

## Future v0.9.x

Focus: production-readiness planning without mixing dev and production automation.

Targets:

- Production domain planning
- Production SSL planning
- Production Nginx architecture checklist
- Backup/restore validation checklist
- Firewall and monitoring checklist

## v1.x goal

Stable developer installer suitable for repeated fresh VM installs, local testing, and demo environments.
