# HCO Deployment — learnings log

Append new entries at the **top** after each HCO install or failed attempt. Keep each entry short; put ticket-local IDs in that ticket’s **HCO Future Deployments variables** section.

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
