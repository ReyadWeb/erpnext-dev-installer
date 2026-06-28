# Testing Guide v0.8.1

## Syntax and help

```bash
bash -n install-erpnext-dev.sh
./install-erpnext-dev.sh help
```

Expected:

- Bash syntax passes.
- Help output includes `ssl-status`, `local-ssl-guide`, `create-self-signed-local-cert`, `configure-local-ssl`, and `disable-local-ssl`.

## Existing environment regression

```bash
./install-erpnext-dev.sh network-status
./install-erpnext-dev.sh app-status
./install-erpnext-dev.sh restart
./install-erpnext-dev.sh doctor
```

Expected:

- ERPNext service running.
- Ports 8000, 9000, 11000, 13000 listening.
- Optional apps show installed if previously installed.

## SSL status before configuration

```bash
./install-erpnext-dev.sh ssl-status
./install-erpnext-dev.sh local-ssl-guide
```

Expected before cert/key are installed:

- SSL certificate/key warnings.
- HTTPS port 443 may be not listening.
- Guide prints self-signed and mkcert workflows.

## Quick self-signed local SSL test

Inside the VM:

```bash
./install-erpnext-dev.sh create-self-signed-local-cert
./install-erpnext-dev.sh configure-local-ssl
./install-erpnext-dev.sh ssl-status
```

From the host:

```bash
curl -I http://erp.test
curl -kI https://erp.test
curl -I http://erp.test:8000
```

Expected:

- `http://erp.test` redirects to `https://erp.test/`.
- `https://erp.test` returns the ERPNext login page with `curl -k`.
- `http://erp.test:8000` still returns the ERPNext login page directly from Bench.
- Browser may warn because self-signed certs are not trusted by default.

## Trusted mkcert local SSL test

On the host machine, generate a local certificate with mkcert:

```bash
mkcert -install
mkcert -cert-file erp.test.crt -key-file erp.test.key erp.test VM_IP localhost 127.0.0.1
scp erp.test.crt erp.test.key USER@VM_IP:/tmp/
```

Inside the VM:

```bash
sudo mkdir -p /etc/erpnext-dev-ssl
sudo cp /tmp/erp.test.crt /etc/erpnext-dev-ssl/erp.test.crt
sudo cp /tmp/erp.test.key /etc/erpnext-dev-ssl/erp.test.key
sudo chown root:root /etc/erpnext-dev-ssl/erp.test.crt /etc/erpnext-dev-ssl/erp.test.key
sudo chmod 644 /etc/erpnext-dev-ssl/erp.test.crt
sudo chmod 600 /etc/erpnext-dev-ssl/erp.test.key

./install-erpnext-dev.sh configure-local-ssl
./install-erpnext-dev.sh ssl-status
```

From the host:

```bash
curl -I http://erp.test
curl -I https://erp.test
curl -I http://erp.test:8000
```

Expected:

- Nginx config test passes.
- Nginx service starts/reloads.
- Port 443 listens.
- `https://erp.test` opens in browser without a warning if mkcert CA trust is installed correctly on that host browser.
- `http://erp.test:8000` still works.

## Disable SSL test

```bash
./install-erpnext-dev.sh disable-local-ssl
./install-erpnext-dev.sh ssl-status
```

Expected:

- Nginx site symlink removed.
- Direct Bench access remains available.
