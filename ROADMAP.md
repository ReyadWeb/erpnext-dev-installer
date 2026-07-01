# ROADMAP

## Current: v0.9.0

Stable developer installer baseline with production readiness/planning classification, share-safe diagnostics, redacted support bundles, and optional app compatibility preflight checks.

Completed:

- ERPNext/Frappe v16 install
- custom local `.test` site names
- autostart service
- runtime and doctor checks
- `doctor --plain` safe copy/paste diagnostics
- `doctor --json` structured diagnostics
- `support-bundle` redacted troubleshooting archive
- `app-compatibility` optional app branch compatibility matrix
- compatibility warnings in `app-install-wizard`
- `production-readiness` environment classification
- `production-plan` planning checklist
- root storage expansion
- corrected post-expansion storage decision logic
- guided setup flow
- access verification
- local SSL wizard
- trusted mkcert replacement path
- optional app checkpoint workflow
- private installer logs and safer credential handling

## Next recommended work

### v0.9.1

- production domain planning
- guide DNS record requirements without changing public DNS automatically
- clarify local `.test` site versus real production domain

### v0.9.2

- production SSL planning
- distinguish mkcert, self-signed, Let's Encrypt, Cloudflare Origin Cert, and commercial cert use cases
- detect common production SSL mistakes

### v0.9.3

- backup/restore hardening
- backup verification, restore warnings, off-VM backup guidance, and retention planning

### v1.0.0-rc1

- final QA pass
- documentation cleanup
- release checklist and GitHub tag workflow
