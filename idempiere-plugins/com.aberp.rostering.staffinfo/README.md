# AbERP Rostering Staff Info — performance rewrite

Standalone package that rewrites **Employee (User) / Agency Staff Rostering Info**
(`AD_InfoWindow_UU = 2b4ab146-0809-47c6-96f3-8b841d60a6bf`) used on
**Shift (Rostered) → Employee → Employee (User) / Agency Staff**.

## What it changes

| Before | After |
|--------|--------|
| 9-table join fan-out + `DISTINCT` | `AD_User` + `C_BPartner` (+ optional `C_Job`) |
| Leave / credentials / needs / BI view in FROM | Display/filter via EXISTS expressions (no `@ctx@`) |
| `MaxQueryRecords=0`, Load Page Num on | Cap 500, page size 50, Load Page Num off |
| No key / order | `AD_User_ID` key, `ORDER BY au.Name` |
| Shift rows on org `*` (read-only Employee tab) | AbilityERP org assigned (`06`) |
| Related Info off | Rostered Shift / Credentials / Alerts on (`08`) |

**On Approved Leave** (default **N**) hides staff with approved leave ending today or later.
Clear the criteria or set **Y** to include them. **Has Future Shift** is display-only.

Shift-window-specific date overlap (using `@StartDate@`) is still deferred — context tokens
break `InfoWindow.loadInfoDefinition` on this iDempiere build.

## Requirements

- Target DB already has this AbERP Info Window (same UUID).
- PostgreSQL + iDempiere with `adempiere` schema.
- No Java/OSGi code — AD + indexes only.

## Build distribution JAR

```bash
cd idempiere-plugins/com.aberp.rostering.staffinfo
chmod +x build.sh deploy.sh
./build.sh
```

Produces `release/com.aberp.rostering.staffinfo_1.0.0.2026071122.jar`.

## Install

```bash
./deploy.sh
```

Applies: `01` → `02` → `03` → `05` → `06` → `07` → `08` → `04`.

Then **Cache Reset** (or log out/in). Restart only if AD cache stays sticky.

## Rollback

```bash
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/99-rollback.sql
```

## Files

| File | Purpose |
|------|---------|
| `sql/01-indexes.sql` | Contact / date indexes |
| `sql/02-rewrite-infowindow.sql` | FROM / WHERE / paging |
| `sql/03-rewrite-infocolumns.sql` | Criteria cleanup |
| `sql/05-hotfix-browser-smoke.sql` | Browser smoke hotfix |
| `sql/06-fix-shift-org.sql` | Move shifts/staff off org `*` |
| `sql/07-eligibility-criteria.sql` | Leave filter + future-shift flag |
| `sql/08-enable-related-info.sql` | Re-enable Related Info panels |
| `sql/04-verify.sql` | AD dump + EXPLAIN |
| `sql/99-rollback.sql` | Restore prior join-based definition |
