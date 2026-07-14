# Leave Planning — external summary

## Windows / processes / objects affected

| Object | Type | Change |
|--------|------|--------|
| **Leave Planning** | Window | New lead window (criteria + summaries) |
| **Leave Records** | Tab | Child tab of matching leave (bridge lines → zoom to leave) |
| **Leave Planning Report** | Process (report) | Print/export by planning period + locations |
| `AbERP_Leave_Planning` | Table | Planning criteria header |
| `AbERP_Leave_Planning_Line` | Table | Non-duplicating links to leave rows |
| `aberp_lp_summary_by_*` | DB functions | Summary text on header |
| Menu **Leave Planning** | Menu | New (root menu tree) |

**AbilityERP Admin** (and operational Admin / Rostering / P&C roles on HCO) can open the window and report after Cache Reset / re-login.

## What’s done

A consolidated **Leave Planning** view for workforce planners: choose a date period and service locations (or All Locations), see who is on leave, review totals by Approver Status and leave type, open the real leave record to submit/approve, and export/print.

## What changed (behaviour)

- Matching uses overlapping dates (`leave start ≤ period end` AND `leave end ≥ period start`).
- Service location = employee **Partner Location** (`AD_User.C_BPartner_Location_ID`). One leave row per employee leave (no duplicates if multiple locations selected).
- Approver Status values as configured: **Reviewing / Approved / Declined** (not a separate approval workflow).
- Submit Leave remains the existing button/process on the leave record.

## Impact

Planners can filter leave for a month and location set without browsing the full Unavailability & Leave list. Existing leave security and submit/approve rules are unchanged.

## How to test

1. Open **Leave Planning**.
2. Set Start/End (e.g. 01/01/2027–31/01/2027), tick **All Locations**, save.
3. Confirm summaries and **Leave Records** list.
4. Zoom a leave row → change Approver Status or run Submit Leave if authorised → return and refresh planning.
5. Export from the grid or run **Leave Planning Report**.
