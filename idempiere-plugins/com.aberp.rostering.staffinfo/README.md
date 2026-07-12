# AbERP Rostering Staff Info — performance rewrite + Java UX

Package that rewrites **Employee (User) / Agency Staff Rostering Info**
(`AD_InfoWindow_UU = 2b4ab146-0809-47c6-96f3-8b841d60a6bf`) used on
**Shift (Rostered) → Employee → Employee (User) / Agency Staff**.

Includes SQL AD changes plus a small OSGi bundle (`IInfoFactory` + `IColumnCalloutFactory`).

## What it changes

| Before | After |
|--------|--------|
| 9-table join fan-out + `DISTINCT` | `AD_User` + `C_BPartner` (+ optional `C_Job`) |
| Leave / credentials / needs / BI view in FROM | EXISTS filters; Java injects leave/overlap + needs match |
| Manual `%` wildcards on Like | Auto-`%` wrap in `StaffRosteringInfoWindow` |
| BP empty until save | Callout fills virtual BP display on contact pick |
| Shift/staff on org `*` | Migration + org sync trigger + callout (`06`/`10`) |
| Related Info off | Rostered Shift / Credentials / Alerts on (`08`) |

**On Approved Leave** (default **N**) is a CURRENT_DATE filter. When the Info is opened from
a Shift with Start/End dates, Java also hides staff on approved leave overlapping that
window and staff already rostered on an overlapping non-template shift — without putting
`@StartDate@` into AD WhereClause.

**Related Rostering Needs** (credentials / gender / restricted employee from
`AbERP_Related_Rostering_Needs_V`) are matched the same way: default shows only matching
staff. **Show Unmatched Staff** (default **N**) includes people who do not meet those needs.
The top banner shows shift document, date/time range, and a needs summary.

## Requirements

- Target DB already has this AbERP Info Window (same UUID).
- PostgreSQL + iDempiere 7.1 with `adempiere` schema.
- Deploy restarts iDempiere (OSGi).

## Build / Install

```bash
cd idempiere-plugins/com.aberp.rostering.staffinfo
chmod +x build.sh deploy.sh
./deploy.sh
```

Applies SQL via `deploy.sh` (`01`→`20`→`04`), installs OSGi jar, restarts iDempiere.

Then **Cache Reset** (or log out/in). **Do not** wipe the full OSGi configuration cache.

Current bundle version: **`1.1.0.2026071220`**.

Agent handoff: repo `Tickets/SAW003_staff_rostering_info/DEPLOY.md` and this package’s `DEPLOY.md`.

## Result grid (lean pick list)

After `sql/20-hide-clutter-columns.sql` (must run **last** before verify):

- Hidden from the **line**: BP Name, Status, Business Partner, Agency Staff – Approved for shifts
- Agency Staff remains a **filter criterion** only
- `C_BPartner_ID` stays active for Related Info (just not displayed)
- Criteria label **Staff Name**; Show Unmatched / Show Unavailable layout from `19` + Java

## Rollback

```bash
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/99-rollback.sql
# then remove the OSGi jar / bundles.info entry and restart
```

## Files

| File | Purpose |
|------|---------|
| `src/.../info/StaffRosteringInfoWindow.java` | Auto-`%`, banner, leave/overlap, needs match, criteria layout |
| `src/.../factory/StaffRosteringInfoFactory.java` | `IInfoFactory` |
| `src/.../callout/CalloutShiftStaffContact.java` | BP + org on contact change |
| `src/.../factory/StaffRosteringCalloutFactory.java` | `IColumnCalloutFactory` |
| `sql/01`–`17` | AD rewrite, indexes, org, eligibility, UX, needs tickbox, criteria fixes |
| `sql/18-fix-result-grid-readonly.sql` | Selected-row display-only |
| `sql/19-rename-staff-name.sql` | Staff Name label |
| `sql/20-hide-clutter-columns.sql` | Hide clutter columns from result grid |
| `sql/99-rollback.sql` | Restore prior join-based definition |
| `release/*_1.1.0.2026071219.jar` | Pack / install JAR |
