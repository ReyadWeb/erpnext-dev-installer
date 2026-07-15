# Development guide

How to work on the **ERPNext Developer Toolkit** locally. For workflow, PR
expectations, and contribution types, start with [`CONTRIBUTING.md`](../CONTRIBUTING.md).
For how releases are cut, see [`RELEASE-PROCESS.md`](RELEASE-PROCESS.md).

Repository: `https://github.com/ReyadWeb/erpnext-dev-toolkit`

---

## Prerequisites

- Linux (Ubuntu 24.04 / 26.04 or Debian 13 recommended for engine testing)
- `git`, `bash`, `python3` (used by some release helpers)
- Optional: Docker Engine + Compose for Docker-engine work
- Optional: passwordless `sudo` for menu / install smoke tests (skipped otherwise)

You do **not** need a full ERPNext site to run the canonical static gate.

---

## Clone and remotes

```bash
git clone https://github.com/<you>/erpnext-dev-toolkit.git
cd erpnext-dev-toolkit
git remote add upstream https://github.com/ReyadWeb/erpnext-dev-toolkit.git
git fetch upstream
git checkout main
git merge --ff-only upstream/main
```

---

## Canonical local validation

Always run this before opening a PR:

```bash
./scripts/validate-release.sh
```

That script is the source of truth. It covers (among other things):

- Bash syntax for the toolkit entrypoint and modules
- Module consistency (`scripts/check-module-consistency.sh`)
- ShellCheck (`scripts/run-shellcheck.sh`)
- `RELEASE-MANIFEST.txt` coherence and `SHA256SUMS` for checksummed paths
- Version pin checks (script / changelog / README / manifest header)
- Hermetic unit-style scripts (engine select, host-OS output, signing policy, …)
- A basic secret-pattern scan of the packaged tree

If you change a checksummed file, regenerate:

```bash
bash scripts/generate-release-checksums.sh
```

Docs/assets that are listed only in `RELEASE-MANIFEST.txt` must **exist**; not every
asset is in `SHA256SUMS` (the generator intentionally checksums the executable
surface + manifest). Prefer editing the generator only when adding new modules.

---

## Layout (where to change what)

| Path | Touch when… |
| --- | --- |
| `erpnext-dev.sh` | New command, help text, dispatcher allowlist |
| `lib/engine.sh` | Engine-agnostic routing / contract verbs |
| `lib/install.sh` | Native install / preflight |
| `lib/docker.sh` | Docker development or production |
| `lib/backup.sh` | Backup, restore, off-VM, object storage (native routing) |
| `lib/security.sh` | Verify / update / security audit |
| `lib/ssl.sh` | Local mkcert / production SSL helpers |
| `scripts/` | Release gate, checksums, hermetic tests |
| `.github/workflows/` | CI / integration / release (maintainer-sensitive) |
| `docs/` | Guides, signing pubkey, diagrams |

Prefer extending `engine_*` verbs over scattering `if docker` elsewhere.

---

## Manual engine testing (optional)

Use disposable VMs. Never commit secrets.

- **Native:** follow [`VALIDATION.md`](../VALIDATION.md) Phase A or
  [`TESTING.md`](../TESTING.md).
- **Docker development:** `DEPLOYMENT_ENGINE=docker` install path in TESTING.
- **Docker production:** `DOCKER_MODE=production` / `docker-production-setup` path
  in VALIDATION Phase B.

CI already runs native + Docker smoke on Ubuntu 24.04 as hard release gates.

---

## Editing tips

- Keep OS wording: **Ubuntu 24.04 / 26.04 LTS and Debian 13**.
- Keep runtime identities stable (`erpnext-dev` CLI, `/opt/erpnext-dev`,
  `/etc/erpnext-dev`) unless there is a deliberate migration.
- Match neighboring Bash style (`status_line`, `ui_*`, `toolkit_cmd`).
- Redact credentials from fixtures and screenshots.

---

## Getting unblocked

- Questions → [Discussions Q&A](https://github.com/ReyadWeb/erpnext-dev-toolkit/discussions/new?category=q-a)
- Design → [Discussions Ideas](https://github.com/ReyadWeb/erpnext-dev-toolkit/discussions/new?category=ideas)
- Bugs / features → [Issue forms](https://github.com/ReyadWeb/erpnext-dev-toolkit/issues/new/choose)
