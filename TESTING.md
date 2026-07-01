# TESTING v0.8.23

## Syntax

```bash
chmod +x install-erpnext-dev.sh
bash -n install-erpnext-dev.sh
grep -n "SCRIPT_VERSION" install-erpnext-dev.sh
```

Expected:

```text
SCRIPT_VERSION="0.8.23"
```

## Help command

```bash
./install-erpnext-dev.sh help | grep -E "doctor --plain|doctor --json|support-bundle"
```

Expected:

- Help lists `doctor --plain`.
- Help lists `doctor --json`.
- Help lists `support-bundle`.

## Doctor plain/json diagnostics

```bash
./install-erpnext-dev.sh doctor --plain
./install-erpnext-dev.sh doctor --json > /tmp/erpnext-doctor.json
python3 -m json.tool /tmp/erpnext-doctor.json >/tmp/erpnext-doctor.pretty.json
```

Expected:

- `doctor --plain` prints a readable diagnostics report without ANSI color codes.
- `doctor --json` prints valid JSON.
- Both modes include OS, Python, Node, MariaDB, Redis, Bench, site, service, port, storage, SSL, and optional app status summaries.
- Neither mode prints passwords, tokens, private keys, raw credential contents, or raw site config secrets.

## Doctor argument order

```bash
./install-erpnext-dev.sh --plain doctor
./install-erpnext-dev.sh --json doctor > /tmp/erpnext-doctor-order.json
python3 -m json.tool /tmp/erpnext-doctor-order.json >/dev/null
./install-erpnext-dev.sh --json > /tmp/erpnext-doctor-default.json
python3 -m json.tool /tmp/erpnext-doctor-default.json >/dev/null
```

Expected:

- Diagnostic format flags work before or after the `doctor` action.
- `--json` alone defaults to the doctor action and produces valid JSON.

## Support bundle

```bash
./install-erpnext-dev.sh support-bundle
```

Expected:

- Command creates `/tmp/erpnext-dev-support-bundle-YYYYMMDD-HHMMSS.tar.gz` unless `SUPPORT_BUNDLE_DIR` is overridden.
- Command prints the final archive path.
- Archive permissions are private, usually `600`.
- Temporary bundle directory is removed after packaging.

Inspect the archive:

```bash
BUNDLE="$(ls -1t /tmp/erpnext-dev-support-bundle-*.tar.gz | head -1)"
tar -tzf "$BUNDLE"
mkdir -p /tmp/erpnext-support-review
rm -rf /tmp/erpnext-support-review/*
tar -xzf "$BUNDLE" -C /tmp/erpnext-support-review
find /tmp/erpnext-support-review -type f -maxdepth 2 -print
python3 -m json.tool /tmp/erpnext-support-review/*/doctor.json >/dev/null
```

Expected archive files:

```text
manifest.txt
doctor-plain.txt
doctor.json
doctor-json-validation.txt
system-summary.txt
service-status.txt
port-status.txt
storage-status.txt
ssl-status.txt
bench-status.txt
recent-errors.txt
```

Expected safety behavior:

- Archive does not include `erpnext-dev-credentials.txt`.
- Archive does not include raw `site_config.json`.
- Archive does not include `.key` files or TLS private keys.
- Archive does not include raw database credentials.
- Included text files are redacted before packaging.

Optional redaction smoke test after extraction:

```bash
grep -RInE "password[=:]|token[=:]|secret[=:]|api[_-]?key[=:]|BEGIN .*PRIVATE KEY" /tmp/erpnext-support-review || true
```

Expected:

- No unredacted secrets should appear.
- Safe explanatory text such as “passwords are excluded” may still appear.

## Support alias

```bash
./install-erpnext-dev.sh support
```

Expected:

- Same behavior as `support-bundle`.

## Next-step regression test after storage expansion

On a VM whose root filesystem is already expanded:

```bash
./install-erpnext-dev.sh storage-status
./install-erpnext-dev.sh next-step
```

Expected storage status:

```text
Expansion OK not needed
```

Expected `next-step` behavior:

- It should show storage as OK / not needing expansion.
- It should recommend the next real workflow step: setup, start, enable autostart, local SSL, or optional app wizard.
- It should not recommend `expand-root-storage` unless actual VG free space or growable disk tail space exists.

## Fresh cloned VM storage test

On a cloned VM where the virtual disk is larger than the root partition:

```bash
./install-erpnext-dev.sh storage-status
./install-erpnext-dev.sh expand-root-storage
./install-erpnext-dev.sh storage-status
df -h /
```

Expected before expansion:

```text
Expansion WARN recommended
```

Expected after expansion:

```text
Expansion OK not needed
```

## Local SSL replacement test

With local HTTPS already configured using a self-signed certificate:

```bash
./install-erpnext-dev.sh ssl-status
./install-erpnext-dev.sh local-ssl-wizard
```

Expected:

- `ssl-status` prints a certificate trust hint.
- `local-ssl-wizard` detects that HTTPS is already configured.
- The wizard offers to keep the current SSL, replace/install mkcert files from `/tmp`, regenerate self-signed SSL, or show status only.

For the trusted replacement path:

```bash
# on HOST
mkcert -install
mkcert -cert-file erp.test.crt -key-file erp.test.key erp.test VM_IP localhost 127.0.0.1
scp erp.test.crt erp.test.key USER@VM_IP:/tmp/

# inside VM
./install-erpnext-dev.sh local-ssl-wizard
./install-erpnext-dev.sh ssl-status
```

Expected:

- Existing VM cert/key files are backed up.
- Cert/key permissions are enforced as root:root 644/600.
- Nginx is tested and reloaded when SSL is already enabled.

## Runtime validation

```bash
./install-erpnext-dev.sh runtime-status
./install-erpnext-dev.sh doctor
./install-erpnext-dev.sh doctor --plain
./install-erpnext-dev.sh doctor --json
./install-erpnext-dev.sh support-bundle
./install-erpnext-dev.sh verify-access
./install-erpnext-dev.sh ssl-status
```
