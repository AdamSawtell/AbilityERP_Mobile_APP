# SAW003 notes

- Deployment finished on staging; ticket marked **done** and agent-ready.
- Bundle: `com.aberp.rostering.staffinfo` — version **`1.1.0.2026071219`** (`build.sh` / `deploy.sh` / MANIFEST / Downloads packs).
- Info Window UU: `2b4ab146-0809-47c6-96f3-8b841d60a6bf`
- Not the same as SAW011 (Accept Shift Request) or SAW004 (Rostering Chat).

## Late UX (keep in packs)

| Script | Behaviour |
|--------|-----------|
| `18` | Result grid display-only when a row is selected |
| `19` | **Staff Name** label; Show Unmatched under Staff Name, Show Unavailable under Employee (Java layout) |
| `20` | Hide BP Name, Status, Business Partner, Agency Staff from **grid**; Agency Staff stays criteria |

`20` must run **after** `03`/`05`/`09` on every full redeploy or those scripts re-show columns.

## Packs

Refresh when the JAR or SQL order changes:

- `Downloads\AbilityERP-ClientUpdate-SAW003_staff_rostering_info-20260712\`
- `Downloads\AbilityERP-ProdUpdate-SAW003_staff_rostering_info-20260712\`
