# HCO Deployment — learnings log

Append new entries at the **top** after each HCO install or failed attempt. Keep each entry short; put ticket-local IDs in that ticket’s **HCO Future Deployments variables** section.

## 2026-07-13 — SAW016 Leave Planning Search fix (AccessSqlParser)

**Fix:** Nested Service Location `SELECT` in InfoColumn `selectclause` broke `AccessSqlParser.getSelectStatements` (IllegalArgument popup on Search). Replaced with scalar fn `aberp_lp_primary_support_location(u.AD_User_ID)` (`sql/22-primary-location-function.sql`) + JAR `1.0.0.2026071332`.

**Browser smoke (Admin):** Jul 2026 → **46** rows, no IllegalArgument; Support Locations in grid (Murray / Spinebill / Centennial / Gawler…); Declined banner filter → 1 row; status cell colours (rose/green); SQL EXISTS filter for `1/6 Murray` → **9** rows.

**Learnings:**
1. Avoid nested `SELECT` / commas in InfoWindow `selectclause` — wrap in a PG function.
2. After AD InfoColumn change: hard restart (or Cache Reset); open window alone is not enough if MInfoColumn is cached.
3. `systemctl restart` alone can leave HTTP 000 — use `restart-webui.sh` / force-kill equinox + init.d.

**No `*_UU` changes.**

## 2026-07-14 — SAW017 Yes/No paras → display type 20

**Fix:** Include Irregular / Include STR / Force Invoice Rule used `ad_reference_id=319` (_YesNo list id). That rendered raw **Y/N textboxes**. Peers use **Yes-No (20)**. Applied `sql/03-fix-yesno-display.sql` on HCO Test. Cache Reset before re-open Bulk dialog.

**No `*_UU` changes.**

## 2026-07-13 — SAW017 full E2E browser smoke PASS

**Smoke:** Single + Bulk on HCO Test after leave.planning restart restored WebUI.

**Evidence:** [`Tickets/SAW017_booking_generator_bulk/hco/E2E-SMOKE-20260713.md`](../SAW017_booking_generator_bulk/hco/E2E-SMOKE-20260713.md)

**Results:**
- Single: SB `53324` (BG `2001124`) InvoiceRule `I` DR Sep period
- Bulk STR: `ok=3` → SBs `53325`, `53326` InvoiceRule `I`
- Temporary smoke AD date/activity defaults **reverted** after run

**Learnings:**
1. If WebUI 503 / proxy to :8080 refused, another ticket’s `rebuild-hco.sh` may have stopped Equinox — wait for its start loop or `sudo /etc/init.d/idempiere start` then poll `:8080/webui/` for 200.
2. Reliable bulk param binding in automation: set AD defaults for the smoke period → Cache Reset → open process from menu → OK → **revert defaults**.
3. Prefer a clean **future** month for E2E so new document numbers are unambiguous.
4. DocAction / `BookingGen_DocList` + `02-fix-docaction-list.sql` remain mandatory for future installs.

**No `*_UU` changes.**

## 2026-07-13 — SAW017 Bulk Generate Bookings smoke

**Install/smoke:** Generator stack + `com.aberp.bookinggenerator.bulk` already on HCO Test. WebUI smoke + AD fix.

**Learnings:**
1. Bulk **DocAction** must use list **`BookingGen_DocList`** (UU `285220bc-…`, same as Generate Bookings). Core `_Document Action` (135) has no `DR` → mandatory DocAction never binds / defaults fail.
2. Ship `sql/02-fix-docaction-list.sql` after install; Cache Reset before re-test.
3. `ad_pinstance` queries by process value still time out on HCO — filter by `ad_process_id` + `created` window.
4. Bulk can report `ok=N` when Generate Bookings returns success even if no new `C_Order` row (patterns already satisfied); still updates BG Start/End dates.

**Smoke:** Single SB `53320` (BG `2001124`); Bulk STR `ok=3`, SB `53323` InvoiceRule `I`. No `*_UU` changes.

## 2026-07-13 — SAW018 HCO Release Packins

**Install:** 2Packs `hco_credentials` / `hco_employee` / `hco_client` / `hco_supportlocation` + SQL view `hco_cred_missing_staff_v` on HCO Test. All four named zips **Completed successfully**. Support Location UU unchanged.

**Learnings:**
1. Folder PackIn filenames must be `yyyymmddHHMM_SYSTEM_*.zip` — System client **Value** is `SYSTEM` (case-sensitive).
2. Create the DB view **before** the credentials packin.
3. Clear stuck `ad_package_imp` (`Installing` / `processed=N`) before PackIn.
4. Legacy OSGi bundle `com.aberp.employee.infopanel` (Incremental2PackActivator) blocked PackInFolder with *Failed to save InfoWindow Employee (User) / Agency Staff Rostering Info* (7.1.3+). Mark those versions completed and uninstall the bundle; prefer SAW003 `com.aberp.rostering.staffinfo`.
5. PackInFolderApplication exits after apply — confirm `systemctl is-active idempiere`.

**Smoke:** package_imp `1001055`–`1001058` success; view + AD_Table UU `598a7584-…`; element `hco_primarydept`; window UU `6ef3c558-…` unchanged.

## 2026-07-13 — SAW017 Booking Generator bulk (Phase 0 discovery)

**Scope:** Discovery only on HCO Test (same host as SAW010). No AD/JAR install. No `*_UU` changes.

**Findings:**
1. **Generate Bookings** AD present (UU `6482f6b8-…`, class `com.aberp.servicebooking.generator.process.GenerateBookings`) but **JAR absent** from plugins/customization-jar (also absent on AbilityERP seed). Same for `GenerateTimesheets` / `GenerateShifts` bytecode.
2. Ops **STANDARDS** user query on BG = Description STANDARD* (~270 active). Blocks = Activity (Day Program=DO, etc.) + Description tokens; monthly DO/SIL queries are on **Service Booking** (`C_Order`), not BG.
3. BG already has `InvoiceRule`, `AbERP_IsProgramOfSupports`, `IsTemplate`, `C_Activity_ID`, `AbERP_Ready_Claim_Rule`, Skip Dates — enough for v1 filters without a new column.
4. `ad_pinstance` lookups by process easily **time out** on HCO (huge table) — avoid naive joins; aligns with SAW012.
5. HCO Test `bundles.info` only lists recent AbERP plugins; many files under `customization-jar/` are not registered/active.

**Next:** Obtain generator JAR from Flamingo/Logilite → install on HCO Test → single-record smoke → then build bulk wrapper.

**Ticket:** [`Tickets/SAW017_booking_generator_bulk/hco/DISCOVERY.md`](../SAW017_booking_generator_bulk/hco/DISCOVERY.md)

## 2026-07-13 — SAW016 Leave Planning window

**Install:** AD + PG functions/trigger (no JAR) on HCO Test. Window UU `16a01602-…`, tables `AbERP_Leave_Planning` + `_Line`.

**Learnings:**
1. Nested `FROM` inside ColumnSQL → `AccessSqlParser: More than one FROM clause` / `Table not open`. Use DB functions for summaries.
2. Child tab on unrelated leave table with only WhereClause and no link column did not appear in WebUI. Bridge line table + `AD_Column_ID` parent link + TabLevel 1 works.
3. Unavailability menus sit at tree parent `-1`; burying Leave Planning under Rostering made search miss it — use root parent like peers.
4. Bump `AD_*` sequences (`GREATEST(currentnext, MAX(id)+1)`) before inserts — `nextid` was colliding on HCO.

**Smoke:** Jan 2027 + All Locations → Summary Approved:21 / Declined:2; Leave Records 23 rows; Zoom leave available. Cache Reset required after AD.

## 2026-07-13 — SAW013 Create Request popup: filter template by window Request Type

**Process:** `CreateRequestFromTemplate` (Logilite) para `RequestTemplate_ID`.

**Issue:** Val rule `R_Request Template` listed all `IsTemplate=Y` rows → staff could pick a template whose type ≠ form `R_RequestType_ID`.

**Fix:** New AbERP val rule UU `a0130004-5a01-4e13-a013-000000000004` (do **not** change shared rule — also used by `X_RequestDocActionMapping` / `X_RequestStatusRoleMapping`). Point process para + default SQL at `@R_RequestType_ID@`. SQL: `05-match-request-template-type.sql`.

**Smoke:** Doc `1003729` Additional Shift → popup defaults/lists only Additional Shift; Doc `1003444` HCO Unserviced → only HCO Unserviced. Cache Reset required.

---

## 2026-07-13 — SAW013 HCO Forms: virtual ColumnSQL times out on large grids

**Window:** HCO Forms and Approvals (`AbERP_ShiftChange`, ~3.8k rows).

**Tried:** Virtual ColumnSQL on `R_Status_ID` / `AbERP_RequestSubmitted` mirroring linked `R_Request`.

**Result:** `GridTable.waitLoadingForRow` **Timeout loading row 1** (30s). Correlated subqueries on every grid row; also `ORDER BY`/`FETCH FIRST` in ColumnSQL broke AccessSqlParser earlier.

**Fix adopted:** Physical read-only Status + `AbERP_RequestSubmitted`, synced by `AFTER` trigger on `R_Request`; DisplayLogic hides Create; BEFORE INSERT blocks duplicate active requests. One-time backfill. No JAR. No HCO `*_UU` overwrites.

**Smoke:** Grid loads; Status matches Requests child (e.g. Doc 1000003 / Not Approved); dup INSERT blocked.

---

## 2026-07-12 — SAW003 Shift Search: real cause of "non-negative only"

**Browser:** Shift `#1102425` Staff Search showed popup **non-negative only**.

**Log (not Intbox alone):**
`StaffRosteringInfoWindow.readLine` → `PSQLException: column ca.c_bpartner_staff_id does not exist`

HCO `AbERP_CredentialAssignment` has **`aberp_user_contact_id` only** (no `c_bpartner_staff_id`). Needs-match SQL from Shift CRD requirements blew up; Info surfaced ZK **non-negative only**.

**Fix:** Java uses BP-staff column only if present; else User Contact only. Redeployed JAR + hard restart. New log has **0** `c_bpartner_staff_id` errors.

---

**Result:** Menu Info ReQuery All/Any = **210 rows, no popup** after JAR with `onUserQuery`/`validateParameters` sanitize + SQL `23`.

### Seed SLUG progress (commits that fixed this before)
`07c0e5c` → `c44fe33` → `165d19e` → **`6596eba`** (16/17 SQL + `clearInvalidIdCriteria`). Popup is ZK Intbox `-1` on **ReQuery path**, not “no staff match”.

### Why prior HCO fix felt incomplete
`InfoPanel.onUserQuery()` runs **before** `executeQuery()`. Client/server can reject `-1` Intboxes before our old clear ran. Now sanitize in `onUserQuery` + `validateParameters` + echo after render.

### Retest
Logout/in → Shift (Rostered) → Employee → Search → ReQuery with All/Any.

---

**Result:** Pass after SQL `22` + JAR rebuild with Intbox constraint strip. Hard restart required (soft restart left old Java process).

### Clarification
**Empty staff list ≠ non-negative popup.** No matches → `0 Rows found`. Popup = ZK Intbox `-1` validation (often before `executeQuery`).

### Extra fix
| Change | Detail |
|--------|--------|
| `22-harden-nonnegative-editors.sql` | Gender/Position → String names; deactivate leftover Search cols |
| Java `neutralizeIdEditorConstraints()` | Strip `no negative` on Intboxes at criteria render (before ReQuery validate) |
| Hard restart | `systemctl stop` + kill leftover `idempiere` java, then start |

### Smoke
Menu Info → ReQuery All/Any → **210 rows**, no popup.

---

**Result:** Hotfix applied on HCO (SQL only; no JAR change). Logout/in required.

### Cause
Portable `08-enable-related-info.sql` activated every `ColumnName=C_BPartner_ID`, including Multi Select **Support Receiver Needs** (`40d550c2-…`). Empty ChosenMultipleSelection holds `-1` → ZK **"non-negative only"** on ReQuery (esp. All/Any).

### Fix (repo + HCO)
| Change | Detail |
|--------|--------|
| Rewrite `08` | Activate parent BP/User by **owned UU only**; deactivate Multi Select / needs columns |
| Add `21-fix-nonnegative-multiselect.sql` | Kill ref `200138` leftovers; restore Agency Staff filter-only criteria |
| Do **not** clear all `isdisplayed=N` query criteria | That wrongly removed Agency Staff |

### Smoke
Logout → Staff Rostering Info → ReQuery with All/Any — popup must be gone.

---

---

## 2026-07-12 — SAW003 Staff Rostering Info (Shift → Employee)

**Result:** Pass (SQL + JAR restart + WebUI Info Window smoke). No HCO `*_UU` overwritten.

### What worked

- Info Window UU already on HCO as local `1000034`; Employee tab `AbERP_User_Contact_ID` already uses ref → that IW.
- Applied full SQL order (`01`→`20`→`04`) + JAR `1.1.0.2026071219` + restart (WebUI 200).
- WebUI: Info Window shows **Staff Name**, Employee=Yes, Agency Staff criteria, Java banner (“Shift filter active…”), Related Info tabs.

### Learnings → process fixes

| Learning | Action taken |
|----------|----------------|
| `06` raised EXCEPTION when AbilityERP client missing → blocked HCO deploy | Soft-skip NOTICE; still set AlwaysUpdateable on `AbERP_User_Contact_ID` |
| `08` hardcoded seed InfoColumn IDs `1000143`/`1000236` (wrong on HCO: `1000181`/`1000246`) | Rewrite `08` by InfoColumn UU / ColumnName + Related UU/name |
| HCO has ~39k org=`*` shifts | Do not bulk re-org; smoke non-`*` shifts; document in NOTES |
| Large JAR upload via base64 over SSH can hang | Prefer single-file `scp` for JARs; SQL via stdin |

### Ticket artefacts

- `Tickets/SAW003_staff_rostering_info/NOTES.md` → HCO Future Deployments variables  
- Process: `sql/06-fix-shift-org.sql`, `sql/08-enable-related-info.sql`

---

## 2026-07-13 — SAW003 unmatched credential AND (JAR 1227)

**Result:** Pass E2E on HCO Test after JAR `1.1.0.2026071227` + leave.planning `zcommon` fix.

### What worked

- Tick **Show Unmatched Staff** → **Require credentials (AND)** Listbox below criteria (253 creds, 720×160).
- Empty selection ReQuery → 210 rows; Aged Care + Nursing AND → 0 rows; clear → 210; untick hides list.
- Credential Listbox must stay **enabled** (ZK drops SelectEvent when disabled).

### Learnings

| Learning | Action |
|----------|--------|
| HCO was on old JAR (1220) while staging had credential UI | Always check `bundles.info` version on target before “missing UI” bugs |
| List clipped inside `z-grid-body` | Place credential box **below** parameterGrid (1227) |
| Opening Staff Info hit Media CNFE from leave.planning | SAW016 MANIFEST needs `zcommon`; hard restart; WebUI on `:8083`/`:80` not `:8080` |
| `init.d` stop can leave Java running (“already running”) | Kill equinox launcher PID before start if WebUI 503 |

---

## 2026-07-12 — SAW012 Session/Process Audit performance

**Result:** Pass on AD/UX/HouseKeeping. Indexes + batched purge long-running (expected). WebUI confirmed High Volume Find on Process Audit.

### What worked

- Core window/tab/field UUs matched; High Volume + MaxQueryRecords=200 + selection columns.
- HouseKeeping `whereclause` is **varchar(255)** — FK-safe logic in `aberp_pinstance_ok_to_purge()` / `aberp_session_ok_to_purge()`.
- Schedulers need `ad_schedule_id` (resolve **1 Day** UU `5a06dc76-704e-40f5-bfcf-724829332c50`).

### Learnings → process fixes

| Learning | Action |
|----------|--------|
| `AD_PInstance` → `C_Order`/`C_OrderLine` ON DELETE CASCADE — naive purge destroys orders | Pack helpers + HOW-TO warning |
| Long discovery scans on `ad_pinstance` block CREATE INDEX CONCURRENTLY and WebUI | Kill stuck diagnostics before index/purge |
| Duplicate `CREATE INDEX CONCURRENTLY` on same name stalls progress | Single `run-indexes.sh` only |
| Menu search “Cache Reset” may show “No Records found” while list still lists it | Click list cell / System Admin path |

### Ticket artefacts

- `Tickets/SAW012_session_process_audit_perf/`
- Downloads packs `*SAW012_session_process_audit_perf-20260712*`

---

## 2026-07-12 — SAW007 Activity types (Email / Meeting / Phone / Note / Task)

**Result:** Pass (SQL verify + WebUI Activity Type dropdown on Booking Generator).

### What worked

- Enabled list values `EM`, `ME`, `PC`, `CN`, `TA` on windows by **name** (HCO IDs `1000163` / `1000075` / `1000073`).
- Delta `sql/04-ensure-activity-types.sql` appended 6 missing grants (PC/CN/TA on SB + SA); EM/ME already present.
- WebUI dropdown showed Email, Meeting, Phone call, Case Note, Task (plus other types already granted to BG).

### Learnings → process fixes

| Learning | Action taken |
|----------|----------------|
| Register step 4 skipped SB/SA when BG ID already in description | Per-window append if missing; dedicated `04-ensure-activity-types.sql` in deploy + packs |
| Business “Note” = list **Case Note** (`CN`) | Documented in EXTERNAL-SUMMARY / HOW-TO / NOTES |

### Packs / next HCO prod

- Staging: `Downloads\AbilityERP-ClientUpdate-SAW007_activity_tab_integration-20260712\`
- Prod: `Downloads\AbilityERP-ProdUpdate-SAW007_activity_tab_integration-20260712\` — use **`02-DELTA-activity-types-only.sql`** when tabs already installed

---

## 2026-07-12 — SAW007 Activity tab integration

**Result:** Pass (SQL + WebUI smoke Booking Generator → Activity). No HCO `*_UU` overwritten.

### What worked

- Portable path: `sql/01-add-link-columns.sql` → `register-contactactivity-tabs.sql` → `fix-activity-user-contact.sql`.
- Windows resolved by name (HCO IDs differ from seed). Tabs: BG `1000358`, SB `1000359`, SA `1000360` (19 fields each).
- WebUI (Admin, after logout/in): Activity New shows **Business Partner** inherited (`Winston Churchill`), **User** empty (not hardcoded SuperUser), **User/Contact** hidden.
- Marker JAR not required for AD tabs on HCO.

### Learnings → process fixes

| Learning | Action taken |
|----------|----------------|
| PG rejects `UPDATE … FROM t JOIN … ON … = target.col` when JOIN references update target | Rewrote `fix-activity-user-contact.sql` UPDATEs with `EXISTS` / no target-alias JOIN |
| `nextid(AD_Field)` lagged after register’s `MAX+1` field clones → duplicate key on User field insert | User-field insert uses `MAX+1` + sequence bump; register now bumps `AD_Field` sequence after clone |
| Existing element `AbERP_BookingGenerator_ID` already on HCO with different UU | Insert element/column only when missing — never overwrite UU |
| Field display changes need logout/in (Cache Reset alone may not refresh tab form) | Documented in HCO NOTES / smoke |

### Ticket artefacts

- `Tickets/SAW007_activity_tab_integration/NOTES.md` → HCO Future Deployments variables  
- Process SQL: `idempiere-plugins/com.aberp.contactactivity.tabs/` (`01`, `register-…`, `fix-activity-user-contact.sql`)

---

## 2026-07-12 — SAW010 Timesheet Approval Info columns

**Result:** Pass (SQL + WebUI column smoke). Existing InfoColumn UUs unchanged (matched pack).

### What worked

- Info Window UU `40d6a2d7-…` and all hide-target InfoColumn UUs matched Core on HCO.
- Break Start/End inserted with owned UUs; order after Shift Type confirmed in WebUI.
- Filters still show Business Partner / Activity / Employee; grid does not.

### Learnings → process fixes

| Learning | Action taken |
|----------|----------------|
| Prefer `ssh` stdin upload over multi-file `scp` on this Windows host (scp/ssh sessions were hanging) | Document in HCO README access notes |
| Stale local `ssh.exe` processes can block new HCO connections | Kill hung ssh/scp before retry |
| Do **not** run `04-seed-test-rows.sql` on HCO (hardcoded client/org) | Already noted in DEPLOY.md — reinforced |
| Grant Info Window access to **Admin** + AbilityERP Admin even when IW already existed | Applied on HCO install |

### Ticket artefacts

- `Tickets/SAW010_timesheet_approval_info_columns/NOTES.md` → HCO Future Deployments variables  
- `Tickets/SAW010_…/hco/run-install.sh`

---

## 2026-07-12 — SAW009 Support day pattern number (Service Booking Line)

**Result:** Pass (SQL + WebUI smoke). No existing HCO column UUIDs changed.

### What worked

- Tab / reference / element UUs matched Core.
- Columns already existed on HCO as **String** storing weekday names; switched to List **14 Day Roster Period** without changing column UUs.
- Backfill from `AbERP_ServicePattern` (48019 lines) → values `1`..`15`; WebUI shows e.g. `13 - Saturday`.
- Sync trigger installed.

### Learnings → process fixes

| Learning | Action taken |
|----------|----------------|
| `01` previously set `ad_column_uu = our UU` when matching by ColumnName — would overwrite HCO UUs | Keep existing UU; only update reference/list/properties |
| HCO already had weekday-text data in the same physical columns | Backfill from pattern only (no weekday→day-01 guessing) |
| HCO “14 Day Roster Period” list labels start Monday (`01 - Monday`), not Sunday | Do not rewrite list; display whatever the client list defines |
| Physical columns already `varchar(100)` | `ADD COLUMN IF NOT EXISTS` skips; do not force shrink to 5 |
| New fields may not keep pack-owned field UUs on insert | Resolve fields by tab + column; never overwrite existing field UU |
| Menu tree “Service Booking” opens reliably via `a.menu-href` click | Prefer menu-href over treecell-only click for WebUI smoke |

### Ticket artefacts

- `Tickets/SAW009_support_day_pattern_number/NOTES.md` → HCO Future Deployments variables  
- `Tickets/SAW009_…/hco/run-install.sh`

---

## 2026-07-12 — SAW001 Paid filter (Notification SR Invoice Send Info)

**Result:** Pass (SQL + WebUI smoke). No HCO UUIDs changed. Process hardened and pushed (`9f720f5`).

### What worked

- Core Info Window UU `8fb1cd46-ed81-4cb9-8b83-7662caed9e62` already present on HCO (local `AD_InfoWindow_ID` = `1000029`, not seed `1000032`).
- UU-owned Paid columns insert cleanly; criteria Yes/No/blank works.
- WebUI: Paid=Yes vs Paid=No returns different row counts; **Paid** grid column visible.

### Learnings → process fixes

| Learning | Action taken |
|----------|----------------|
| Menu SQL used hardcoded tree node `1000229` — missing on HCO → menu landed at parent `0` | `04-add-info-menu.sql`: resolve parent by summary menu name **Ability ERP** |
| UPDATE-by-name path set `ad_menu_uu = our UU` — would **overwrite** a client menu UU | Never overwrite existing `ad_menu_uu`; only set UU on INSERT of our owned object |
| HCO SuperUser role dialog exposes **Admin**, not AbilityERP Admin; Admin had **no** Info Window access | `05-grant-admin-infowindow-access.sql`: grant by role **name** to `Admin` + `AbilityERP Admin` |
| AbilityERP Admin can exist in AD but still not appear on SuperUser’s role list for that client | Smoke as **Admin** on HCO; still grant AbilityERP Admin for builds that use it |
| Windows PEM `d:\HCObusiness.pem` too open for OpenSSH | Copy to `%USERPROFILE%\.ssh\HCObusiness.pem` with user-only ACL before SSH |
| ZK dateboxes: JS `.value =` alone often does not bind — mandatory Date Invoiced stays red / empty query | Prefer calendar UI or Enter/blur + ReQuery; narrow date range for smoke |
| Functional-check SQL dumping all invoices floods logs on HCO (~20k paid rows) | Prefer `COUNT(*)` / `LIMIT` on client smoke SQL |

### HCO local IDs (hints only — do not use in portable SQL)

| Object | HCO ID | UU |
|--------|--------|-----|
| Info Window | 1000029 | `8fb1cd46-ed81-4cb9-8b83-7662caed9e62` |
| Menu | 1000227 | `c1d2e3f4-a5b6-7788-9900-aabbccdde001` |
| Ability ERP folder | 1000000 | (name lookup) |

### Ticket artefacts

- `Tickets/SAW001_paid_filter_invoice_send_info/NOTES.md` → HCO Future Deployments variables  
- One-off apply helper: `Tickets/SAW001_…/hco/05-hco-access-menu.sql` (folded into package `05-grant-admin-infowindow-access.sql`)

---

## 2026-07-13 — SAW014 Support Location contact grid columns

**Result:** Pass

### What worked
- Root cause confirmed: `AbERP_Email` / `AbERP_Phone` / `AbERP_Phone2` used `@SQL=` virtual columns (iDempiere 7 evaluates only selected grid row).
- Fix: correlated subquery `ColumnSQL` against `C_BPartner_Location` (same pattern as existing `AbERP_Location_Address` on this table). Also fixed `AbERP_LocationName` / `AbERP_Location_IsActive`.
- Applied on HCO; Cache Reset; Grid View showed Email/Phone on unselected rows; blank rows matched DB (no contact on BP Location).

### Learnings → process fixes
| Learning | Action taken |
|----------|----------------|
| Prefer subquery ColumnSQL over `@SQL=` for any grid-displayed virtual column | Documented in ticket NOTES; migration is UU-safe UPDATE only |
| Menu search may show “No Records found” while results still list the window | Click `a.menu-href` / Ability ERP tree item (same as prior Cache Reset learning) |

### HCO local IDs (hints only — do not use in portable SQL)

| Object | HCO ID | UU |
|--------|--------|-----|
| Window Support Location | 1000016 | `6ef3c558-3ec8-4f0c-be40-89f35d8acebf` |
| Table AbERP_Support_Location | 1000017 | `4ed40b98-ca31-4404-a20b-ea9000d5c51d` |
| Col AbERP_Email | 1001645 | `bd54d23d-44b6-42d7-b8c8-30b3e7b826e6` |
| Col AbERP_Phone | 1001646 | `5f9a40e5-248b-48bd-848f-532ae4601006` |
| Col AbERP_Phone2 | 1001647 | `f41c821a-90fb-4b8b-95c6-8bf2f181f8e7` |

### Ticket artefacts

- `Tickets/SAW014_support_location_contact_grid/`
- Downloads packs `*SAW014_support_location_contact_grid-20260713*`

---

## 2026-07-13 — SAW015 Skip Dates Copy Dates From

**Result:** Pass

### What worked
- New OSGi bundle `com.aberp.skipdates.copyfrom` + AD process/button on Skip Dates header.
- WebUI smoke: copied 12 dates from Public Holidays 2025+2026 into SAW015 UAT Copy Test; source unchanged; independent IDs; review warning in help + result.
- Window button style `B` (labeled) more visible than toolbar-only `Y` for this custom table.

### Learnings → process fixes
| Learning | Action taken |
|----------|----------------|
| HCO `*_UU` columns are `varchar` — do not compare to PostgreSQL `uuid` type | Preflight/install use `TEXT` UU vars |
| `nextid(..., 'N')` cannot be used as scalar (OUT param); use `nextidfunc` | Install SQL uses `nextidfunc` |
| `systemctl restart idempiere` can report success while Java is down (“already running”) | `deploy.sh` now **stop then start** |
| SAW012 purge DELETE sessions can saturate `max_connections` and block smoke | Terminate waiting DELETE backends if needed; document in ticket NOTES |

### HCO local IDs (hints only — do not use in portable SQL)

| Object | HCO ID | UU |
|--------|--------|-----|
| Window Skip Dates | 1000162 | `b3037901-e883-42f2-8e6d-c8e759ca91cd` |
| Process Copy Dates From | 1000071 | `15a01501-c0d4-4f01-8e15-000000000001` |
| Column AbERP_CopyDatesFrom | 1007363 | `15a01503-c0d4-4f01-8e15-000000000003` |
| Field Copy Dates From | 1009357 | `15a01504-c0d4-4f01-8e15-000000000004` |

### Ticket artefacts

- `Tickets/SAW015_skip_dates_copy_from/`
- `idempiere-plugins/com.aberp.skipdates.copyfrom/`
- Downloads packs `*SAW015_skip_dates_copy_from-20260713*`

---

<!-- Template for next entry:

## YYYY-MM-DD — SAW### short title

**Result:** Pass | Fail | Partial

### What worked
- …

### Learnings → process fixes
| Learning | Action taken |
|----------|----------------|
| … | … |

### HCO local IDs (hints only)
| Object | HCO ID | UU |
|--------|--------|-----|

### Ticket artefacts
- …

-->
