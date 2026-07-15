# Contributing to the ERPNext Developer Toolkit

Thank you for wanting to help. You do **not** need to be an ERPNext infrastructure
expert to contribute. Docs, compatibility reports, clearer error text, and small UX
fixes are as valuable as deep engine work.

This repository is **`ReyadWeb/erpnext-dev-toolkit`**. The day-to-day CLI remains
`erpnext-dev`; only the GitHub repo name was rebranded.

Please read [`SUPPORT.md`](SUPPORT.md) so bugs, questions, and security reports go
to the right channel.

---

## Project philosophy

- **Two first-class engines, one CLI.** Native VM and Docker share the same operator
  experience via [`lib/engine.sh`](lib/engine.sh). Prefer extending the contract over
  scattering `if docker` branches.
- **Do not regress the defaults.** Native install and Docker local-dev (`pwd.yml`)
  must stay simple and safe.
- **Release integrity is sacred.** Stable tags must pass the full validate +
  integration gate and signed publish path.
- **Secrets never belong in tickets or PRs.** Redact passwords, keys, tokens, and
  `site_config.json` values before you share anything.

---

## Ways to contribute

| Contribution type | Experience |
| --- | --- |
| Fix a typo / clarify docs | Beginner |
| Improve documentation or diagrams | Beginner |
| Test an install on a new VPS/provider | Beginner–intermediate |
| Report compatibility results | Beginner–intermediate |
| Improve terminal / help UX | Intermediate |
| Add or harden tests | Intermediate |
| Fix a native-engine bug | Intermediate–advanced |
| Fix Docker lifecycle / production compose | Advanced |
| Touch release signing, update, or security | Advanced + maintainer review |

Look for issues labeled `good first issue` or `help wanted`.

---

## Before opening an issue

1. Search existing [Issues](https://github.com/ReyadWeb/erpnext-dev-toolkit/issues)
   and [Discussions](https://github.com/ReyadWeb/erpnext-dev-toolkit/discussions).
2. Confirm whether it is a **bug**, **feature**, **question**, or **security** report
   (see [`SUPPORT.md`](SUPPORT.md)).
3. Use an [Issue Form](https://github.com/ReyadWeb/erpnext-dev-toolkit/issues/new/choose)
   when filing a bug or feature.
4. **Never** file security vulnerabilities as public issues. Use private vulnerability
   reporting described in [`SECURITY.md`](SECURITY.md).

---

## Before writing code

1. Open or claim an issue (or start a Discussion for design questions).
2. Keep the change small and focused — one concern per PR.
3. Prefer engine-agnostic routing in `lib/engine.sh` when both engines need the same verb.
4. Do not change runtime paths (`/opt/erpnext-dev`, `/etc/erpnext-dev`, service names)
   or the `erpnext-dev` command identity without an explicit, documented migration.

---

## Development setup

You need Bash, `git`, and the usual developer tools on Linux. Many local checks need
no ERPNext install.

```bash
git clone https://github.com/<your-username>/erpnext-dev-toolkit.git
cd erpnext-dev-toolkit
git remote add upstream https://github.com/ReyadWeb/erpnext-dev-toolkit.git
```

Full native or Docker installs for behavioral testing should follow
[`VALIDATION.md`](VALIDATION.md) / [`TESTING.md`](TESTING.md) on a disposable VM.

---

## Repository map (start here)

| Path | Role |
| --- | --- |
| [`erpnext-dev.sh`](erpnext-dev.sh) | CLI entry + dispatcher |
| [`lib/engine.sh`](lib/engine.sh) | Deployment-engine contract |
| [`lib/install.sh`](lib/install.sh) | Native install / preflight |
| [`lib/docker.sh`](lib/docker.sh) | Docker (dev + production) |
| [`lib/backup.sh`](lib/backup.sh) | Backup / restore / off-site |
| [`lib/security.sh`](lib/security.sh) | Release verify / self-update / audit |
| [`lib/ssl.sh`](lib/ssl.sh) | Local + production HTTPS |
| [`scripts/validate-release.sh`](scripts/validate-release.sh) | **Canonical local release gate** |
| [`.github/workflows/`](.github/workflows/) | CI, integration, release |

---

## How to choose an issue

1. Prefer labeled `good first issue` for a first PR.
2. Prefer `help wanted` for clearly scoped maintainer-approved work.
3. For large ideas, open a Discussion under **Ideas** or **Architecture** first.

---

## Fork and branch workflow

```bash
# 1. Fork on GitHub, then clone your fork (see above)

# 2. Sync main
git fetch upstream
git checkout main
git merge --ff-only upstream/main

# 3. Create a branch
git checkout -b fix/short-description

# 4. Make the change

# 5. Run the canonical local validation (required)
./scripts/validate-release.sh

# 6. Commit (clear, why-focused message)
git add -A
git commit -m "fix(docker): clarify readiness timeout message"

# 7. Push and open a PR against ReyadWeb/erpnext-dev-toolkit:main
git push -u origin fix/short-description
```

`validate-release.sh` is the source of truth. It runs syntax checks, module
consistency, shellcheck, checksum/manifest coherence, and other release gates.
Do not invent a parallel ad-hoc checklist that drifts from it.

---

## Coding standards

- Bash with `set -Eeuo pipefail` at the entrypoint; follow existing `lib/` patterns.
- Prefer clear `status_line` / `ui_*` messaging over silent failure.
- Avoid `if docker; then … else …` scattered outside `lib/engine.sh` when a contract
  verb already exists.
- No secrets in source, fixtures, screenshots, or logs committed to the repo.
- Match neighboring style; do not reformat unrelated regions.

---

## Testing requirements

- Always run `./scripts/validate-release.sh` before opening a PR.
- For behavior changes, say what you ran (commands + OS + engine) in the PR template.
- Native vs Docker: note which engine(s) you exercised.
- Release/signing/update/security paths require maintainer attention; expect extra review.

See [`TESTING.md`](TESTING.md) and [`VALIDATION.md`](VALIDATION.md) for deeper scenarios.

---

## Security-sensitive changes

Extra care for anything that touches:

- root execution, credentials, SSH keys
- network exposure / firewall / HTTPS
- backups, restore, off-site transport
- release signing, checksums, `update-toolkit`
- GitHub Actions / Dependabot

Call these out in the PR **Security impact** section. Prefer private vulnerability
reporting for suspected vulnerabilities ([`SECURITY.md`](SECURITY.md)).

---

## Native engine changes

- Keep Ubuntu 24.04 / 26.04 LTS and Debian 13 expectations accurate in messaging.
- Do not weaken install preflight without a documented reason.
- Prefer additive helpers over breaking config-file renames.

---

## Docker engine changes

- Preserve the local-dev `pwd.yml` happy path.
- Production `compose.yaml` changes must keep pins, durable backups, and exposure
  guardrails in mind ([`DEPLOYMENT-ARCHITECTURE.md`](DEPLOYMENT-ARCHITECTURE.md)).
- Avoid mutating a running container when an immutable re-deploy is the documented path.

---

## Documentation contributions

Docs PRs are welcome and often the best first contribution. Keep:

- Supported OS wording accurate (Ubuntu 24.04 / 26.04 LTS and Debian 13)
- Repo URLs pointing at `erpnext-dev-toolkit`
- Commands copy-pasteable with `sudo` where required

---

## Pull request requirements

Use the PR template. In short:

- Clear summary and why
- Scope checkboxes (native / Docker / security / docs / …)
- Validation commands and environments
- Backward-compatibility and security notes
- No secrets in the branch

We prefer **squash merge** of focused PRs.

---

## Review and merge process

1. CI must pass (including release-validation checks used by the project).
2. A maintainer reviews for correctness, safety, and scope.
3. Changes may be requested; please keep the branch updated.
4. Maintainers merge when ready; credit appears in release notes when applicable.

Recommended repository protection for `main` (maintainer-administered): require a
pull request for outside contributors, require the project's status checks
(including release validation), require conversation resolution, block force
pushes and branch deletion, and require code-owner review for security/release
paths listed in `.github/CODEOWNERS`. Signed commits are **not** required for
first-time contributors.

---

## Growing into a maintainer

There is no formal ladder yet. In practice:

1. **Contributor** — an accepted PR or helpful report
2. **Regular contributor** — several quality contributions
3. **Trusted helper** — triage/docs/review in an area you know

Module ownership and a `GOVERNANCE.md` will come when the community needs them.
Reliable, kind collaboration matters more than titles.

---

## Code of conduct

Participation is governed by [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).

Questions about contributing? Open a **Q&A** Discussion or ask on an issue — and
thank you for improving the toolkit.
