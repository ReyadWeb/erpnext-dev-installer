# TESTING v0.8.5

## Fresh VM custom-site test

Inside a fresh VM:

```bash
curl -fsSL https://raw.githubusercontent.com/ReyadWeb/erpnext-dev-installer/main/install-erpnext-dev.sh -o install-erpnext-dev.sh
chmod +x install-erpnext-dev.sh
SITE_NAME=erp107.test ./install-erpnext-dev.sh setup
```

After install:

```bash
./install-erpnext-dev.sh site-config
./install-erpnext-dev.sh environment-check
./install-erpnext-dev.sh doctor
./install-erpnext-dev.sh runtime-status
./install-erpnext-dev.sh service-summary
```

Expected:

```text
Current site: erp107.test
Site app: frappe OK
Site app: erpnext OK
Bench web: OK port 8000 listening
Socket.io: OK port 9000 listening
Autostart: OK Enabled
```

## Host access test

On the Linux host, use the `/etc/hosts` command printed by:

```bash
./install-erpnext-dev.sh hosts-command
```

Then test:

```bash
getent hosts erp107.test
curl -I http://erp107.test:8000
```

Expected:

```text
HTTP/1.1 200 OK
```

## Saved config test

Inside the VM, run without `SITE_NAME=`:

```bash
./install-erpnext-dev.sh site-config
./install-erpnext-dev.sh doctor
```

Expected: commands still use `erp107.test` from `/home/frappe/erpnext-dev-config.env`.

## Validation rejection tests

These should fail before install:

```bash
SITE_NAME=https://erp.test ./install-erpnext-dev.sh setup
SITE_NAME=erp.test:8000 ./install-erpnext-dev.sh setup
SITE_NAME='erp test' ./install-erpnext-dev.sh setup
SITE_NAME=erp.local ./install-erpnext-dev.sh setup
```

## SSL test with custom site name

Inside the VM:

```bash
./install-erpnext-dev.sh create-self-signed-local-cert
./install-erpnext-dev.sh configure-local-ssl
./install-erpnext-dev.sh verify-local-ssl
```

On the Linux host:

```bash
curl -I http://erp107.test
curl -kI https://erp107.test
curl -I http://erp107.test:8000
```

Expected:

```text
http://erp107.test        -> 301 redirect to https://erp107.test/
https://erp107.test       -> 200 OK through Nginx
http://erp107.test:8000   -> 200 OK direct Bench fallback
```
