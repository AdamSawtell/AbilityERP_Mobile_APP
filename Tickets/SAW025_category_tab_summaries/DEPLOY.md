# SAW025 — Deploy

## Plugin

`idempiere-plugins/com.aberp.compliance/`

## JAR

Yes — `com.aberp.compliance_7.1.0.202607170545.jar` (writes `PopulationCount` on refresh). Live population + KPIs also work from SQL view / ColumnSQL functions alone.

## Ordered SQL

1. `sql/35-category-population-summary.sql`
2. `sql/36-fix-population-client-90d.sql`
3. `sql/37-category-kpi-expansion.sql`
4. `sql/38-roster-current-next-period.sql`
5. `sql/39-category-progressive-explainers.sql`

Or `deploy.sh` (includes 35→39 for this ticket; SQL 40 is **SAW024** Findings navigation and runs after 39 when using the full script).

## Restart / cache

OSGi install/start JAR if deploying engine change. After SQL 37–39: **restart iDempiere** (or Cache Reset + logout/in) so ColumnSQL and field-layout updates are picked up.

## Smoke

1. Menu → Organisation Audit → Audit Hub → Find
2. On the lead page, confirm visible explanations for readiness, totals, exceptions and refresh
3. **Employee**: Active Employees + Change (90d) + shared/category KPIs (Screening, Credentials %, etc.)
4. **Client**: Active Clients (~127) + Risk / No Support / Plans KPIs
5. **Incidents**: Active Incidents + Closed / Actions / Median Days Open
6. **Rostering**: **Current Roster | Next Roster**; fill/unfilled/filled/cancelled/missing-cred pairs for those two periods only (no 7d/14d)
7. **Documentation**: Total Documents + Current % / Onboarding Expired
8. In form view, confirm **At a glance** and **Action required** are open
9. Confirm persistent calculation explanations appear below the primary metric rows
10. Confirm **Trends and ageing** + **Compliance breakdown** are collapsed
11. Confirm **no SQL error modal** on any category tab

Findings tab visibility / Open & Fix: see **SAW024** `DEPLOY.md`.

## AbilityERP Admin access

No new windows/processes. Existing grants cover NDIS Audit Tool + Refresh Compliance.

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |

## Population definitions

| Tab | Count | Change (90d) |
|-----|-------|--------------|
| Employee | Active employees (`AD_User` + `C_BPartner.IsEmployee`) | current − members Created ≤ today−90 (or snapshot ≤90d) |
| Client | Active support receivers (`AbERP_IsSupport_Receiver=Y`) | same |
| Incidents | Open (non-closed) active incidents | same |
| Rostering | Shifts in current pay period | Next Roster uses the immediately following pay period |
| Documentation | Active credential assignments | same |

## KPI note (SQL 37)

Category KPIs are virtual `AD_Column.ColumnSQL` calling `aberp_compliance_*` DB functions. Nested `NOT EXISTS` / `ORDER BY` / `::date` arithmetic must stay inside those functions — iDempiere’s ColumnSQL parser mangles them if inlined.
