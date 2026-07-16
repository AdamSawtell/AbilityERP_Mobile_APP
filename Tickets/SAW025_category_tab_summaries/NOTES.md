# SAW025 — Notes

- Live counts come from the dashboard view (no refresh required to see current population).
- **Active Clients** = `AbERP_IsSupport_Receiver='Y'` (same as Client window) — not all `IsCustomer` BPs.
- **Change (90d)** = current − baseline. Baseline prefers a snapshot with `PopulationCount` from ≤90 days ago; until that exists, baseline = population members with `Created` ≤ today−90 (so change = net additions still active). Rostering uses current period vs average of completed pay periods in the last 90 days.
- Seed on install writes today’s population onto the latest snapshots.
- **SQL 37 KPIs** use `AD_Column.ColumnSQL` → `aberp_compliance_*` functions. Do **not** put nested `NOT EXISTS`, `ORDER BY`, or `CURRENT_DATE - timestamp` (without safe casting) directly in ColumnSQL — iDempiere’s parser mangles them (`Could not remove`, `COALESCE types interval and integer`).

## Unsupported / substituted metrics

| Ask | What we ship instead |
|-----|----------------------|
| Missing service agreements | Plans/assessments + risk coverage (SA table has no usable BP/date linkage on this build) |
| Mandatory credential set % | Credentials Current % / onboarding docs (no mandatory flag on credentials) |

## Smoke (dev `3.27.207.215`)

- 2026-07-17 initial: Employee 210 / Change 0 (snapshot-only baseline)
- **2026-07-17 fix (SQL 36):** Clients **127** (+11), Employees 210 (+3), Incidents 83 (+31), Period shifts 1866 (−91), Documents 9062 (+512)
- **2026-07-17 KPI expansion (SQL 37):** all five category tabs load population + shared + category KPIs with **no SQL modal**. Spot checks: Active Clients 127; Employee Screening Expired 8; Roster Fill Rate 98.0%; Client No Support (30d) 85; Incident Median Days Open ~106.5; Doc Current % ~98.5
- JAR `com.aberp.compliance_7.1.0.202607170545`
