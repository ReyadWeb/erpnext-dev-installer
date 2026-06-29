# Testing v0.8.17

## 1. Syntax check

```bash
bash -n install-erpnext-dev.sh
grep -n "SCRIPT_VERSION" install-erpnext-dev.sh
```

Expected:

```text
SCRIPT_VERSION="0.8.17"
```

## 2. Fresh VM guided setup

```bash
rm -f install-erpnext-dev.sh
curl -fsSL "https://raw.githubusercontent.com/ReyadWeb/erpnext-dev-installer/main/install-erpnext-dev.sh?cache_bust=$(date +%s)" -o install-erpnext-dev.sh
chmod +x install-erpnext-dev.sh
./install-erpnext-dev.sh guided-setup
```

Expected:

- storage expansion is offered before low disk warnings when needed
- custom site name prompt appears
- ERPNext installs successfully
- service/autostart prompts work
- final output points to `verify-access`

## 3. Access verification

Inside the VM:

```bash
./install-erpnext-dev.sh verify-access
./install-erpnext-dev.sh next-step
```

Expected:

- Bench web port is OK
- Socket.io port is OK when service is running
- local direct HTTP returns an HTTP status
- host `/etc/hosts` command is printed

On the host:

```bash
curl -I http://VM_IP:8000
curl -I http://erp.test:8000
```

## 4. Runtime checks

```bash
./install-erpnext-dev.sh runtime-status
./install-erpnext-dev.sh doctor
./install-erpnext-dev.sh service-summary
```

Expected:

- ERPNext service running
- autostart enabled when selected
- ports 8000, 9000, 11000, 13000 listening
- site app checks OK

## 5. Reboot test

```bash
sudo reboot
```

After reboot:

```bash
./install-erpnext-dev.sh runtime-status
./install-erpnext-dev.sh doctor
./install-erpnext-dev.sh verify-access
```

Expected: ERPNext returns to running state automatically when autostart was enabled.

## 6. Log permission check

```bash
ls -l /tmp/erpnext-dev-installer-*.log | tail -1
```

Expected:

```text
-rw-------
```
