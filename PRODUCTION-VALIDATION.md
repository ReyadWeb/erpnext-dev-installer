# v1.1.76 production validation notes

v1.1.76 extracts support and diagnostics helpers into `lib/support.sh`.

Production validation should confirm:

```bash
VERSION="v1.1.76"
sudo erpnext-dev version
sudo erpnext-dev verify-toolkit
scripts/validate-release.sh
sudo erpnext-dev support-bundle-audit
sudo erpnext-dev final-qa
```

Expected:

- Version prints `ERPNext Developer Toolkit v1.1.76`.
- `/opt/erpnext-dev/lib/support.sh` exists after install/update reuse.
- `support-bundle-audit` and Final QA still work.

Runtime/install/backup/restore/SSL/firewall/health/go-live behavior is unchanged.

---

# v1.1.75 production validation notes