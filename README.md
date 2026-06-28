# ERPNext Developer Installer v0.8.5

Local ERPNext / Frappe developer VM installer for Ubuntu 24.04 / 26.04.

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/ReyadWeb/erpnext-dev-installer/main/install-erpnext-dev.sh -o install-erpnext-dev.sh
chmod +x install-erpnext-dev.sh
./install-erpnext-dev.sh setup
```

During interactive setup, the installer asks for a local site name. Press Enter to use the default:

```text
erp.test
```

## Custom local site name

Use a unique `.test` hostname for each ERPNext VM.

Good examples:

```text
erp.test
erp107.test
school.test
client-a.test
```

Avoid `.local` because Linux uses `.local` for mDNS/Avahi.

You can provide the site name non-interactively:

```bash
SITE_NAME=erp107.test ./install-erpnext-dev.sh setup
```

The selected site name is saved to:

```text
/home/frappe/erpnext-dev-config.env
```

Future commands reuse the saved name automatically.

## Host /etc/hosts setup

After setup, run this inside the VM:

```bash
./install-erpnext-dev.sh hosts-command
```

Then run the printed command on your Linux host. It will look like:

```bash
sudo sed -i '/[[:space:]]erp107\.test$/d' /etc/hosts
echo "192.168.122.107 erp107.test" | sudo tee -a /etc/hosts
```

Then test from the host:

```bash
curl -I http://erp107.test:8000
```

## Useful commands

```bash
./install-erpnext-dev.sh environment-check
./install-erpnext-dev.sh site-config
./install-erpnext-dev.sh doctor
./install-erpnext-dev.sh runtime-status
./install-erpnext-dev.sh service-summary
./install-erpnext-dev.sh list-apps
./install-erpnext-dev.sh app-library
```

## Optional app library

Supported app profiles:

```bash
./install-erpnext-dev.sh install-crm
./install-erpnext-dev.sh install-hrms
./install-erpnext-dev.sh install-helpdesk
./install-erpnext-dev.sh install-insights
```

Helpdesk installs Telephony as a dependency.

## Local HTTPS

For quick self-signed local HTTPS inside the VM:

```bash
./install-erpnext-dev.sh create-self-signed-local-cert
./install-erpnext-dev.sh configure-local-ssl
./install-erpnext-dev.sh verify-local-ssl
```

Expected URLs:

```text
http://SITE_NAME:8000   direct Bench access
https://SITE_NAME       Nginx local HTTPS reverse proxy
```

For browser-trusted HTTPS, use:

```bash
./install-erpnext-dev.sh mkcert-guide
./install-erpnext-dev.sh browser-trust-guide
```

## Host/VM safety

v0.8.4+ includes a guard that blocks VM-only SSL actions when they are accidentally run on the Linux host instead of inside the ERPNext VM.

Check where you are:

```bash
./install-erpnext-dev.sh environment-check
```

## Development status

v0.8.5 is a beta development-VM release. It is not a production installer.

Production should be a separate future track, likely `install-erpnext-prod.sh`.
