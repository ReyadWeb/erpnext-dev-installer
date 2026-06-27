# ERPNext Developer Installer

A simple developer installer for setting up a local **Frappe + ERPNext** development environment on Ubuntu.

This project is intended for developers, testers, lab environments, and local VM setups where you want a fast way to install ERPNext for development or evaluation.

> This installer is for **development environments only**.
> Do **not** use it as-is for production servers.

---

## What This Installer Does

The script automates the setup of:

* Frappe Framework
* ERPNext
* Frappe Bench
* MariaDB
* Redis
* Node.js
* Yarn
* Python
* Local ERPNext development site

Default site name:

```text
erp.test
```

Default start command:

```bash
bench start
```

---

## Target Environment

Recommended environment:

```text
OS: Ubuntu 26.04 LTS
Use case: Local development / KVM VM / test environment
Mode: Development, not production
```

Recommended VM resources:

```text
CPU: 4 cores minimum
RAM: 8 GB minimum
Disk: 60 GB minimum
Network: NAT or bridged
```

This installer is designed for a **fresh Ubuntu Server VM**.

---

## Important: Run Inside the Ubuntu VM

Run this installer inside the target Ubuntu Server VM, **not on your Linux host machine**.

For example:

```text
Correct:
Ubuntu Server VM → run installer here

Incorrect:
Linux Mint / desktop host → do not run installer here
```

The script intentionally exits if it detects an unsupported operating system.

---

## Repository Contents

```text
erpnext-dev-installer/
├── install-erpnext-dev.sh
├── README.md
├── LICENSE
└── .gitignore
```

---

## One-Command Install

Run this inside a fresh Ubuntu Server development VM:

```bash
sudo apt update && sudo apt install -y curl ca-certificates && curl -fsSL https://raw.githubusercontent.com/ReyadWeb/erpnext-dev-installer/main/install-erpnext-dev.sh -o install-erpnext-dev.sh && chmod +x install-erpnext-dev.sh && ./install-erpnext-dev.sh
```

---

## One-Command Install With Custom Values

Example:

```bash
sudo apt update && sudo apt install -y curl ca-certificates && curl -fsSL https://raw.githubusercontent.com/ReyadWeb/erpnext-dev-installer/main/install-erpnext-dev.sh -o install-erpnext-dev.sh && chmod +x install-erpnext-dev.sh && SITE_NAME=erp.test ADMIN_PASSWORD='ChangeThisAdminPassword' ./install-erpnext-dev.sh
```

---

## Safer Manual Install

Clone the repository:

```bash
git clone https://github.com/ReyadWeb/erpnext-dev-installer.git
cd erpnext-dev-installer
```

Make the installer executable:

```bash
chmod +x install-erpnext-dev.sh
```

Optionally review the script before running it:

```bash
less install-erpnext-dev.sh
```

Run the installer:

```bash
./install-erpnext-dev.sh
```

---

## Optional Configuration

You can override defaults using environment variables:

```bash
SITE_NAME=erp.test \
FRAPPE_USER=frappe \
ADMIN_PASSWORD='ChangeThisAdminPassword' \
./install-erpnext-dev.sh
```

Common variables:

| Variable            | Default            | Purpose                              |
| ------------------- | ------------------ | ------------------------------------ |
| `SITE_NAME`         | `erp.test`         | Local Frappe/ERPNext site name       |
| `FRAPPE_USER`       | `frappe`           | Linux user used for Bench            |
| `BENCH_NAME`        | `frappe-bench`     | Bench folder name                    |
| `FRAPPE_BRANCH`     | `version-16`       | Frappe branch                        |
| `ERPNEXT_BRANCH`    | `version-16`       | ERPNext branch                       |
| `ADMIN_PASSWORD`    | Generated if empty | ERPNext Administrator password       |
| `DB_ADMIN_USER`     | `frappe_db_admin`  | MariaDB admin user created for Bench |
| `DB_ADMIN_PASSWORD` | Generated if empty | MariaDB admin password               |

---

## After Installation

Switch to the Frappe user:

```bash
su - frappe
```

Go to the bench folder:

```bash
cd ~/frappe/frappe-bench
```

Start ERPNext:

```bash
bench start
```

Keep this terminal open while using ERPNext.

Open ERPNext in your browser:

```text
http://erp.test:8000
```

Login:

```text
Username: Administrator
Password: check ~/erpnext-dev-credentials.txt
```

The credentials file is created inside the Frappe user's home directory:

```text
/home/frappe/erpnext-dev-credentials.txt
```

---

## Hostname Setup

If ERPNext is running inside a KVM VM, add the VM IP to your **host machine's** `/etc/hosts` file.

Example:

```text
192.168.122.36 erp.test
```

Then open:

```text
http://erp.test:8000
```

To find the VM IP from inside the VM:

```bash
hostname -I
```

To verify hostname resolution from your host machine:

```bash
getent hosts erp.test
```

Expected example:

```text
192.168.122.36 erp.test
```

---

## KVM Fixed IP Recommendation

For KVM/libvirt users, it is recommended to reserve a fixed IP for the VM using a libvirt DHCP reservation.

Example target:

```text
192.168.122.36 erp.test
```

This avoids changing `/etc/hosts` every time the VM receives a new IP address.

Example workflow on the host machine:

```bash
virsh list --all
virsh domiflist "YOUR_VM_NAME"
```

Then reserve the IP using the VM MAC address:

```bash
sudo virsh net-update default add ip-dhcp-host "<host mac='YOUR_VM_MAC' name='erpnext-dev' ip='192.168.122.36'/>" --live --config
```

Restart the VM after adding the reservation.

---

## Development Notes

This installer uses Frappe development mode.

To start ERPNext:

```bash
su - frappe
cd ~/frappe/frappe-bench
bench start
```

Useful commands:

```bash
bench --site erp.test list-apps
bench --site erp.test migrate
bench build
bench --site erp.test clear-cache
bench --site erp.test backup
```

Expected installed apps:

```text
frappe
erpnext
```

---

## Updating ERPNext

From the bench folder:

```bash
su - frappe
cd ~/frappe/frappe-bench
bench update
```

For local development, always consider taking a VM snapshot before major updates.

---

## Backups

Create a site backup:

```bash
su - frappe
cd ~/frappe/frappe-bench
bench --site erp.test backup
```

Backups are usually stored under:

```text
~/frappe/frappe-bench/sites/erp.test/private/backups/
```

---

## Uninstall / Reset

For a simple development reset, rename the bench folder instead of deleting it immediately:

```bash
su - frappe
cd ~
mv ~/frappe ~/frappe-backup-$(date +%Y%m%d-%H%M%S)
```

For the cleanest test, use a fresh VM or roll back to a KVM snapshot.

---

## Important Safety Notes

Do not commit generated credentials.

The installer may generate credentials and save them in:

```text
~/erpnext-dev-credentials.txt
```

Files like credentials, logs, database dumps, and `.env` files should stay out of Git.

This repository's `.gitignore` should include:

```gitignore
*.log
.env
*.env
erpnext-dev-credentials.txt
credentials.txt
secrets.txt
*.sql
*.sql.gz
.DS_Store
```

---

## Troubleshooting

### Installer exits with unsupported OS

Example:

```text
ERROR: This script is designed for Ubuntu. Detected: Linux Mint
```

This means the script was probably run on the host machine instead of the Ubuntu VM.

SSH into the Ubuntu VM first, then run the installer there.

---

### ERPNext install fails with Redis Queue error

If you see:

```text
Error 111 connecting to 127.0.0.1:11000. Connection refused.
```

Start Bench services in one terminal:

```bash
su - frappe
cd ~/frappe/frappe-bench
bench start
```

Then retry the failed command in another terminal.

---

### Browser cannot open erp.test

Check that the hostname resolves from your host machine:

```bash
getent hosts erp.test
```

Expected example:

```text
192.168.122.36 erp.test
```

If it does not resolve, update the host machine's `/etc/hosts` file.

---

### Check VM IP

Inside the VM:

```bash
hostname -I
```

---

### Check installed apps

```bash
su - frappe
cd ~/frappe/frappe-bench
bench --site erp.test list-apps
```

Expected:

```text
frappe
erpnext
```

---

### Start ERPNext manually

```bash
su - frappe
cd ~/frappe/frappe-bench
bench start
```

Then open:

```text
http://erp.test:8000
```

---

## License

This project is licensed under the GPL-3.0 license.

