# TESTING v0.8.22

## Syntax

```bash
bash -n install-erpnext-dev.sh
grep -n "SCRIPT_VERSION" install-erpnext-dev.sh
```

Expected:

```text
SCRIPT_VERSION="0.8.22"
```


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
```

Expected:

- Diagnostic format flags work before or after the `doctor` action.
- `--json` alone defaults to the doctor action and produces valid JSON.

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
./install-erpnext-dev.sh verify-access
./install-erpnext-dev.sh ssl-status
```
