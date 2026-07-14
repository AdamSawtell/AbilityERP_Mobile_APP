# SAW021 — Unavailability Planning

| | |
|--|--|
| **Status** | in-progress |
| **Kind** | idempiere |
| **GitHub** | [#21](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/21) |
| **Slug** | `SAW021_unavailability_planning` |
| **JAR** | Planned: `com.aberp.unavailability.planning` (clone of Leave Planning Info UX) |
| **Environment** | Develop / HCO Test `13.210.248.141` (SSH key `HCObusiness.pem`) |

## Deploy

See [`DEPLOY.md`](DEPLOY.md).

## External ticket

See [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md).

## Goal

Workforce **Unavailability Planning** Info Window using the same framework as **SAW016 Leave Planning**, sourced from `AbERP_OngoingUnavailability`:

- Mandatory planning period (date-only Start/End)
- Overlap matching (`end ≥ period start` AND `start ≤ period end`)
- Same search/filter criteria family as Leave Planning (Support Location, Approver Status, Employee; no Leave Type — that column does not exist on Ongoing)
- Summary banner by Approver Status + Export CSV + Zoom to Ongoing Unavailability for submit/approve
- Grid of matching unavailability headers for the period

## Source of truth

- Planned: `idempiere-plugins/com.aberp.unavailability.planning/`
- Pattern reference: `idempiere-plugins/com.aberp.leave.planning/` (SAW016)

## Dependencies (app)

None.

## Key data facts (13.210.248.141, 2026-07-14)

| Item | Value |
|------|--------|
| Table | `AbERP_OngoingUnavailability` UU `cda3018c-0390-48a5-99f4-fcc06a89f0de` |
| Child days | `AbERP_UnavailableDays` (14-day roster day + Start/End time) |
| Window | **Ongoing Unavailability** UU `68bcd45c-eec6-4e45-855c-0d4f0705aeb5` |
| Rows | ~70 headers, ~541 day lines (~8/header) |
| Jan 2027 overlap | 49 active headers |
| Type column | **None** (unlike Leave) |
