# Roadmap

## Current: v0.8.17

Guided developer setup flow.

Completed:

- `guided-setup`
- `next-step`
- `verify-access`
- improved final setup guidance
- cleaner separation between VM-side and host-side access steps

## Next: v0.8.18

Local SSL wizard.

Target:

- guided local SSL command
- host/VM separation for mkcert steps
- clearer self-signed vs trusted certificate path
- SSL verification checklist
- rollback confirmation

## Later: v0.8.19

Optional app checkpoint workflow.

Target:

- snapshot/backup reminder before optional apps
- clearer app compatibility notes
- better failed optional app recovery
- optional app install summary

## v0.9.x

Production-readiness planning branch.

Target:

- production domain planning
- production SSL planning
- Nginx/Supervisor/systemd production model notes
- firewall, backups, monitoring, and update strategy

Production automation should remain separate from the developer `bench start` workflow.
