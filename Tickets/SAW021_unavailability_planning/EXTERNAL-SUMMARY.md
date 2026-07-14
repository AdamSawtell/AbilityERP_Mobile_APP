# Unavailability Planning — external summary

## Windows / processes / objects affected

| Object | Type | Change |
|--------|------|--------|
| **Unavailability Planning** | Info Window | New planning search (criteria + results) |
| `AbERP_OngoingUnavailability` | Table (source) | Queried; not structurally changed |
| `AbERP_UnavailableDays` | Child table | Shown via Zoom / optional pattern summary |
| Menu **Unavailability Planning** | Menu | New (Info action) |
| Export CSV | Toolbar action (JAR) | Download matching rows |
| Report process (optional) | Process | Print/export if included in delivery |

**AbilityERP Admin** (and operational Admin / Rostering / P&C roles) can open the Info Window after Cache Reset / re-login.

## What’s done

Consolidated **Unavailability Planning** view for workforce planners: choose a date period and optional Support Location, see who has ongoing unavailability overlapping that period (including compact unavailable day/time patterns), review totals by Approver Status and day-line counts, open the real Ongoing Unavailability record to submit/approve, and export.

## What changed (behaviour)

- Matching uses overlapping dates (`unavailability start ≤ period end` AND `unavailability end ≥ period start`).
- Service location filter follows the same rostered Support Location path as Leave Planning (blank = all locations, subject to org/role security).
- Ongoing Unavailability does **not** use Leave Type — filters are period, location, Approver Status, and Employee.
- Submit / Approver Status remain on the underlying Ongoing Unavailability record.

## Impact

Planners can filter ongoing unavailability for a month and location without browsing the full Ongoing Unavailability list. Existing security and submit/approve rules are unchanged.

## How to test

1. Open **Unavailability Planning**.
2. Set Start/End (e.g. 01/01/2027–31/01/2027), leave Support Location blank, Search.
3. Confirm summary banner and result grid.
4. Zoom a row → Ongoing Unavailability (Unavailable Days tab still available).
5. Filter by Approver Status or Employee; Export CSV.
