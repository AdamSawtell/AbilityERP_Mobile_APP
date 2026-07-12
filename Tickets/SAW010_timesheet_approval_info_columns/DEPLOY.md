# SAW010 — Deploy to another build (agent)

**Ticket / slug:** `SAW010_timesheet_approval_info_columns`  
**Kind:** idempiere · **JAR:** No (this ticket) · **Status:** done (columns)

## Required host access

- SSH · `psql` · WebUI Admin · Cache Reset  
- Optional E2E approve: timesheet-approval **process plugin JAR** must already be on the host

## Agent one-liner

```bash
cd idempiere-plugins/com.aberp.timesheet.approvalinfo
chmod +x deploy.sh && sudo ./deploy.sh
# Cache Reset / logout-in. No restart for this SQL pack.
```

Prefer thin prod pack if present: `Downloads\AbilityERP-ProdUpdate-SAW010_timesheet_approval_info_columns-*\`

## Package

`idempiere-plugins/com.aberp.timesheet.approvalinfo/`  
Info Window UU: `40d6a2d7-3bbc-431e-940c-ce75829a68e4`

## Ordered SQL (`deploy.sh`)

1. `sql/00-preflight-uuids.sql`  
2. `sql/01-update-infocolumns.sql`  
3. `sql/02-verify.sql`  
4. `sql/03-functional-check.sql`  

Optional staging seed only: `sql/04-seed-test-rows.sql` (**hardcodes client/org — do not run on foreign clients**).  
Rollback: `sql/99-rollback.sql`

## AbilityERP Admin access

No new window. Updates existing Timesheet Approval Info. Admin needs existing Info access. Approve button needs process access + process JAR. Smoke columns **as Admin**.

## Blocker (separate from this pack)

`ClassNotFoundException: com.aberp.timesheetapproval.processes.setstatus` → restore/start timesheetapproval process plugin; out of scope of this SQL pack.

## WebUI smoke

Grid without removed columns; Break Start/End after Shift Type; filters work; select row opens Set Timesheet Approved Status dialog (execute may still need process JAR).

## Packs

- Staging + Prod Downloads folders `AbilityERP-*-SAW010_timesheet_approval_info_columns-*`

## External ticket text

`Tickets/SAW010_timesheet_approval_info_columns/EXTERNAL-SUMMARY.md`
