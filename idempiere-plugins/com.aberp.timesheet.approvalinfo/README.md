# Timesheet Approval Info Window — column cleanup (SAW010 / #901558)

Updates **Timesheet Approval** Info Window
(`AD_InfoWindow_UU = 40d6a2d7-3bbc-431e-940c-ce75829a68e4`).

## Changes

| Change | Detail |
|--------|--------|
| Hide from result grid | Shift Cost, Name, Employee (`IsEmployee`), Activity |
| Keep as filters | Activity, Employee (`IsEmployee`), Business Partner |
| Deduplicate staff | Keep **Employee (User) / Agency Staff**; hide Business Partner in grid |
| Add columns | **Break Start**, **Break End** after Shift Type (`t.AbERP_Break_*`, Date+Time) |

No physical table columns created. Approval process bind column
`AbERP_TimesheetAndExpenses_ID` is unchanged.

## Install

```bash
cd /opt/ability-erp-pwa/idempiere-plugins/com.aberp.timesheet.approvalinfo
chmod +x deploy.sh
sudo ./deploy.sh
```

Then **Cache Reset** (or log out/in).

Optional staging seed rows:

```bash
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/04-seed-test-rows.sql
```

## Rollback

```bash
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/99-rollback.sql
```

## Files

| File | Purpose |
|------|---------|
| `sql/00-preflight-uuids.sql` | Fail fast if Info Window / break cols / process bind missing |
| `sql/01-update-infocolumns.sql` | Hide columns + upsert Break Start/End |
| `sql/02-verify.sql` | Assert display flags and seqnos |
| `sql/03-functional-check.sql` | Sample query shape |
| `sql/04-seed-test-rows.sql` | Staging-only extra timesheets |
| `sql/99-rollback.sql` | Restore display + delete Break InfoColumns |
| `deploy.sh` | Apply migration on server |
