# SAW010 NOTES

## Existing configuration (staging)

- **Info Window:** Timesheet Approval — UU `40d6a2d7-3bbc-431e-940c-ce75829a68e4` (seed ID 1000033)
- **Base table:** `AbERP_TimesheetAndExpenses` (not a view); custom FROM with aliases `t`, `u`, `bp`
- **FROM:**
  ```
  AbERP_TimesheetAndExpenses t
  LEFT OUTER JOIN ad_user u ON (t.AbERP_User_Contact_ID = u.ad_user_id AND u.IsActive='Y')
  LEFT OUTER JOIN C_BPartner bp ON (bp.C_BPartner_ID=u.C_BPartner_ID AND bp.IsActive='Y')
  ```
- **Process:** AbERP Set Timesheet Approved Status (`com.aberp.timesheetapproval.processes.setstatus`, UU `3a3c2c41-995c-41ba-9fde-caeaacee1d75`)
  - Parameter: `R_Status_ID` only
  - InfoProcess binds to InfoColumn `AbERP_TimesheetAndExpenses_ID` (hidden) — **do not remove**

## Break fields

| UI label | Physical column | AD_Element UU | Reference |
|----------|-----------------|---------------|-----------|
| Break Start | `aberp_timesheetandexpenses.aberp_break_start` | `27c45dc9-aaef-40cb-8306-a2f5ebdeae2b` | Date+Time (16) |
| Break End | `aberp_timesheetandexpenses.aberp_break_end` | `ad62182e-9dfb-46e5-9f2b-89a3232276ca` | Date+Time (16) |

Select clauses: `t.AbERP_Break_Start`, `t.AbERP_Break_End`. No new DB columns.

## Employee column retained

**Retained in grid:** Employee (User) / Agency Staff (`t.AbERP_User_Contact_ID`)

**Why:** Direct staff assignment on the timesheet; label already covers employees and agency staff. Business Partner (`u.C_BPartner_ID`) is derived via the user join and duplicates the same person for employees. Business Partner remains available as a **search filter** only.

**Also hidden from grid (req #1):** Employee Yes/No (`bp.IsEmployee`) — kept as filter.

## Display seq after change

| seqno | Column | Displayed |
|-------|--------|-----------|
| 10 | Employee (User) / Agency Staff | Y |
| 30 | Start Date | Y |
| 50 | End Date | Y |
| 70 | Shift Type | Y |
| 72 | Break Start | Y (new) |
| 74 | Break End | Y (new) |
| 90 | Contract Location | Y |
| 100 | Description | Y |
| 110 | Status | Y |
| 140 | Supervisor | Y |
| (hidden) | Timesheet ID | N (process key) |

## Assumptions / issues

- Staging DB had only one live timesheet before seed; used `04-seed-test-rows.sql` for no-break + agency-style coverage.
- Approved/unapproved UI statuses for this process on staging are `10_Pending` / `20_Complete` (val rule 1000052), not a free-text "Approved" name.

## Client-build follow-up: timesheet approval process JAR

**Review when testing on the client build** (not blocked for SAW010 column pack).

| | |
|--|--|
| **Symptom (staging)** | WebUI: `Failed to create new process instance for com.aberp.timesheetapproval.processes.setstatus` |
| **Root cause** | `ClassNotFoundException` — OSGi class / JAR not present on this staging host |
| **AD still OK** | InfoProcess binds to hidden `AbERP_TimesheetAndExpenses_ID`; dialog opens; Status para works |
| **History** | AD_PInstance rows from Jan 2024 show the process succeeded when the class was deployed |
| **Client check** | Confirm `com.aberp.timesheetapproval` (or equivalent) is installed/started; run **AbERP Set Timesheet Approved Status** end-to-end on Timesheet Approval |
| **SAW010 pack** | Does **not** include this JAR — AD/SQL only |

## WebUI smoke (2026-07-12 staging)

| Check | Result |
|-------|--------|
| Cache Reset | Pass (session timeout after reset expected) |
| Grid missing Shift Cost / Name / Employee / Activity / Business Partner | Pass |
| Grid has Employee (User)/Agency Staff only for staff | Pass |
| Break Start / Break End after Shift Type (Date+Time) | Pass (with-break + blank no-break rows) |
| 3 rows (employee + agency seed + no-break) | Pass |
| Filters still shown | Pass |
| Select row → Set Timesheet Approved Status dialog | Pass |
| Process execute to completion | Fail — ClassNotFoundException (pre-existing missing JAR) |
