# ERPNext Developer Installer v0.8.4

Beta-quality local developer installer for ERPNext/Frappe on an Ubuntu VM.

## Status

v0.8.4 is a safety and SSL workflow hardening release. It keeps the v0.8.x local HTTPS reverse proxy direction and adds stronger protection against running VM-only SSL commands on the Linux Mint host by mistake.

## Key workflows

### Developer VM setup

```bash
curl -fsSL https://raw.githubusercontent.com/ReyadWeb/erpnext-dev-installer/main/install-erpnext-dev.sh -o install-erpnext-dev.sh
chmod +x install-erpnext-dev.sh
./install-erpnext-dev.sh setup
```

### Basic operation

```bash
./install-erpnext-dev.sh start
./install-erpnext-dev.sh status
./install-erpnext-dev.sh access
./install-erpnext-dev.sh doctor
```

### Optional app library

Verified app stack in testing:

| App | Status |
| --- | --- |
| ERPNext | Verified |
| Frappe CRM | Verified |
| Frappe HR / HRMS | Verified |
| Frappe Telephony | Verified as Helpdesk dependency |
| Frappe Helpdesk | Verified |
| Frappe Insights | Verified |

### Local HTTPS

Local HTTPS is optional and uses Nginx inside the VM:

```text
Browser HTTPS :443
  -> Nginx inside VM
    -> Bench web 127.0.0.1:8000
    -> Socket.io 127.0.0.1:9000
```

The direct developer fallback remains available:

```text
http://erp.test:8000
http://VM_IP:8000
```

## Host vs VM safety rule

Run these commands on the **Linux Mint host**:

```bash
mkcert -install
mkcert -cert-file erp.test.crt -key-file erp.test.key erp.test VM_IP
scp erp.test.crt test@VM_IP:/tmp/erp.test.crt
scp erp.test.key test@VM_IP:/tmp/erp.test.key
curl -I http://erp.test
curl -kI https://erp.test
```

Run these commands **inside the ERPNext VM**:

```bash
./install-erpnext-dev.sh ssl-status
./install-erpnext-dev.sh install-local-ssl-cert
./install-erpnext-dev.sh configure-local-ssl
./install-erpnext-dev.sh verify-local-ssl
```

If unsure, run:

```bash
./install-erpnext-dev.sh environment-check
```

v0.8.4 blocks VM-only SSL actions when the ERPNext VM context is not detected, preventing accidental changes to the host.

## Important limitation

This is a local developer VM installer. It is not a production installer yet. Production should be handled by a separate production track with domain/DNS, Nginx/Supervisor production mode, firewall, backups, monitoring, and SSL renewal.
