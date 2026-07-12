# SAW010 — Deploy to another build

**Ticket:** SAW010_timesheet_approval_info_columns · **Kind:** idempiere · **JAR:** No (this ticket)

## Agent one-liner

bash
cd idempiere-plugins/com.aberp.timesheet.approvalinfo
chmod +x deploy.sh && sudo ./deploy.sh
# Cache Reset / logout-in. No iDempiere restart for this SQL pack.


**Thin prod pack (preferred when present):**

Downloads\AbilityERP-ProdUpdate-SAW010_timesheet_approval_info_columns-*\ → 00-PREFLIGHT.sql, 01-APPLY.sql, 99-ROLLBACK.sql, HOW-TO.

## Package

idempiere-plugins/com.aberp.timesheet.approvalinfo/

Info Window UU: 40d6a2d7-3bbc-431e-940c-ce75829a68e4

## Ordered SQL

1. sql/00-preflight-uuids.sql  
2. sql/01-update-infocolumns.sql  
3. sql/02-verify.sql  
4. sql/03-functional-check.sql  
Optional staging seed: sql/04-seed-test-rows.sql  
Rollback: sql/99-rollback.sql

## Restart / cache

- **No** restart for this pack  
- **Yes** Cache Reset / logout-in

## WebUI smoke

1. Timesheet Approval Info: grid without Shift Cost / Name / Employee(Y/N) / Activity / BP columns.  
2. One staff column: Employee (User)/Agency Staff; Break Start/End after Shift Type.  
3. Filters still work; selecting a row opens **AbERP Set Timesheet Approved Status** dialog.

## Blockers / notes

- **Out of scope of this SQL pack:** process class com.aberp.timesheetapproval.processes.setstatus may be missing on the host (ClassNotFoundException). Restore/start that timesheet-approval process JAR separately, then retest approve end-to-end.  
- Preflight expects aberp_break_start / aberp_break_end columns to exist.


## AbilityERP Admin access (mandatory)

Install SQL / deploy must grant **AbilityERP Admin** access to every new or newly exposed **window**, **process**, **Info Window**, and **form** (and process access for toolbar buttons). See docs/DEV-REQUIREMENTS.md. After grant: Role Access Update or logout/in. Smoke as Admin.

## Packs

- Staging: AbilityERP-ClientUpdate-SAW010_timesheet_approval_info_columns-*  
- Prod: AbilityERP-ProdUpdate-SAW010_timesheet_approval_info_columns-*
