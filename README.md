# ERPNext Developer Installer v0.8.17

Developer VM installer for Frappe v16 and ERPNext v16 on Ubuntu 24.04 / 26.04 LTS.

This release builds on the v0.8.16 stable baseline and adds a guided setup flow so new users can follow the correct order: storage, site name, ERPNext installation, host access, and verification.

## Quick start

Inside the ERPNext VM:

```bash
curl -fsSL "https://raw.githubusercontent.com/ReyadWeb/erpnext-dev-installer/main/install-erpnext-dev.sh?cache_bust=$(date +%s)" -o install-erpnext-dev.sh
chmod +x install-erpnext-dev.sh
./install-erpnext-dev.sh guided-setup
```

The guided setup runs the safe installer flow and then prints access verification steps.

## Recommended workflow

```bash
./install-erpnext-dev.sh guided-setup
./install-erpnext-dev.sh verify-access
./install-erpnext-dev.sh next-step
```

The installer handles:

- Ubuntu 24.04 / 26.04 validation
- VM root storage expansion prompt when needed
- custom local site names, such as `erp.test` or `erp08.test`
- ERPNext v16 installation
- systemd service creation
- optional autostart on boot
- runtime and doctor checks
- local SSL tooling
- optional app installation workflows
- private installer logs

## Custom local site name

Use a unique `.test` hostname for each local VM:

```bash
SITE_NAME=erp08.test ./install-erpnext-dev.sh guided-setup
```

Avoid `.local` because it can conflict with mDNS/Avahi and tools such as LocalWP.

## Host access

After setup, add the friendly hostname on the Linux Mint host, not inside the VM:

```bash
echo "VM_IP erp.test" | sudo tee -a /etc/hosts
```

Then verify:

```bash
./install-erpnext-dev.sh verify-access
```

Host-side tests:

```bash
curl -I http://VM_IP:8000
curl -I http://erp.test:8000
```

## Useful commands

```bash
./install-erpnext-dev.sh next-step
./install-erpnext-dev.sh status
./install-erpnext-dev.sh runtime-status
./install-erpnext-dev.sh doctor
./install-erpnext-dev.sh access
./install-erpnext-dev.sh verify-access
./install-erpnext-dev.sh storage-status
./install-erpnext-dev.sh local-ssl-guide
./install-erpnext-dev.sh app-library
```

## Security notes

Generated credentials are not printed into the terminal log. They are saved to:

```text
/home/frappe/erpnext-dev-credentials.txt
```

The credentials file is owned by the `frappe` user and uses restrictive permissions. Installer logs are created with private `600` permissions.

## Release status

v0.8.17 is a guided workflow patch on top of the v0.8.16 security/reliability baseline.
