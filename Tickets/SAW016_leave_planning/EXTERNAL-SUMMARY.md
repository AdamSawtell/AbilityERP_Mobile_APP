# Leave Planning — external summary

## Windows / processes / objects affected

| Object | Type | Change |
|--------|------|--------|
| **Leave Planning** | Info Window | Primary UX: planning period + optional Support Location, overlapping leave grid |
| **Leave Planning** | Window (record) | Soft-retired; keep for AD/report bridges if present |
| **Leave Planning Report** | Process (report) | Print/export by planning period |
| `AbERP_Leave_Planning` / `_Line` | Tables | Planning header + bridge lines (zoom) |
| `aberp_lp_primary_support_location` | DB function | Grid Support Location (roster primary site) |
| `aberp_lp_summary_by_*` | DB functions | Banner / summary totals |
| Menu **Leave Planning** | Menu | Opens Info Window |

**AbilityERP Admin** (and Admin / Rostering / P&C roles where granted) can open Leave Planning after Cache Reset / re-login.

## What’s done

A consolidated **Leave Planning** Info view: set a date period, optionally filter by **Support Location** (rostered site — blank = all), see who is on leave, review status colours / banner links, Export CSV, and Zoom to the real leave record.

## What changed (behaviour)

- Overlap: leave start ≤ period end AND leave end ≥ period start.
- Support Location filter uses roster path (ShiftStaff → Shift → MasterLocation → Support Location), not home address.
- Approver Status: **Reviewing / Approved / Declined** as configured on leave.
- Submit Leave remains the existing process on the leave record.

## Impact

Planners can filter leave for a month and site without browsing Unavailability & Leave. Existing leave security and submit/approve rules are unchanged.

## How to test

1. Open **Leave Planning** (Info).
2. Set Start/End (e.g. Jul 2026), leave Support Location blank → ReQuery → rows appear.
3. Pick a Support Location via Search → ReQuery → narrower set; no “non-negative number” popup.
4. Use banner status links; confirm colours; Export CSV; Zoom a leave row.
5. Return after changing Approver Status on a leave and re-search.
