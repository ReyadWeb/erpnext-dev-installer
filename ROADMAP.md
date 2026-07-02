# ROADMAP

## Current: v0.9.2

Stable developer installer baseline with production readiness/planning classification, structured production domain planning, share-safe diagnostics, redacted support bundles, optional app compatibility preflight checks, and the first public cloud VM install hotfix.

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
- `production-domain-plan` structured DNS/domain planning
- root-run guided setup hotfix for fresh public/cloud VMs
- root storage expansion
- corrected post-expansion storage decision logic
- guided setup flow
- access verification
- local SSL wizard
- trusted mkcert replacement path
- optional app checkpoint workflow
- private installer logs and safer credential handling

## Next recommended work

### v0.9.3

- production SSL planning
- distinguish mkcert, self-signed, Let's Encrypt, Cloudflare Origin Cert, and commercial cert use cases
- detect common production SSL mistakes

### v0.9.4

- backup/restore hardening
- backup verification, restore warnings, off-VM backup guidance, and retention planning

### v1.0.0-rc1

- final QA pass
- documentation cleanup
- release checklist and GitHub tag workflow
