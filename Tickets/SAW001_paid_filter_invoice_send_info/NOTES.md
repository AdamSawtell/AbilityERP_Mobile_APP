# SAW001 notes

- Info Window UU: `8fb1cd46-ed81-4cb9-8b83-7662caed9e62`
- Display / criteria column UUs fixed in package SQL (see plugin README / migrations)
- Create From still needs Logilite `WCreateNotificationLines` on builds that lack it (pre-existing)

## HCO Future Deployments variables

Recorded from HCO Test install (`32.236.127.117`, build AvERP HCO Test001 20260712) on 2026-07-12. **Do not change any HCO `*_UU` values** — only update the AbilityERP update process / SQL.

| Variable | AbilityERP Core / pack | HCO observed | Notes |
|---|---|---|---|
| `AD_InfoWindow_UU` | `8fb1cd46-ed81-4cb9-8b83-7662caed9e62` | **same** | Preflight OK |
| `AD_InfoWindow_ID` (local) | seed hint `1000032` | `1000029` | Numeric ID differs — always resolve by UU |
| Paid display `AD_InfoColumn_UU` | `a8f3c2e1-9b47-4d6a-8e15-2c7f9a1b4d03` | inserted as this UU | Owned AbERP UU |
| Paid criteria `AD_InfoColumn_UU` | `b7e4d3f2-0c58-4e7b-9f26-3d8a0b2c5e14` | inserted as this UU | Owned AbERP UU |
| Menu `AD_Menu_UU` | `c1d2e3f4-a5b6-7788-9900-aabbccdde001` | inserted as this UU | Owned AbERP UU |
| Menu `AD_Menu_ID` (local) | n/a | `1000227` | Local only |
| Menu tree parent | old SQL used node `1000229` (missing on HCO → parent `0`) | parent `1000000` **Ability ERP** (by name) | **Process fix:** `04-add-info-menu.sql` now resolves parent by name `Ability ERP` |
| Role for WebUI smoke | AbilityERP Admin | HCO login role list uses **`Admin`** (AbilityERP Admin exists in AD but not on SuperUser role dialog) | **Process fix:** `05-grant-admin-infowindow-access.sql` grants IW access to `Admin` + `AbilityERP Admin` by name |
| WebUI | — | `http://32.236.127.117/webui/` | SuperUser / HCOflamingo |
| DB | — | `idempiere` / `adempiere` / flamingo | |

### HCO install outcome (2026-07-12)

- Preflight / 01 / 04 applied; then Admin access + menu parent fix (`Tickets/.../hco/05-hco-access-menu.sql` one-off; now folded into package `05-…`).
- WebUI smoke (Admin): Paid criteria Yes/No visible; Paid=Yes → 65 rows (01–12 Jul 2026); Paid=No → 20 rows; grid includes **Paid** column.
- No HCO UUIDs were modified.
