# Changelog

## v0.8.1 Beta

### Added

- Added `create-self-signed-local-cert` command for quick local HTTPS testing.
- Added richer `ssl-status` diagnostics:
  - Nginx installed/running state.
  - Nginx SSL config and enabled site status.
  - Certificate/key existence and permissions.
  - Certificate subject, issuer, validity dates, and SAN when available.
  - Port 80, 443, 8000, and 9000 status.
  - Local HTTP, HTTPS, and direct Bench response checks.
- Expanded `local-ssl-guide` with self-signed and mkcert workflows.
- Added clearer host test commands and rollback instructions.

### Preserved

- Existing v0.8.0 Nginx reverse proxy behavior remains unchanged.
- Direct Bench access on `http://SITE_NAME:8000` remains unchanged.
- Existing `erpnext-dev.service` behavior remains unchanged.

### Notes

- Self-signed certificates are for testing only and will trigger browser warnings.
- mkcert remains the recommended local trusted-browser workflow.
- Production SSL remains a separate future track.

## v0.8.0 Beta

### Added

- Added `ssl-status` command.
- Added `local-ssl-guide` command.
- Added `configure-local-ssl` command.
- Added `disable-local-ssl` command.
- Added Nginx reverse proxy config generation for local HTTPS.
- Added mkcert/local CA workflow guidance.
- Added local SSL options to Access and Advanced menus.
- Added documentation for local HTTPS architecture.
