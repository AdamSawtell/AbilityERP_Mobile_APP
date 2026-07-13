# SAW003 — Deploy to another build (agent)

**Ticket / slug:** `SAW003_staff_rostering_info`  
**Kind:** idempiere · **JAR:** Yes · **Status:** done

## Required host access

- SSH · `psql` · WebUI Admin · ability to restart iDempiere / install OSGi JAR  
- Java 11 + `$IDEMPIERE_HOME` (default `/opt/idempiere-server`) to **build** JAR

## Agent one-liner

```bash
cd idempiere-plugins/com.aberp.rostering.staffinfo
chmod +x build.sh deploy.sh
./deploy.sh
# build JAR → SQL 01→20→04 → restart → wait WebUI 200 → then Cache Reset / logout-in
```

## Package / bundle

| | |
|--|--|
| Path | `idempiere-plugins/com.aberp.rostering.staffinfo/` |
| Symbolic name | `com.aberp.rostering.staffinfo` |
| Version | `1.1.0.2026071223` (rebuild on host via `build.sh`) |
| Info Window UU | `2b4ab146-0809-47c6-96f3-8b841d60a6bf` (**must already exist**) |

## Ordered SQL (`deploy.sh`)

`01-indexes` → `02-rewrite-infowindow` → `03-rewrite-infocolumns` → `05-hotfix-browser-smoke` → `06-fix-shift-org` → `07-eligibility-criteria` → `08-enable-related-info` → `09-find-fill-ux` → `10-java-ux-org` → `11-drop-redundant-criteria` → `12-needs-match-criteria` → `14-fix-show-unmatched-selectclause` → `15-fix-onapprovedleave-criteria` → `16-fix-nonnegative-id-criteria` → `17-fix-hidden-multiselect-criteria` → `18-fix-result-grid-readonly` → `19-rename-staff-name` → `20-hide-clutter-columns` → `21-fix-nonnegative-multiselect` → `22-harden-nonnegative-editors` → `23-force-no-id-criteria` → `04-verify`

Do **not** use stub `sql/install-all.sql` as the install.  
Skip `13-load-test-needs-match.sql` unless load-testing.  
Rollback: `sql/99-rollback.sql` + remove JAR / bundles.info line + restart.

## AbilityERP Admin access

Info Window is pre-existing — Admin must already have (or be granted) access to Staff Rostering Info / Shift (Rostered). No new process. Smoke **as Admin**.

## Portability risks

- Prefer host `build.sh` so JAR version matches MANIFEST (or ship `release/*_1.1.0.2026071223.jar`).
- `sql/06-fix-shift-org.sql` only moves org=`*` data for the **AbilityERP** seed client; on HCO it skips data move and still sets AlwaysUpdateable on the Employee Search column.
- `sql/08-enable-related-info.sql` resolves Related Info / parent columns by **owned UU only** (never activate every `ColumnName=C_BPartner_ID` — that reactivates Multi Select “Support Receiver Needs” → ZK **non-negative only**).
- `sql/21-fix-nonnegative-multiselect.sql` deactivates Multi Select leftovers; keeps Agency Staff as filter-only criteria.

## WebUI smoke

Shift (Rostered) → Employee → staff Search: wildcards, leave/needs, Related Info, contact→BP. See also `EXTERNAL-SUMMARY.md`. Confirm Info Window title **Employee (User) / Agency Staff Rostering Info** with **Staff Name** criteria.

**Show Unmatched Staff:**
1. Unticked → shift Related Needs apply (matched list).
2. Ticked → needs ignored; **Require credentials (AND)** multi-select appears under the tick.
3. Select 2+ credentials → only staff with **all** selected (AND). Empty selection → full unmatched pool.

## Packs

- `Downloads\AbilityERP-ClientUpdate-SAW003_staff_rostering_info-20260712\`  
- `Downloads\AbilityERP-ProdUpdate-SAW003_staff_rostering_info-20260712\`

## External ticket text

`Tickets/SAW003_staff_rostering_info/EXTERNAL-SUMMARY.md`
