# SAW026 deployment artifacts

Use these repository artifacts for deployment to another environment. The SQL
wrappers execute the plugin migration files directly, so there is one SQL
source of truth.

| Order | Artifact | Purpose |
|---|---|---|
| 1 | `sql/01-APPLY.sql` | Portable, idempotent installation |
| 2 | `sql/95-VERIFY.sql` | Read-only metadata and data verification |
| Rollback | `sql/99-ROLLBACK.sql` | Conservative rollback that preserves Activity data |
| — | `artifacts/NO-JAR.txt` | Confirms this update has no OSGi bundle |
| — | `artifacts/NO-PACKOUT.txt` | Explains why SQL is the authoritative delivery format |

The wrappers use `psql`'s `\ir` command and therefore work from any current
working directory. Keep the ticket and `idempiere-plugins` directories in their
repository layout.

The separate client and production packs remain available on the originating
workstation:

- `C:\Users\sawte\Downloads\AbilityERP-ClientUpdate-SAW026_vehicle_activity_tab-20260717\`
- `C:\Users\sawte\Downloads\AbilityERP-ProdUpdate-SAW026_vehicle_activity_tab-20260717\`

Those local paths are not required for an agent deploying from this repository.
