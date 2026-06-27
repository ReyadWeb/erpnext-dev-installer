# ERPNext Developer Installer

A simple developer installer for setting up a local Frappe + ERPNext environment on Ubuntu.

This project is intended for developers, testers, and lab environments who want to quickly install ERPNext in a local VM or development machine.

## Purpose

This installer automates the setup of:

* Frappe Framework
* ERPNext
* Frappe Bench
* MariaDB
* Redis
* Node.js
* Yarn
* Python
* Local ERPNext development site

Default local site:

```text
erp.test
```

Default development command:

```bash
bench start
```

## Target Environment

Recommended environment:

```text
OS: Ubuntu 26.04 LTS
Use case: Local development / KVM VM / test environment
Mode: Development, not production
```

This script is not intended for production servers.

## Repository Contents

```text
erpnext-dev-installer/
├── install-erpnext-dev.sh
├── README.md
├── LICENSE
└── .gitignore
```

## Quick Start

Clone the repository:

```bash
git clone https://github.com/ReyadWeb/erpnext-dev-installer.git
cd erpnext-dev-installer
```

Make the installer executable:

```bash
chmod +x install-erpnext-dev.sh
```

Run the installer:

```bash
./install-erpnext-dev.sh
```

## Optional Configuration

You can override defaults using environment variables:

```bash
SITE_NAME=erp.test \
FRAPPE_USER=frappe \
ADMIN_PASSWORD='ChangeThisAdminPassword' \
./install-erpnext-dev.sh
```

Common variables:

| Variable         | Default            | Purpose                        |
| ---------------- | ------------------ | ------------------------------ |
| `SITE_NAME`      | `erp.test`         | Local Frappe/ERPNext site name |
| `FRAPPE_USER`    | `frappe`           | Linux user used for Bench      |
| `BENCH_NAME`     | `frappe-bench`     | Bench folder name              |
| `FRAPPE_BRANCH`  | `version-16`       | Frappe branch                  |
| `ERPNEXT_BRANCH` | `version-16`       | ERPNext branch                 |
| `ADMIN_PASSWORD` | Generated if empty | ERPNext Administrator password |

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

Open ERPNext in your browser:

```text
http://erp.test:8000
```

Login:

```text
Username: Administrator
Password: check ~/erpnext-dev-credentials.txt
```

## Hostname Setup

If you are running ERPNext inside a KVM VM, add the VM IP to your host machine’s `/etc/hosts` file.

Example:

```text
192.168.122.36 erp.test
```

Then open:

```text
http://erp.test:8000
```

## KVM Fixed IP Recommendation

For KVM/libvirt users, it is recommended to reserve a fixed IP for the VM using libvirt DHCP reservation.

Example target:

```text
192.168.122.36 erp.test
```

This avoids changing `/etc/hosts` every time the VM gets a new IP.

## Development Notes

This installer uses development mode.

To start ERPNext:

```bash
bench start
```

Keep the terminal open while using ERPNext.

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

## Important Safety Notes

Do not commit generated credentials.

The installer may generate local credentials and save them in:

```text
~/erpnext-dev-credentials.txt
```

Files like credentials, logs, and `.env` files should stay out of Git.

## Troubleshooting

### ERPNext install fails with Redis Queue error

If you see:

```text
Error 111 connecting to 127.0.0.1:11000. Connection refused.
```

Start Bench services in one terminal:

```bash
bench start
```

Then retry the install command in another terminal.

### Browser cannot open erp.test

Check that the hostname resolves:

```bash
getent hosts erp.test
```

Expected:

```text
192.168.122.36 erp.test
```

If it does not resolve, update your host machine’s `/etc/hosts`.

### Check VM IP

Inside the VM:

```bash
hostname -I
```

### Check installed apps

```bash
bench --site erp.test list-apps
```

Expected:

```text
frappe
erpnext
```

## License

This project is licensed under the GPL-3.0 license.


