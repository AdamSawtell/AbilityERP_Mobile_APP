# SAW021 — Notes

## Investigation (develop `13.210.248.141`, 2026-07-14)

| Topic | Finding |
|-------|---------|
| Source table | `AbERP_OngoingUnavailability` UU `cda3018c-0390-48a5-99f4-fcc06a89f0de` (AD 1000212) |
| Dates | `StartDate` / `EndDate` (AD Date+Time 16); planning criteria Date (15) |
| Approver Status | Same list pattern as leave (`AbERP_ApproverStatus`) — mostly AP on this build |
| Submitter Status | `AbERP_SubmitterStatus` (sample all DR) |
| Employee | `AbERP_User_Contact_ID` → AD_User |
| Type | **No** `AbERP_Unavailability_Type_ID` on Ongoing |
| Child lines | `AbERP_UnavailableDays` — 14 Day Roster Period (1–15) + StartTime/EndTime; ~8 lines/header avg |
| Windows | Ongoing Unavailability `68bcd45c-…`; My Ongoing Unavailability `14d48d54-…` |
| Leave Planning present | Info UU `16a016iw-c0d4-4f01-8e15-000000000001` |
| Overlap Jan 2027 | 49 active headers |
| SSH | `ubuntu@13.210.248.141` + `%USERPROFILE%` path via `Documents\SSH Keys\HCObusiness.pem` |

## Design decisions (proposed — confirm before build)

1. **Primary UX = Info Window** (menu action `I`), same as SAW016 after UX revision — not a saved planning document.
2. **Clone JAR** from `com.aberp.leave.planning`: banner, Export CSV, status colours, Support Location EXISTS, Intbox `-1` sanitize, planning-date overlap rewrite.
3. Drop **Unavailability Type** criteria/columns; keep Planning Start/End, Support Location, Approver Status, Employee (+ grid display columns).
4. Zoom target = **Ongoing Unavailability** window (not Leave).
5. Optional v1.1 additions listed under **Proposed extras** — decide which are in-scope for first ship.

## Proposed extras (beyond straight Leave clone)

| Priority | Idea | Why |
|----------|------|-----|
| **P0 (recommend)** | Compact **Unavailable Days pattern** column (e.g. `01 Mon 07:00–11:00; 08 Mon 11:00–13:00`) via DB function | Headers alone hide the real pattern; planners need times/roster days |
| **P0 (recommend)** | Related Info / child view of day lines for selected header | Avg 8 lines/header — Zoom works but in-tool detail is faster |
| **P1** | Criteria: **Roster Day** (14-day period list) — who is unavailable on that pattern day | Matches how Unavailable Days are modelled |
| **P1** | Criteria: **Time window** (Start/End time) overlapping day-line StartTime/EndTime | Shift coverage planning |
| **P1** | **Clash indicator** — EXISTS rostered shift for employee in period that intersects unavailable day/time | Highest planner value; more SQL/JAR work |
| **P2** | Banner counts stay by Approver Status; secondary line “Avg days/header” or “With day lines / without” | Some headers have empty day tabs |
| **P2** | Open-ended / long-span flag (End − Start > N days or End far future) | Many rows are 2-year spans |
| **P2** | Report process (mirror Leave Planning Report) | Packs/print path |
| **Out of scope v1** | Combined Leave + Ongoing planning | Separate tickets / later merge Info |

## Scope recommendation for v1

Ship **parity with Leave Planning** + **pattern summary column** (function + AccessSqlParser-safe). Park clash detection and roster-day/time criteria unless explicitly requested.

## HCO Future Deployments variables

| Item | Value |
|------|--------|
| Host | `13.210.248.141` (develop / current HCO Test per SAW016 DEPLOY) |
| WebUI | `http://13.210.248.141/webui/` |
| Source table UU | `cda3018c-0390-48a5-99f4-fcc06a89f0de` |
| Zoom window UU | `68bcd45c-eec6-4e45-855c-0d4f0705aeb5` |
| Info Window UU | _(allocate AbERP-owned UU at pack time)_ |
| JAR | _(version after first build)_ |
