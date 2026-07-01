# ROADMAP

## Current: v0.8.22

Stable developer installer baseline with share-safe diagnostic output for support/debug workflows.

Completed:

- ERPNext/Frappe v16 install
- custom local `.test` site names
- autostart service
- runtime and doctor checks
- `doctor --plain` safe copy/paste diagnostics
- `doctor --json` structured diagnostics
- root storage expansion
- corrected post-expansion storage decision logic
- guided setup flow
- access verification
- local SSL wizard
- trusted mkcert replacement path
- optional app checkpoint workflow
- private installer logs and safer credential handling

## Next recommended work

### v0.8.23

- add safer support bundle export with secrets redacted
- include `doctor --plain` and `doctor --json` outputs in the support bundle
- include recent service logs with redaction
- exclude credentials, private keys, tokens, and raw site config secrets

### v0.8.24

- improve optional app compatibility checks before download/install
- show detected Frappe/ERPNext branch and target app branch
- warn before installing uncertain or experimental app branches

### v0.9.x

- production planning branch
- production domain planning
- production SSL planning
- backup/restore hardening
