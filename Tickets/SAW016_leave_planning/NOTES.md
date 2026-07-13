# SAW016 — Notes

## Investigation (HCO Test 2026-07-13)

| Topic | Finding |
|-------|---------|
| Leave table | `AbERP_Unavailability_Leave` UU `a32f38ba-6067-4497-abdc-99e2a7d01a1b` |
| Dates | `StartDate` / `EndDate` (AD ref Date+Time 16 on leave; planning uses Date 15) |
| Approver Status | List `AbERP_ApproverStatus_List`: RV=Reviewing, AP=Approved, DC=Declined |
| Submitter Status | DR=Draft, SB=Submitted |
| Leave type | `AbERP_Unavailability_Type_ID` → Annual / Personal / LSL / … |
| Employee | `AbERP_User_Contact_ID` → AD_User |
| Supervisor | ColumnSQL via BP.Supervisor_ID |
| Service location | **Mismatch fixed 2026-07-13:** was `AD_User.C_BPartner_Location_ID` (home address). Correct = Support Locations via rostered shifts (`ShiftStaff → Shift → MasterLocation → Support Location`). Lookup lists active Support Locations; filter uses EXISTS on that path. |
| Submit | Process `SUBMIT_LEAVE` / classname `com.aberp.rostering.processes.submitleave` |
| Approval | Edit Approver Status (no separate leave approval process/workflow) |
| Multi-location storage | Chosen Multiple Selection Table on planning header (`C_BPartner_Location_IDs`) |
| Reporting | Grid export + report process `AbERP_LeavePlanning_Report` |

## Design decisions (revised after UX review)

1. **Primary UX = Info Window** (not a saved planning document). Static criteria → Search → results. Menu action `I`.
2. Record window (`16a01602-…`) soft-retired — was wrong pattern (1-of-N / New / Save).
3. **Service Location:** Info Multi Select (`200138` + All/Any) is a cramped weird editor and can emit `-1` when empty. Switched to **optional Table Direct** — blank = all locations. Multi-location = Search per site or use the Report (custom taller multi later via JAR if planners need it).
4. Summaries: query-scoped totals (Approver Status / Status+Type). Related Info is row-linked, so prefer a **Java InfoWindow banner** (Staff Rostering style) after Search — not header ColumnSQL on a planning record.
5. Edit/action leave via Zoom — reuse Submit Leave + Approver Status.

## HCO smoke

- 2026-07-13 (record window): Jan 2027 + All Locations → 23 leave rows; summaries worked.
- 2026-07-13 (Info Window): installed UU `16a016iw-…`; Service Locations ref-value fix applied (`12-fix-info-locations.sql`). WebUI re-smoke pending Cache Reset / login.
- 2026-07-13 (banner + readonly): JAR `1.0.0.2026071322` + `14`/`15` SQL. Jan 2027 Search → banner Approved 21 / Declined 2 / Total 23; grid editors = 0 on selected row.

## HCO Future Deployments variables

| Item | Value |
|------|--------|
| Host | `32.236.127.117` |
| WebUI | `http://32.236.127.117/webui/` |
| Info Window UU | `16a016iw-c0d4-4f01-8e15-000000000001` |
| Window UU (retired) | `16a01602-c0d4-4f01-8e15-000000000001` |
| Table UU | `16a01601-c0d4-4f01-8e15-000000000001` |
| Line table UU | `16a0160b-c0d4-4f01-8e15-000000000001` |
| Process UU | `16a01608-c0d4-4f01-8e15-000000000001` |
| JAR | `com.aberp.leave.planning_1.0.0.2026071332.jar` |
| Require-Bundle | `zul` + `zk` (Export CSV uses `Filedownload.save(byte[])` — no `zcommon`/`AMedia`) |
| Service Location display | `aberp_lp_primary_support_location(u.AD_User_ID)` |

## 2026-07-13 — Media ClassNotFound

Opening Info Windows on HCO threw `org/zkoss/util/media/Media` attributed to `com.aberp.leave.planning` (Export CSV uses `AMedia`). Fix: use `Filedownload.save(byte[])` — no `zcommon`/`AMedia`. Confirmed Export CSV no longer raises Media CNFE.

## 2026-07-13 — Search IllegalArgumentException (AccessSqlParser)

Nested `SELECT` in InfoColumn `selectclause` for Service Location broke `AccessSqlParser.getSelectStatements` (even without `string_agg` commas). Fix: `sql/22-primary-location-function.sql` → function `aberp_lp_primary_support_location(numeric)`; selectclause = `aberp_lp_primary_support_location(u.AD_User_ID)`. Restart / Cache Reset after AD change.

