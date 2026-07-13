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

## Design decisions

1. Header table + bridge line table (trigger refresh) so child tab has a real parent link.
2. Summaries via DB functions (AccessSqlParser rejects nested FROM in ColumnSQL).
3. Menu at tree parent `-1` like other Unavailability menus (under Rostering alone was hard to find).
4. Edit/action leave via Zoom to Unavailability & Leave (preserves Submit Leave + status rules).

## HCO smoke (2026-07-13)

- Window opens; summaries show Approved/Declined counts for Jan 2027.
- Leave Records: 23 overlapping rows; Service Location / Calendar Days / Approver Status visible.
- Export toolbar present on window.

## HCO Future Deployments variables

| Item | Value |
|------|--------|
| Host | `32.236.127.117` |
| WebUI | `http://32.236.127.117/webui/` |
| Window UU | `16a01602-c0d4-4f01-8e15-000000000001` |
| Table UU | `16a01601-c0d4-4f01-8e15-000000000001` |
| Line table UU | `16a0160b-c0d4-4f01-8e15-000000000001` |
| Process UU | `16a01608-c0d4-4f01-8e15-000000000001` |
