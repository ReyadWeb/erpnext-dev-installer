# ERPNext Developer Installer v0.8.23

Local developer installer for ERPNext/Frappe on Ubuntu 24.04/26.04 VMs.

## Main workflow

```bash
curl -fsSL https://raw.githubusercontent.com/ReyadWeb/erpnext-dev-installer/main/install-erpnext-dev.sh -o install-erpnext-dev.sh
chmod +x install-erpnext-dev.sh
./install-erpnext-dev.sh setup
```

## Important commands

```bash
./install-erpnext-dev.sh storage-status
./install-erpnext-dev.sh expand-root-storage
./install-erpnext-dev.sh verify-access
./install-erpnext-dev.sh local-ssl-wizard
./install-erpnext-dev.sh app-install-wizard
./install-erpnext-dev.sh doctor
./install-erpnext-dev.sh doctor --plain
./install-erpnext-dev.sh doctor --json
./install-erpnext-dev.sh support-bundle
./install-erpnext-dev.sh next-step
```

## v0.8.23 focus

v0.8.23 adds a redacted support bundle command for safer troubleshooting.

Create a support archive with:

```bash
./install-erpnext-dev.sh support-bundle
```

The command creates an archive like:

```text
erpnext-dev-support-bundle-YYYYMMDD-HHMMSS.tar.gz
```

The bundle includes:

- `doctor-plain.txt`
- `doctor.json`
- `doctor-json-validation.txt`
- `system-summary.txt`
- `service-status.txt`
- `port-status.txt`
- `storage-status.txt`
- `ssl-status.txt`
- `bench-status.txt`
- `recent-errors.txt`
- `manifest.txt`

The support bundle intentionally excludes credential files, private keys, raw `site_config.json` secrets, tokens, and passwords. Bundle text files are also passed through a redaction step before packaging.

Review before sharing:

```bash
tar -tzf /tmp/erpnext-dev-support-bundle-YYYYMMDD-HHMMSS.tar.gz
mkdir -p /tmp/erpnext-support-review
tar -xzf /tmp/erpnext-dev-support-bundle-YYYYMMDD-HHMMSS.tar.gz -C /tmp/erpnext-support-review
```

## Diagnostics

The regular `doctor` command shows the existing full health report:

```bash
./install-erpnext-dev.sh doctor
```

For copy/paste support output without ANSI colors, use:

```bash
./install-erpnext-dev.sh doctor --plain
```

For structured tooling and support-bundle generation, use:

```bash
./install-erpnext-dev.sh doctor --json
```

The plain and JSON diagnostic modes intentionally exclude secrets, passwords, tokens, private keys, and credential file contents. They report paths and presence checks only.

## Local SSL

For quick local HTTPS:

```bash
./install-erpnext-dev.sh local-ssl-wizard
```

Self-signed certificates are useful for testing. For trusted browser SSL, use `mkcert` on the host and install the generated cert/key into the VM.

Typical trusted replacement flow:

```bash
# on the HOST
mkcert -install
mkcert -cert-file erp.test.crt -key-file erp.test.key erp.test VM_IP localhost 127.0.0.1
scp erp.test.crt erp.test.key USER@VM_IP:/tmp/

# inside the VM
./install-erpnext-dev.sh local-ssl-wizard
```

Existing VM cert/key files are backed up before replacement.

## Optional apps

Use the checkpoint workflow:

```bash
./install-erpnext-dev.sh app-install-wizard
```

The wizard shows a preflight, recommends backup checkpoints, installs one optional app at a time, and runs post-app validation.
