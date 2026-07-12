# SAW007 notes

- `deploy.sh` default is **portable** (`register-contactactivity-tabs.sql` + `fix-activity-user-contact.sql`).
- Seed path only with `ABERP_ACTIVITY_SEED_SQL=1` (hardcoded window IDs — reference tenant only).
- No INSTALL-CONTACT-ACTIVITY-TABS.md — use this ticket `DEPLOY.md`.
- Marker JAR `com.aberp.contactactivity.tabs` is packaging-only (no Java classes). AD tabs work without OSGi install; optional for inventory.

## HCO Future Deployments variables

| Item | HCO value (2026-07-12) | Notes |
|------|------------------------|--------|
| Host | `32.236.127.117` | WebUI `http://32.236.127.117/webui/` |
| `C_ContactActivity` table | `53354` (same as seed) | Resolve by `tablename`, never hardcode |
| Booking Generator window | local ID `1000163` (≠ seed `1000193`) | Resolve by **name** |
| Service Booking window | local ID `1000075` (≠ seed `1000077`) | Resolve by **name** |
| Service Agreement (Project) | local ID `1000073` (≠ seed `1000118`) | Resolve by **name** |
| Activity tabs created | BG `1000358` · SB `1000359` · SA `1000360` | Link cols: `AbERP_BookingGenerator_ID` / `C_Order_ID` / `C_Project_ID` |
| Element `AbERP_BookingGenerator_ID` | HCO UU `a3f7351a-…` (pre-existing) | **Do not overwrite** — insert only if missing |
| Physical cols before install | Missing `aberp_bookinggenerator_id`, `c_order_id` | Added by portable `01` / register |
| Marker JAR on host | Not installed | AD-only smoke passed without JAR |
| Smoke role | **Admin** | Logout/in required after field AD changes |
| Required Activity Types | EM, ME, PC, CN, TA | Email, Meeting, Phone call, Case Note (Note), Task — all three windows |
| Delta SQL (types only) | `sql/04-ensure-activity-types.sql` | Applied HCO 2026-07-12 after first tab install |

**Do not** set `ABERP_ACTIVITY_SEED_SQL=1` on HCO.

### HCO next install / prod update note

If Activity tabs are already present, the next HCO production update only needs:

`AbilityERP-ProdUpdate-SAW007_activity_tab_integration-20260712\02-DELTA-activity-types-only.sql`

(or repo `sql/04-ensure-activity-types.sql`)

Fresh HCO-like hosts: full portable order including `04`. After apply: logout/in; Activity Type must list Email, Meeting, Phone call, Case Note, Task.
