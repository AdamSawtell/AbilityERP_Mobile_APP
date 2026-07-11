# AbERP Rostering Staff Info — performance rewrite

Standalone package that rewrites **Employee (User) / Agency Staff Rostering Info**
(`AD_InfoWindow_UU = 2b4ab146-0809-47c6-96f3-8b841d60a6bf`) used on
**Shift (Rostered) → Employee → Employee (User) / Agency Staff**.

## What it changes

| Before | After |
|--------|--------|
| 9-table join fan-out + `DISTINCT` | `AD_User` + `C_BPartner` (+ optional `C_Job`) |
| Leave / credentials / needs / BI view in FROM | `EXISTS` / `NOT EXISTS` in WhereClause |
| `MaxQueryRecords=0`, Load Page Num on | Cap 500, page size 50, Load Page Num off |
| No key / order | `AD_User_ID` key, `ORDER BY au.Name` |

When Start/End dates are present (from shift context), approved leave and overlapping
rostered shifts are excluded unless the officer enables **Show staff on leave** or
**Show overlapping shifts**.

Credentials / needs multi-select join filters are deactivated. Use **Related Info**
(Credentials Assigned, Rostered Shift) for drill-down.

## Requirements

- Target DB already has this AbERP Info Window (same UUID).
- PostgreSQL + iDempiere with `adempiere` schema.
- No Java/OSGi code — AD + indexes only.

## Build distribution JAR

On any machine with `jar` (JDK):

```bash
cd idempiere-plugins/com.aberp.rostering.staffinfo
chmod +x build.sh deploy.sh
./build.sh
```

Produces:

- `build/dist/com.aberp.rostering.staffinfo_1.0.0.2026071101.jar`
- `dist/com.aberp.rostering.staffinfo_1.0.0.2026071101.jar` (committed release copy)

Copy that JAR to other instances (e.g. `customization-jar/` or extract and run SQL).

## Install on an instance

### Option A — deploy script (on iDempiere server)

```bash
# from repo checkout or extracted package
./deploy.sh
```

### Option B — apply SQL from the JAR

```bash
mkdir -p /tmp/staffinfo && cd /tmp/staffinfo
jar xf /path/to/com.aberp.rostering.staffinfo_1.0.0.2026071101.jar
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/01-indexes.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/02-rewrite-infowindow.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/03-rewrite-infocolumns.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/04-verify.sql
```

**No iDempiere restart required.** Log out and log back in (or Role Access Update / cache reset) so the Info Window AD cache refreshes.

## Rollback

```bash
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/99-rollback.sql
```

Then log out/in again.

## Manual test

1. Open **Shift (Rostered)** → **Employee** tab → Search on **Employee (User) / Agency Staff**.
2. Confirm the list opens quickly with Employee=Y default.
3. Pick a user; confirm the Employee line receives `AbERP_User_Contact_ID`.
4. With shift dates in context, confirm people on approved leave / overlapping shifts are hidden unless Show* is enabled.
5. Open Related Info → Credentials Assigned / Rostered Shift.

## Files

| File | Purpose |
|------|---------|
| `sql/01-indexes.sql` | Contact / date indexes for EXISTS paths |
| `sql/02-rewrite-infowindow.sql` | FROM / WHERE / paging / DISTINCT |
| `sql/03-rewrite-infocolumns.sql` | Criteria cleanup + display flags |
| `sql/04-verify.sql` | AD dump + EXPLAIN |
| `sql/99-rollback.sql` | Restore prior join-based definition |
| `build/dist/*.jar` | Portable install artifact |
