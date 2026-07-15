# Community project board

Track starter and community-facing work for
[`ReyadWeb/erpnext-dev-toolkit`](https://github.com/ReyadWeb/erpnext-dev-toolkit).

## Create the board (one-time, maintainer)

GitHub Projects requires the `project` / `read:project` token scopes. From a
machine where `gh` can refresh auth:

```bash
gh auth refresh -s project,read:project
gh project create --owner ReyadWeb --title "ERPNext Dev Toolkit — Community"
```

Then link the repository under the project’s **Settings → Linked repositories**,
and add a view filtered to:

- `label:good first issue`
- `label:help wanted`
- `label:status: accepted`

Suggested columns: **Backlog → Ready → In progress → Done**.

## Seed issues (already opened)

| # | Title |
| --- | --- |
| [#19](https://github.com/ReyadWeb/erpnext-dev-toolkit/issues/19) | docs: expand Debian 13 native troubleshooting notes |
| [#20](https://github.com/ReyadWeb/erpnext-dev-toolkit/issues/20) | docs: add a VPS provider validation record |
| [#21](https://github.com/ReyadWeb/erpnext-dev-toolkit/issues/21) | ux: clarify Docker readiness-timeout warning next steps |
| [#22](https://github.com/ReyadWeb/erpnext-dev-toolkit/issues/22) | docs: improve object-backup help descriptions |
| [#23](https://github.com/ReyadWeb/erpnext-dev-toolkit/issues/23) | docs: link SUPPORT/CONTRIBUTING from next-steps surfaces |

After the board exists, add these items (and new `good first issue` tickets) to
**Ready**.

## Contributor entry points

- [Issue forms](https://github.com/ReyadWeb/erpnext-dev-toolkit/issues/new/choose)
- [`CONTRIBUTING.md`](../CONTRIBUTING.md)
- [`docs/DEVELOPMENT.md`](DEVELOPMENT.md)
