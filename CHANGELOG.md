# CHANGELOG

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
