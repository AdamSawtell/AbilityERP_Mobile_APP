# SAW010 CHECKLIST

## Preflight / implement

- [x] Allocate SAW010 + GitHub issue #10
- [x] Discover AD_InfoWindow / InfoColumns / process bind / break columns
- [x] Migration SQL (UUID-safe) in `idempiere-plugins/com.aberp.timesheet.approvalinfo/`
- [x] Install on staging (`deploy.sh`)
- [x] Optional seed test rows
- [x] Cache Reset
- [x] WebUI smoke: columns, filters, breaks, approval process dialog
- [x] Staging + prod Downloads packs
- [x] Commit + push

## Acceptance

- [x] Shift Cost, Name, Employee, Activity not in result grid
- [x] Only Employee (User)/Agency Staff visible for staff (not Business Partner)
- [x] Break Start / Break End after Shift Type with Date+Time formatting
- [x] Search filters still present (Activity, Employee, Business Partner, dates, etc.)
- [x] Approval process dialog opens on selected row (Timesheet ID bind intact)
- [x] No SQL/UI errors from Info Window query
- [~] Process class execution: **blocked on staging** by pre-existing `ClassNotFoundException: com.aberp.timesheetapproval.processes.setstatus` (JAR not installed; historical PInstances from 2024 succeeded when class was present)

## Packs

- Staging: `C:\Users\sawte\Downloads\AbilityERP-ClientUpdate-SAW010_timesheet_approval_info_columns-20260712`
- Prod: `C:\Users\sawte\Downloads\AbilityERP-ProdUpdate-SAW010_timesheet_approval_info_columns-20260712`
