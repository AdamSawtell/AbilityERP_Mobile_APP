# SAW003 notes

- Deployment finished on staging; ticket marked **done** and agent-ready.
- Bundle: `com.aberp.rostering.staffinfo` ? version **`1.1.0.2026071219`** (`build.sh` / `deploy.sh` / MANIFEST / Downloads packs).
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

**Pack rule:** JAR must be **~46 KB**. Same version string at ~29 KB is a stale binary (no ticks).

## HCO Future Deployments variables

| Item | HCO value (2026-07-12) | Notes |
|------|------------------------|--------|
| Host | `32.236.127.117` | WebUI `http://32.236.127.117/webui/` |
| Info Window UU | `2b4ab146-0809-47c6-96f3-8b841d60a6bf` | Local `AD_InfoWindow_ID` = **1000034** (? seed `1000027`) |
| OLD IW (do not use) | UU `d0a2aeb5-?` local `1000042` | Leave alone |
| Shift (Rostered) window | UU `7c269a7e-?` local `1000082` | Employee tab `1000149` |
| Employee Search field | `AbERP_User_Contact_ID` ? ref `1000215` | Already points at IW `1000034` |
| Admin IW access | Admin + AbilityERP Admin + Rostering (+TL) | Already granted |
| JAR | `?_1.1.0.2026071219.jar` (~46 KB) | Rebuilt + redeployed after stale first install |
| Org `*` shifts | ~39k of ~106k on HCO | Do **not** bulk-move; smoke on `ad_org_id > 0` |
| `06-fix-shift-org.sql` | Skips AbilityERP-only data move | Still sets AlwaysUpdateable on contact column |

### Scope review vs HCO (2026-07-12)

| Area | Status |
|------|--------|
| SQL `01`?`20`?`04` | Applied on HCO |
| Lean FROM / Staff Name / hide clutter | OK |
| Related Info (7 links) | OK |
| BP/org triggers + AlwaysUpdateable | OK |
| Java ticks + needs/leave filters | OK after JAR rebuild |
| Downloads packs JAR | Refreshed to ~46 KB |
| Full smoke from Shift ? Employee Search | Still needs manual pass (automation hit parent-tab dialogs) |
