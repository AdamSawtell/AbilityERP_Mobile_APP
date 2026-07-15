# SAW023 — Deploy (Compliance & Audit Hub)

## Hosts

| Env | Host | Notes |
|-----|------|-------|
| Dev | `3.27.207.215` | Skeleton installed here first |
| HCO | See `Tickets/HCO_Deployment/` | Later — never change HCO `*_UU` |

SSH (dev): `ubuntu@3.27.207.215` with `C:\Users\sawte\Documents\SSH Keys\HCObusiness.pem`

## JAR

None for skeleton. Phase 2 adds `com.aberp.compliance` OSGi JAR (manual OSGi console).

## SQL order

From `idempiere-plugins/com.aberp.compliance/sql/`:

1. `00-preflight.sql`
2. `01-create-tables.sql`
3. `02-ad-references.sql`
4. `03-ad-table-columns.sql`
5. `04-dashboard-view.sql`
6. `05-rules-window.sql`
7. `06-summary-window.sql`
8. `07-menu-access.sql`
9. `08-seed-dummy-snapshot.sql` (dev smoke numbers — skip on prod if unwanted)
10. `09-verify.sql`
11. `10-menu-window-trl.sql`

```bash
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f /path/to/00-preflight.sql
# … through 10
```

Or: `bash install-all.sh` from the `sql/` folder on the host.

Then **Cache Reset** or restart iDempiere, then WebUI logout/in.

## AbilityERP Admin access

Install SQL grants window access to **AbilityERP Admin**, **Admin**, and **System Administrator** by role name.

| Access | Name | Search key |
|--------|------|------------|
| Window | Compliance Summary | — |
| Window | Compliance Rules | — |

## Smoke

1. Menu → **Ability ERP → Compliance & Audit Hub → Compliance Summary** (or search; Find with empty criteria if 0/0)
2. Summary tab shows score / traffic light / totals
3. Breadcrumb **Summary ▼** → Employee / Client / Incidents / Rostering / Documentation — identical KPI field layout
4. **Compliance Rules** opens (empty until rules seeded)

## Dev install evidence (2026-07-16)

- Host `3.27.207.215` — SQL 00–10 applied; verify: 3 tables, 1 view, 4 AD tables, 2 windows, 6 summary tabs
- WebUI smoke (Admin / HCO): Summary KPIs 76.4 / Red / 1234; Employee tab 412/389/… layout OK

## Blockers / later

- Refresh process + Info Window not in skeleton
- Service Agreement source for Rule #4 TBD at Employee/Client view phase
- Support Location FK = `AbERP_Support_Location_ID` → `aberp_support_location`
