# SAW025 — Notes

- Live counts come from the dashboard view (no refresh required to see current population).
- **Active Clients** = `AbERP_IsSupport_Receiver='Y'` (same as Client window) — not all `IsCustomer` BPs.
- **Change (90d)** = current − baseline. Baseline prefers a snapshot with `PopulationCount` from ≤90 days ago; until that exists, baseline = population members with `Created` ≤ today−90 (so change = net additions still active). Rostering uses current period vs average of completed pay periods in the last 90 days.
- Seed on install writes today’s population onto the latest snapshots.

## Smoke (dev `3.27.207.215`)

- 2026-07-17 initial: Employee 210 / Change 0 (snapshot-only baseline)
- **2026-07-17 fix (SQL 36):** Clients **127** (+11), Employees 210 (+3), Incidents 83 (+31), Period shifts 1866 (−91), Documents 9062 (+512)
- JAR `com.aberp.compliance_7.1.0.202607170545`
