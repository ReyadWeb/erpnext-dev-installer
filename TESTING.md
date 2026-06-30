# Testing Guide v0.8.19

## 1. Syntax check

```bash
bash -n install-erpnext-dev.sh
grep -n "SCRIPT_VERSION" install-erpnext-dev.sh
```

Expected:

```text
SCRIPT_VERSION="0.8.19"
```

## 2. Existing VM validation

```bash
./install-erpnext-dev.sh runtime-status
./install-erpnext-dev.sh doctor
./install-erpnext-dev.sh verify-access
./install-erpnext-dev.sh next-step
```

Expected:

- Runtime OK
- Service OK
- Autostart OK when enabled
- Bench web on 8000 OK
- Socket.io on 9000 OK
- Redis queue/cache ports OK

## 3. Optional app wizard menu test

```bash
./install-erpnext-dev.sh app-install-wizard
```

Expected:

- Preflight screen appears.
- Site and bench path are shown.
- Runtime is shown as OK or informational.
- Backup policy is shown.
- Menu lists CRM, HRMS, Insights, Telephony, Helpdesk, custom app, and rollback guide.

Choose Back for a non-destructive menu test.

## 4. App install safety test

For a disposable VM or snapshot, install one app:

```bash
./install-erpnext-dev.sh app-install-wizard
```

Expected:

- The script asks to install the selected app.
- The script offers a database + files backup checkpoint before installing.
- After install, post-app validation is shown.
- `app-status`, `doctor`, and `verify-access` are suggested.

## 5. Backup policy override test

For disposable test VMs only:

```bash
APP_BACKUP_BEFORE_INSTALL=false ./install-erpnext-dev.sh app-install-wizard
```

Expected:

- Backup checkpoint is skipped with a warning.
- App install still requires explicit confirmation.

## 6. Rollback guide test

```bash
./install-erpnext-dev.sh app-rollback-guide
```

Expected:

- Restore-first rollback guidance is shown.
- It does not make system changes.

## 7. Local SSL sanity check

```bash
./install-erpnext-dev.sh ssl-status
./install-erpnext-dev.sh verify-local-ssl
```

Expected:

- Existing v0.8.18 SSL behavior is unchanged.

## 8. Log permissions check

```bash
ls -l /tmp/erpnext-dev-installer-*.log | tail -1
```

Expected:

```text
-rw-------
```
