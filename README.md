# ERPNext Developer Installer v0.9.1

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
./install-erpnext-dev.sh app-compatibility
./install-erpnext-dev.sh production-readiness
./install-erpnext-dev.sh production-plan
./install-erpnext-dev.sh doctor
./install-erpnext-dev.sh doctor --plain
./install-erpnext-dev.sh doctor --json
./install-erpnext-dev.sh support-bundle
./install-erpnext-dev.sh next-step
```

## v0.9.1 focus

v0.9.1 adds structured production domain planning and fixes production readiness install detection. It does not convert the developer VM into production; it classifies the environment, shows the planning checklist, and provides DNS/domain guidance before any production hardening or migration work.

Run:

```bash
./install-erpnext-dev.sh production-readiness
./install-erpnext-dev.sh production-plan
./install-erpnext-dev.sh production-domain-plan
```

`production-readiness` checks CPU, RAM, disk, install/runtime/service state, production domain configuration, local SSL assumptions, and backup readiness. It classifies the VM as dev-only, production candidate, or not recommended.

`production-plan` prints the planning checklist for architecture, domain, DNS/network path, SSL, backups, and hardening.

`production-domain-plan` prints a structured DNS/domain plan, including the local `.test` site, planned production domain, recommended A record, provider notes, and warnings when the current VM IP is private/NAT.

## v0.8.24 optional app compatibility

Check the optional app matrix with:

```bash
./install-erpnext-dev.sh app-compatibility
```

The compatibility check shows:

- detected Frappe branch
- detected ERPNext branch
- target optional app branch
- current app install/download state
- compatibility status and recommendation

The app install wizard also shows a compact compatibility snapshot before the menu, and each app install shows a detailed preflight card before confirmation. Moving branches such as `main` and experimental branches such as `develop` are clearly marked with warnings.

Branch overrides remain available:

```bash
CRM_BRANCH=main
HRMS_BRANCH=version-16
HELPDESK_BRANCH=main
TELEPHONY_BRANCH=develop
INSIGHTS_BRANCH=main
```

## Support bundle

Create a redacted support archive with:

```bash
./install-erpnext-dev.sh support-bundle
```

The command creates an archive like:

```text
erpnext-dev-support-bundle-YYYYMMDD-HHMMSS.tar.gz
```

The bundle includes `doctor-plain.txt`, `doctor.json`, JSON validation, system/service/port/storage/SSL/Bench status, recent errors, and a manifest.

The support bundle intentionally excludes credential files, private keys, raw `site_config.json` secrets, tokens, and passwords. Bundle text files are also passed through a redaction step before packaging.

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
./install-erpnext-dev.sh app-compatibility
./install-erpnext-dev.sh app-install-wizard
```

The wizard shows a preflight, a compatibility snapshot, backup checkpoint prompts, one-app-at-a-time installation, and post-app validation.
