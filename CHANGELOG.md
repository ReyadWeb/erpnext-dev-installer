# Changelog

## v0.8.19

Added optional app checkpoint workflow.

Changes:

- Added `app-install-wizard` command.
- Added `app-wizard` alias.
- Added `app-install-guide` command.
- Added `app-rollback-guide` command.
- Added pre-app install validation summary.
- Added backup checkpoint prompt before optional app installs.
- Added `APP_BACKUP_BEFORE_INSTALL=true|false|prompt` override.
- Added post-app validation summary after optional app installation.
- Updated App Library menu to prioritize the app install wizard.
- Updated `next-step` to point HTTPS-ready systems toward `app-install-wizard`.
- Documentation updated for optional app checkpoint workflow.

## v0.8.18

Added local SSL wizard workflow.

## v0.8.17

Added guided setup, next-step, and verify-access workflows.

## v0.8.16

Security and reliability cleanup:

- Private installer logs.
- Reduced credential exposure in terminal/logs.
- Installer lock for sensitive operations.
- Post-install validation summary.

## v0.8.15

Fixed setup-time root storage expansion decision logic.
