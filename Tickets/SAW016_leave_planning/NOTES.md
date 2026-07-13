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
| Service location | Employee Partner Location `AD_User.C_BPartner_Location_ID` (single active location per user; 233 distinct on HCO) |
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
