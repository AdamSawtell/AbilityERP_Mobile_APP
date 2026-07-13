# SAW016 — Checklist

## Staging (HCO Test `32.236.127.117`)

- [x] Preflight
- [x] Install SQL (table, AD, functions, line bridge, menu, report)
- [x] Review: SQL verify + WebUI smoke (window, summary, Leave Records tab)
- [x] Packs written to Downloads
- [ ] Mark done when packs ready + EXTERNAL-SUMMARY accepted

## Acceptance mapping

- [x] Leave Planning window
- [x] Date-only Start/End mandatory; DB CHECK End ≥ Start
- [x] One / many / All Locations (Chosen Multiple + All Locations)
- [x] Overlap matching; outside period excluded
- [x] No duplicate leave IDs on multi-location
- [x] Sort/group by Approver Status (OrderBy + grid)
- [x] Summaries by status and status+type; refresh on criteria save
- [x] Zoom to underlying leave (existing submit/approve)
- [x] Report process + grid export
- [x] Migration scripts under `idempiere-plugins/com.aberp.leave.planning/sql/`
