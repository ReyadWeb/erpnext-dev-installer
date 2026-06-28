# Testing — v0.8.4

## Syntax

```bash
bash -n install-erpnext-dev.sh
./install-erpnext-dev.sh help
```

## Host-side safety test

Run on the Linux Mint host:

```bash
./install-erpnext-dev.sh environment-check
./install-erpnext-dev.sh ssl-status
./install-erpnext-dev.sh configure-local-ssl
./install-erpnext-dev.sh install-local-ssl-cert
```

Expected:

- `environment-check` shows ERPNext VM context is not detected.
- VM-only SSL commands are blocked before sudo work.
- Output explains that the command must run inside the ERPNext VM.

## VM-side SSL test

Run inside the ERPNext VM:

```bash
./install-erpnext-dev.sh environment-check
./install-erpnext-dev.sh ssl-status
./install-erpnext-dev.sh verify-local-ssl
./install-erpnext-dev.sh doctor
```

Expected:

- ERPNext VM context detected.
- Nginx/cert/ports are reported correctly.
- Doctor remains green.

## Host HTTPS tests

Run on the host:

```bash
curl -I http://erp.test
curl -kI https://erp.test
curl -I http://erp.test:8000
```

Expected:

- `http://erp.test` redirects to HTTPS.
- `https://erp.test` returns 200 with `-k` for self-signed certs.
- `http://erp.test:8000` remains direct Bench fallback.
