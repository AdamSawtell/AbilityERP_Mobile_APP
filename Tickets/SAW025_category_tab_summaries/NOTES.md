# SAW025 — Notes

- Live counts come from the dashboard view (no refresh required to see current population).
- **Active Clients** = `AbERP_IsSupport_Receiver='Y'` (same as Client window) — not all `IsCustomer` BPs.
- **Change (90d)** = current − baseline. Baseline prefers a snapshot with `PopulationCount` from ≤90 days ago; until that exists, baseline = population members with `Created` ≤ today−90 (so change = net additions still active). Rostering instead shows the current and immediately next pay/roster periods.
- Seed on install writes today’s population onto the latest snapshots.
- **SQL 37 KPIs** use `AD_Column.ColumnSQL` → `aberp_compliance_*` functions. Do **not** put nested `NOT EXISTS`, `ORDER BY`, or `CURRENT_DATE - timestamp` (without safe casting) directly in ColumnSQL — iDempiere’s parser mangles them (`Could not remove`, `COALESCE types interval and integer`).

## Ticket boundary (2026-07-19)

- **SAW025** = category KPIs / summaries / progressive layout (SQL 35–39)
- **SAW024** = Findings navigation including SQL 40 (parent-only Findings visibility). Population columns from this ticket are a dependency for that DisplayLogic.

## Unsupported / substituted metrics

| Ask | What we ship instead |
|-----|----------------------|
| Missing service agreements | Plans/assessments + risk coverage (SA table has no usable BP/date linkage on this build) |
| Mandatory credential set % | Credentials Current % / onboarding docs (no mandatory flag on credentials) |

## Smoke (dev `3.27.207.215`)

- 2026-07-17 initial: Employee 210 / Change 0 (snapshot-only baseline)
- **2026-07-17 fix (SQL 36):** Clients **127** (+11), Employees 210 (+3), Incidents 83 (+31), Period shifts 1866 (−91), Documents 9062 (+512)
- **SQL 38:** Rostering tab metrics are scoped to **current + next pay/roster period** only. Calendar 7d/14d coverage and the 90d period-average pair are removed from that tab.
- Spot check after SQL 38: Current Roster **1866** / Next **1777**; Current Fill **98.0%** / Next **96.3%**.
- **SQL 39:** the lead page and all five category form views show open **At a glance** / **Action required** sections with persistent explainers. **Trends and ageing** / **Compliance breakdown** are collapsed by default. Browser smoke passed with no SQL modal.
