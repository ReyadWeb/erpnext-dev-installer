# ERPNext Developer Installer v0.7.0 Beta

A menu-driven Bash installer for creating a local ERPNext / Frappe developer VM on Ubuntu 24.04 or Ubuntu 26.04.

This project is intended for local development, learning, evaluation, and repeatable VM setup. It is not a production installer.

## Status

v0.7.0 builds on the verified v0.6.0 public beta and adds VM/networking diagnostics. The full app stack has been tested successfully on a local VM:

| App | Status |
|---|---|
| Frappe | Verified |
| ERPNext | Verified |
| Frappe CRM | Verified |
| Frappe HR / HRMS | Verified |
| Frappe Telephony | Verified |
| Frappe Helpdesk | Verified |
| Frappe Insights | Verified |

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/ReyadWeb/erpnext-dev-installer/main/install-erpnext-dev.sh -o install-erpnext-dev.sh
chmod +x install-erpnext-dev.sh
./install-erpnext-dev.sh
```

Recommended flow:

```bash
./install-erpnext-dev.sh setup
./install-erpnext-dev.sh start
./install-erpnext-dev.sh access
```

## New in v0.7.0

- Added `network-status` command.
- Added `hosts-command` command.
- Added `host-test` command.
- Added `kvm-identify` command.
- Added `ssl-roadmap` command.
- Improved Access submenu.
- Improved Advanced menu networking options.
- Added host-safe KVM VM identification loop that supports VM names with spaces.
- Added future SSL / HTTPS roadmap guidance.

## Common commands

```bash
./install-erpnext-dev.sh status
./install-erpnext-dev.sh doctor
./install-erpnext-dev.sh start
./install-erpnext-dev.sh restart
./install-erpnext-dev.sh stop
./install-erpnext-dev.sh access
./install-erpnext-dev.sh network-status
./install-erpnext-dev.sh list-apps
./install-erpnext-dev.sh app-status
```

## VM and hostname commands

```bash
./install-erpnext-dev.sh access
./install-erpnext-dev.sh hosts-command
./install-erpnext-dev.sh network-status
./install-erpnext-dev.sh host-test
./install-erpnext-dev.sh kvm-identify
./install-erpnext-dev.sh kvm-guide
./install-erpnext-dev.sh multi-env-guide
```

`network-status` shows the VM hostname, primary interface, MAC address, IP address, gateway, direct URL, friendly URL, and the host commands needed to map `erp.test`.

`kvm-identify` prints a host-side libvirt loop that correctly handles VM names with spaces.

## Browser access

Direct IP access:

```text
http://VM_IP:8000
```

Friendly local access:

```text
http://erp.test:8000
```

The friendly URL requires a host `/etc/hosts` entry on your Linux Mint / Ubuntu host:

```bash
sudo sed -i '/[[:space:]]erp\.test$/d' /etc/hosts
echo "VM_IP erp.test" | sudo tee -a /etc/hosts
```

## Optional app library

```bash
./install-erpnext-dev.sh install-crm
./install-erpnext-dev.sh install-hrms
./install-erpnext-dev.sh install-helpdesk
./install-erpnext-dev.sh install-insights
./install-erpnext-dev.sh list-apps
./install-erpnext-dev.sh app-status
```

Helpdesk requires Telephony. The installer handles this dependency automatically.

## Backups and maintenance

```bash
./install-erpnext-dev.sh backup
./install-erpnext-dev.sh backup-files
./install-erpnext-dev.sh list-backups
./install-erpnext-dev.sh maintenance
./install-erpnext-dev.sh migrate
./install-erpnext-dev.sh build
./install-erpnext-dev.sh clear-cache
```

## SSL / HTTPS direction

SSL is planned but not automated in v0.7.0. The future local HTTPS plan is:

```text
Browser HTTPS :443
  -> Nginx reverse proxy inside the VM
    -> Bench web on 127.0.0.1:8000
    -> Socket.io on 127.0.0.1:9000
```

Planned future commands:

```bash
./install-erpnext-dev.sh ssl-status
./install-erpnext-dev.sh local-ssl-guide
./install-erpnext-dev.sh configure-local-ssl
./install-erpnext-dev.sh disable-local-ssl
```

Production SSL should be handled in a separate production track, not mixed into the current developer `bench start` workflow.

## Production warning

This script is for local developer VM use. It does not yet configure a production architecture with Nginx, Supervisor, hardened MariaDB/Redis, firewall rules, SSL renewal, monitoring, or disaster recovery.
