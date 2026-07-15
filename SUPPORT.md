# Support

This page explains where to ask for help with the **ERPNext Developer Toolkit**
(`ReyadWeb/erpnext-dev-toolkit`).

The toolkit is open source and community-supported. There is **no commercial /
private support channel** at this time.

---

## Choose the right channel

| Kind of request | Where to go |
| --- | --- |
| **Bug** — something does not behave as documented | [GitHub Issues](https://github.com/ReyadWeb/erpnext-dev-toolkit/issues/new/choose) (Bug report form) |
| **Feature** — you want behavior that does not exist yet | [GitHub Issues](https://github.com/ReyadWeb/erpnext-dev-toolkit/issues/new/choose) (Feature request form) |
| **Question** — how do I use X? | [GitHub Discussions → Q&A](https://github.com/ReyadWeb/erpnext-dev-toolkit/discussions/new?category=q-a) |
| **Idea / architecture** — open-ended design talk | [Discussions → Ideas](https://github.com/ReyadWeb/erpnext-dev-toolkit/discussions/new?category=ideas) |
| **Installation experience** — “it worked on provider Y” | [Discussions → Show and tell](https://github.com/ReyadWeb/erpnext-dev-toolkit/discussions/new?category=show-and-tell) (prefix the title with `Installation report:`) |
| **Security vulnerability** | **Private only** — see [`SECURITY.md`](SECURITY.md). Do **not** open a public issue. |
| **Docs typo / clarity** | Issue (or a small PR — see [`CONTRIBUTING.md`](CONTRIBUTING.md)) |

---

## Before you ask

1. Check [`README.md`](README.md), [`TESTING.md`](TESTING.md), and
   [`VALIDATION.md`](VALIDATION.md).
2. Run `sudo erpnext-dev doctor --plain` (or `engine-diagnostics`) and include a
   **redacted** excerpt if relevant.
3. Remove passwords, API keys, private keys, database credentials, tokens, and
   customer data from anything you paste.

---

## What maintainers need for a useful bug

- Toolkit version (`erpnext-dev version`)
- Deployment engine (native / Docker development / Docker production)
- OS (Ubuntu 24.04 / 26.04, Debian 13, other)
- Exact command(s)
- Expected vs actual result
- Redacted logs / doctor output

Use the Bug report Issue Form so these fields are structured.

---

## Response expectations

This is a maintainer-led project. Issues and Discussions are handled as time
allows. Security reports are prioritized according to
[`SECURITY.md`](SECURITY.md).

Thank you for helping keep the support surface clear — that makes the project
safer and more sustainable for everyone.
