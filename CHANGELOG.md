# CHANGELOG v0.8.5

## Added

- Custom local site/domain selection during setup.
- `SITE_NAME=custom.test ./install-erpnext-dev.sh setup` workflow documented and improved.
- Interactive setup prompt:
  - `Local ERPNext site name [erp.test]:`
- Persistent local config file:
  - `/home/frappe/erpnext-dev-config.env`
- New command:
  - `site-config`
- New command:
  - `site-name-guide`
- Site name validation:
  - rejects URLs
  - rejects ports
  - rejects spaces/slashes
  - rejects `.local`
  - recommends `.test`
- Future commands reuse saved `SITE_NAME` when no environment override is provided.

## Changed

- Setup now makes multiple local ERPNext VM environments easier to manage.
- Access, SSL, `/etc/hosts`, and config output now reflect the selected site name.
- `environment-check` now reports site source and config file.
- `environment-check` avoids confusing missing-bench output when the VM context is otherwise detected.

## Fixed

- Clarified that `erp.test` is only the default, not a hardcoded requirement.
- Improved multi-environment guidance to use `setup` consistently.
