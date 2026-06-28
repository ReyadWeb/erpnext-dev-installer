# Testing Guide v0.7.0

## Syntax check

```bash
bash -n install-erpnext-dev.sh
./install-erpnext-dev.sh help
```

## Existing VM regression

```bash
./install-erpnext-dev.sh restart
./install-erpnext-dev.sh doctor
./install-erpnext-dev.sh list-apps
./install-erpnext-dev.sh app-status
```

Expected: all core services and optional apps show OK.

## Networking commands

```bash
./install-erpnext-dev.sh network-status
./install-erpnext-dev.sh hosts-command
./install-erpnext-dev.sh host-test
./install-erpnext-dev.sh kvm-identify
./install-erpnext-dev.sh kvm-guide
./install-erpnext-dev.sh multi-env-guide
./install-erpnext-dev.sh ssl-roadmap
```

Expected:

- `network-status` shows hostname, interface, MAC, IP, gateway, direct URL, friendly URL, and host mapping commands.
- `hosts-command` prints only the host `/etc/hosts` update commands.
- `host-test` prints host-side `getent` and `curl` tests.
- `kvm-identify` prints a MAC-based VM lookup command that supports VM names with spaces.
- `ssl-roadmap` prints planning guidance only and does not change the system.

## Fresh VM regression

```bash
curl -fsSL https://raw.githubusercontent.com/ReyadWeb/erpnext-dev-installer/main/install-erpnext-dev.sh -o install-erpnext-dev.sh
chmod +x install-erpnext-dev.sh
./install-erpnext-dev.sh setup
./install-erpnext-dev.sh start
./install-erpnext-dev.sh doctor
./install-erpnext-dev.sh network-status
```

## App Library regression

```bash
./install-erpnext-dev.sh install-crm
./install-erpnext-dev.sh install-hrms
./install-erpnext-dev.sh install-helpdesk
./install-erpnext-dev.sh install-insights
./install-erpnext-dev.sh list-apps
./install-erpnext-dev.sh doctor
```

Expected app stack:

```text
frappe
erpnext
crm
hrms
telephony
helpdesk
insights
```

## KVM host validation

On the host, compare the MAC from `network-status` with:

```bash
virsh list --all --name
target_mac="PASTE_MAC_HERE"
while IFS= read -r vm; do
  [ -n "$vm" ] || continue
  virsh domiflist "$vm" | grep -qi "$target_mac" && echo "Matched VM: $vm"
done < <(virsh list --all --name)
```
