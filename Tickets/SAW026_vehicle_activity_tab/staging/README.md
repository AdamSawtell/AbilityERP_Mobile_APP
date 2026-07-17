# SAW026 staging diagnostics

These scripts are investigation aids, not deployment steps:

- `00-discover.sql` inventories Vehicle, Activity, reference, role, and field metadata.
- `01-diagnose-link.sql` compares the Vehicle parent link with established Activity tabs.

For another environment, deploy with the ordered wrappers under `../sql/` and
follow `../DEPLOY.md`. Run these diagnostics only if preflight or WebUI
verification fails.
