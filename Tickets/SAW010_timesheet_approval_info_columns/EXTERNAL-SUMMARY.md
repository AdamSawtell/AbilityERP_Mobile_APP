# SAW010 — External ticket update (copy/paste)

**Status:** Ready for client install (Info Window columns)  
**Area:** iDempiere — Timesheet Approval Info Window  
**Internal ID:** SAW010_timesheet_approval_info_columns  
**Source request:** #901558

## Windows / processes / objects affected

| Type | Name | Change |
|------|------|--------|
| **Info Window** | Timesheet Approval | Updated — column layout / Break Start & End |
| **Info columns (grid)** | Shift Cost, Name, Employee (Y/N), Activity, Business Partner | Hidden from result grid (filters may remain) |
| **Info column (grid)** | Employee (User) / Agency Staff | Retained as the staff column |
| **Info columns (grid)** | Break Start, Break End | **Added** after Shift Type |
| **Process** | AbERP Set Timesheet Approved Status | Unchanged bind — still launched from Info (needs process JAR on host) |
| **Window / Menu** | *(none new)* | Existing Timesheet Approval Info entry |

**Admin access:** AbilityERP Admin can open the Info Window; approve process requires Admin (or granted role) process access **and** the timesheet-approval plugin JAR.

---

## What’s been done

The **Timesheet Approval** Info Window result grid has been cleaned up: unused columns removed, staff shown once under Employee (User)/Agency Staff, and **Break Start** / **Break End** added after Shift Type.

## What changed

- Removed from the result grid: Shift Cost, Name, Employee (Y/N), Activity, and Business Partner (as a grid column)
- Kept one staff column: **Employee (User) / Agency Staff**
- Added **Break Start** and **Break End** (existing break fields on the timesheet)
- Search filters for the removed concepts can remain available where useful
- Approval process bind to the timesheet ID is preserved

## Impact

- Users who approve or review timesheets via this Info Window
- Clearer grid; break times visible without opening every record

## How to test

1. Log in as AbilityERP Admin.
2. Open **Timesheet Approval** Info Window.
3. Confirm the grid no longer shows the removed columns.
4. Confirm Break Start/End appear after Shift Type and look correct.
5. Confirm filters still work.
6. Select a row and open **AbERP Set Timesheet Approved Status** — dialog should open.

## Notes / caveats

- Completing the approve action needs the timesheet-approval **process plugin JAR** on the server. If you see a class-not-found error when running approve, restore/start that plugin separately — this ticket’s pack only updates the Info Window columns.
- After install: Cache Reset or log out/in.
