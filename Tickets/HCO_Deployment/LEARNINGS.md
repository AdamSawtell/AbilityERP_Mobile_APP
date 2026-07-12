# HCO Deployment — learnings log

Append new entries at the **top** after each HCO install or failed attempt. Keep each entry short; put ticket-local IDs in that ticket’s **HCO Future Deployments variables** section.

---

## 2026-07-12 — SAW007 Activity tab integration

**Result:** Pass (SQL + WebUI smoke Booking Generator → Activity). No HCO `*_UU` overwritten.

### What worked

- Portable path: `sql/01-add-link-columns.sql` → `register-contactactivity-tabs.sql` → `fix-activity-user-contact.sql`.
- Windows resolved by name (HCO IDs differ from seed). Tabs: BG `1000358`, SB `1000359`, SA `1000360` (19 fields each).
- WebUI (Admin, after logout/in): Activity New shows **Business Partner** inherited (`Winston Churchill`), **User** empty (not hardcoded SuperUser), **User/Contact** hidden.
- Marker JAR not required for AD tabs on HCO.

### Learnings → process fixes

| Learning | Action taken |
|----------|----------------|
| PG rejects `UPDATE … FROM t JOIN … ON … = target.col` when JOIN references update target | Rewrote `fix-activity-user-contact.sql` UPDATEs with `EXISTS` / no target-alias JOIN |
| `nextid(AD_Field)` lagged after register’s `MAX+1` field clones → duplicate key on User field insert | User-field insert uses `MAX+1` + sequence bump; register now bumps `AD_Field` sequence after clone |
| Existing element `AbERP_BookingGenerator_ID` already on HCO with different UU | Insert element/column only when missing — never overwrite UU |
| Field display changes need logout/in (Cache Reset alone may not refresh tab form) | Documented in HCO NOTES / smoke |

### Ticket artefacts

- `Tickets/SAW007_activity_tab_integration/NOTES.md` → HCO Future Deployments variables  
- Process SQL: `idempiere-plugins/com.aberp.contactactivity.tabs/` (`01`, `register-…`, `fix-activity-user-contact.sql`)

---

## 2026-07-12 — SAW010 Timesheet Approval Info columns

**Result:** Pass (SQL + WebUI column smoke). Existing InfoColumn UUs unchanged (matched pack).

### What worked

- Info Window UU `40d6a2d7-…` and all hide-target InfoColumn UUs matched Core on HCO.
- Break Start/End inserted with owned UUs; order after Shift Type confirmed in WebUI.
- Filters still show Business Partner / Activity / Employee; grid does not.

### Learnings → process fixes

| Learning | Action taken |
|----------|----------------|
| Prefer `ssh` stdin upload over multi-file `scp` on this Windows host (scp/ssh sessions were hanging) | Document in HCO README access notes |
| Stale local `ssh.exe` processes can block new HCO connections | Kill hung ssh/scp before retry |
| Do **not** run `04-seed-test-rows.sql` on HCO (hardcoded client/org) | Already noted in DEPLOY.md — reinforced |
| Grant Info Window access to **Admin** + AbilityERP Admin even when IW already existed | Applied on HCO install |

### Ticket artefacts

- `Tickets/SAW010_timesheet_approval_info_columns/NOTES.md` → HCO Future Deployments variables  
- `Tickets/SAW010_…/hco/run-install.sh`

---

## 2026-07-12 — SAW009 Support day pattern number (Service Booking Line)

**Result:** Pass (SQL + WebUI smoke). No existing HCO column UUIDs changed.

### What worked

- Tab / reference / element UUs matched Core.
- Columns already existed on HCO as **String** storing weekday names; switched to List **14 Day Roster Period** without changing column UUs.
- Backfill from `AbERP_ServicePattern` (48019 lines) → values `1`..`15`; WebUI shows e.g. `13 - Saturday`.
- Sync trigger installed.

### Learnings → process fixes

| Learning | Action taken |
|----------|----------------|
| `01` previously set `ad_column_uu = our UU` when matching by ColumnName — would overwrite HCO UUs | Keep existing UU; only update reference/list/properties |
| HCO already had weekday-text data in the same physical columns | Backfill from pattern only (no weekday→day-01 guessing) |
| HCO “14 Day Roster Period” list labels start Monday (`01 - Monday`), not Sunday | Do not rewrite list; display whatever the client list defines |
| Physical columns already `varchar(100)` | `ADD COLUMN IF NOT EXISTS` skips; do not force shrink to 5 |
| New fields may not keep pack-owned field UUs on insert | Resolve fields by tab + column; never overwrite existing field UU |
| Menu tree “Service Booking” opens reliably via `a.menu-href` click | Prefer menu-href over treecell-only click for WebUI smoke |

### Ticket artefacts

- `Tickets/SAW009_support_day_pattern_number/NOTES.md` → HCO Future Deployments variables  
- `Tickets/SAW009_…/hco/run-install.sh`

---

## 2026-07-12 — SAW001 Paid filter (Notification SR Invoice Send Info)

**Result:** Pass (SQL + WebUI smoke). No HCO UUIDs changed. Process hardened and pushed (`9f720f5`).

### What worked

- Core Info Window UU `8fb1cd46-ed81-4cb9-8b83-7662caed9e62` already present on HCO (local `AD_InfoWindow_ID` = `1000029`, not seed `1000032`).
- UU-owned Paid columns insert cleanly; criteria Yes/No/blank works.
- WebUI: Paid=Yes vs Paid=No returns different row counts; **Paid** grid column visible.

### Learnings → process fixes

| Learning | Action taken |
|----------|----------------|
| Menu SQL used hardcoded tree node `1000229` — missing on HCO → menu landed at parent `0` | `04-add-info-menu.sql`: resolve parent by summary menu name **Ability ERP** |
| UPDATE-by-name path set `ad_menu_uu = our UU` — would **overwrite** a client menu UU | Never overwrite existing `ad_menu_uu`; only set UU on INSERT of our owned object |
| HCO SuperUser role dialog exposes **Admin**, not AbilityERP Admin; Admin had **no** Info Window access | `05-grant-admin-infowindow-access.sql`: grant by role **name** to `Admin` + `AbilityERP Admin` |
| AbilityERP Admin can exist in AD but still not appear on SuperUser’s role list for that client | Smoke as **Admin** on HCO; still grant AbilityERP Admin for builds that use it |
| Windows PEM `d:\HCObusiness.pem` too open for OpenSSH | Copy to `%USERPROFILE%\.ssh\HCObusiness.pem` with user-only ACL before SSH |
| ZK dateboxes: JS `.value =` alone often does not bind — mandatory Date Invoiced stays red / empty query | Prefer calendar UI or Enter/blur + ReQuery; narrow date range for smoke |
| Functional-check SQL dumping all invoices floods logs on HCO (~20k paid rows) | Prefer `COUNT(*)` / `LIMIT` on client smoke SQL |

### HCO local IDs (hints only — do not use in portable SQL)

| Object | HCO ID | UU |
|--------|--------|-----|
| Info Window | 1000029 | `8fb1cd46-ed81-4cb9-8b83-7662caed9e62` |
| Menu | 1000227 | `c1d2e3f4-a5b6-7788-9900-aabbccdde001` |
| Ability ERP folder | 1000000 | (name lookup) |

### Ticket artefacts

- `Tickets/SAW001_paid_filter_invoice_send_info/NOTES.md` → HCO Future Deployments variables  
- One-off apply helper: `Tickets/SAW001_…/hco/05-hco-access-menu.sql` (folded into package `05-grant-admin-infowindow-access.sql`)

---

<!-- Template for next entry:

## YYYY-MM-DD — SAW### short title

**Result:** Pass | Fail | Partial

### What worked
- …

### Learnings → process fixes
| Learning | Action taken |
|----------|----------------|
| … | … |

### HCO local IDs (hints only)
| Object | HCO ID | UU |
|--------|--------|-----|

### Ticket artefacts
- …

-->
