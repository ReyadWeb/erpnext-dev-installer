# ERPNext Developer Installer v0.8.19

A guided ERPNext/Frappe developer VM installer for Ubuntu 24.04 / 26.04 LTS.

Default stack:

- Frappe v16
- ERPNext v16
- Local site name: `erp.test`
- Developer runtime using `bench start`
- Optional systemd autostart service
- Optional local HTTPS reverse proxy
- Optional app install wizard with backup checkpoints

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/ReyadWeb/erpnext-dev-installer/main/install-erpnext-dev.sh -o install-erpnext-dev.sh
chmod +x install-erpnext-dev.sh
./install-erpnext-dev.sh guided-setup
```

For a custom local hostname:

```bash
SITE_NAME=erp08.test ./install-erpnext-dev.sh guided-setup
```

Use `.test` for local development. Avoid `.local` because it can conflict with mDNS/Avahi.

## Main workflow

```bash
./install-erpnext-dev.sh guided-setup
./install-erpnext-dev.sh verify-access
./install-erpnext-dev.sh local-ssl-wizard
./install-erpnext-dev.sh app-install-wizard
./install-erpnext-dev.sh next-step
```

The guided flow checks storage, installs ERPNext, starts the service, and shows the host `/etc/hosts` command.

## Local HTTPS

```bash
./install-erpnext-dev.sh local-ssl-wizard
```

The wizard supports:

1. Quick self-signed SSL for testing.
2. Trusted local SSL using `mkcert` from the host.
3. SSL status-only checks.

Direct Bench access remains available:

```text
http://VM_IP:8000
http://erp.test:8000
```

## Optional apps

v0.8.19 adds a safer optional app workflow:

```bash
./install-erpnext-dev.sh app-install-wizard
```

The wizard provides:

- Pre-app install checks
- Backup checkpoint prompt before each app
- Recommended one-app-at-a-time flow
- Post-app validation summary
- Rollback guidance

Supported app profiles include Frappe CRM, HRMS, Helpdesk, Telephony, and Insights.

Backup behavior can be controlled with:

```bash
APP_BACKUP_BEFORE_INSTALL=true|false|prompt
```

Default is `prompt`. For disposable test VMs only, you can skip app backup prompts:

```bash
APP_BACKUP_BEFORE_INSTALL=false ./install-erpnext-dev.sh app-install-wizard
```

## Useful commands

```bash
./install-erpnext-dev.sh status
./install-erpnext-dev.sh doctor
./install-erpnext-dev.sh runtime-status
./install-erpnext-dev.sh service-summary
./install-erpnext-dev.sh access
./install-erpnext-dev.sh verify-access
./install-erpnext-dev.sh next-step
./install-erpnext-dev.sh local-ssl-wizard
./install-erpnext-dev.sh app-install-wizard
./install-erpnext-dev.sh app-status
./install-erpnext-dev.sh app-rollback-guide
```

## Storage expansion

The installer can detect common resized/cloned VM storage layouts and offer expansion before installing ERPNext.

```bash
./install-erpnext-dev.sh storage-status
./install-erpnext-dev.sh expand-root-storage
```

Supported automatic cases include common Ubuntu LVM root layouts and direct ext4/XFS root partitions.

## Credentials

Credentials are saved to:

```text
/home/frappe/erpnext-dev-credentials.txt
```

Installer logs are private by default:

```text
/tmp/erpnext-dev-installer-*.log
```

Expected permissions:

```text
-rw-------
```

## Production note

This script is for local developer VMs. Production deployment should use a separate production workflow with a real domain, hardened Nginx, SSL renewal, backups, monitoring, and update strategy.
