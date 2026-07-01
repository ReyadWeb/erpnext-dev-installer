# CHANGELOG

## v0.9.0

### Added

- Added `production-plan` command and `prod-plan` alias.
- Expanded `production-readiness` from a preview into a production planning classifier.
- Added checks for CPU, RAM, root disk, install state, runtime/service state, production domain setting, local SSL assumptions, Nginx presence, and backup readiness.

### Improved

- Production readiness now classifies the VM as `Dev-only`, `Production candidate`, or `Not recommended`.
- Help text and examples now include `production-plan`.
- The production commands are planning-only and do not apply production changes.

## v0.8.24

### Added

- Added `app-compatibility` command for an optional app compatibility matrix.
- Added aliases `app-compat` and `app-preflight`.
- Added detailed compatibility cards before optional app install confirmation.
- Added compatibility snapshot inside `app-install-wizard`.

### Improved

- App install flow now shows detected Frappe branch, detected ERPNext branch, target app branch, install state, compatibility status, and recommendation before download/install.
- Moving branches such as `main` and experimental branches such as `develop` are now clearly warned before installation.
- Help text and app install guide now document the compatibility command.

### Safety

- Optional app installs now require an extra confirmation when the compatibility preflight returns a warning.
- Remote branch availability is checked before backup/download when a target branch is specified and the app is not already downloaded.

## v0.8.23

### Added

- Added `support-bundle` command for generating a redacted troubleshooting archive.
- Support bundle includes `doctor --plain`, `doctor --json`, JSON validation, system summary, service status, port status, storage status, SSL status, Bench status, recent warnings/errors, and a manifest.
- Added `support` as a short alias for `support-bundle`.

### Safety

- Support bundle generation excludes credential files, TLS private keys, raw `site_config.json` secrets, tokens, and database passwords.
- Bundle text outputs are passed through a redaction step before packaging.
- Generated support archives are written with private file permissions.

### Improved

- Help text now documents `support-bundle`.
- The support workflow builds directly on the v0.8.22 plain and JSON diagnostic primitives.
- Replaced the internal GiB formatter with an `awk` implementation to avoid depending on Python during support/status collection.

## v0.8.22

### Added

- Added `doctor --plain` for share-safe copy/paste diagnostics without ANSI colors.
- Added `doctor --json` for structured share-safe diagnostics.
- Diagnostic output now includes OS, Python, Node, MariaDB, Redis, Bench, site, service, port, storage, SSL, and optional app status summaries.

### Improved

- `active_bench_dir` no longer prints duplicate fallback paths when the expected Bench folder is missing.
- Help text now documents `doctor --plain` and `doctor --json`.

### Safety

- Plain and JSON doctor modes intentionally exclude passwords, tokens, private keys, raw credential contents, and raw site config secrets.

## v0.8.21

### Improved

- `next-step` now shows the decision inputs it used: storage, install, runtime, autostart, and local SSL state.
- `next-step` now moves forward after storage is already expanded instead of making the storage phase feel unresolved.
- Local SSL wizard now supports replacing an already-configured certificate with trusted mkcert files copied into `/tmp`.
- Local SSL wizard now identifies whether the installed certificate appears self-signed.
- `ssl-status` now prints a certificate trust hint to make self-signed vs mkcert-style certificates clearer.
- Missing mkcert source-file guidance now reuses the same HOST/VM instructions and explains replacement backups.

## v0.8.20

### Fixed

- Fixed storage status showing `Expansion recommended` after the root filesystem was already expanded.
- Replaced unsafe whole-disk-vs-partition-size expansion decision with actual partition tail-free-space detection.
- Avoids treating `/boot`, BIOS partitions, and partition start offsets as growable space.
- `expand-root-storage` now skips `growpart` when no growable disk tail exists and only uses existing LVM free space when available.

### Improved

- `storage-debug` now prints both detector and evaluator output.
- `storage-status` can display growable disk tail space when present.

## v0.8.19

- Added optional app checkpoint workflow.
- Added app install wizard and rollback guidance.
