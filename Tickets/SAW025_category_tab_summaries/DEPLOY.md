# SAW025 — Deploy

## Plugin

`idempiere-plugins/com.aberp.compliance/`

## JAR

Yes — `com.aberp.compliance_7.1.0.202607170545.jar` (writes `PopulationCount` on refresh). Live population + KPIs also work from SQL view / ColumnSQL functions alone.

## Ordered SQL

1. `sql/35-category-population-summary.sql`
2. `sql/36-fix-population-client-90d.sql`
3. `sql/37-category-kpi-expansion.sql`

Or `deploy.sh` (includes 35→37).

## Restart / cache

OSGi install/start JAR if deploying engine change. After SQL 37: **restart iDempiere** (or Cache Reset + logout/in) so ColumnSQL updates are picked up.

## Smoke

1. Menu → Organisation Audit → Audit Hub → Find
2. **Employee**: Active Employees + Change (90d) + shared/category KPIs (Screening, Credentials %, etc.)
3. **Client**: Active Clients (~127) + Risk / No Support / Plans KPIs
4. **Incidents**: Active Incidents + Closed / Actions / Median Days Open
5. **Rostering**: Period shifts + Fill Rate % / Coverage 7–14d
6. **Documentation**: Total Documents + Current % / Onboarding Expired
7. Confirm **no SQL error modal** on any category tab

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
| Rostering | Shifts in current pay period | vs average of completed periods in last 90d |
| Documentation | Active credential assignments | same |

## KPI note (SQL 37)

Category KPIs are virtual `AD_Column.ColumnSQL` calling `aberp_compliance_*` DB functions. Nested `NOT EXISTS` / `ORDER BY` / `::date` arithmetic must stay inside those functions — iDempiere’s ColumnSQL parser mangles them if inlined.
