# HCO20260714 — Deployment Report (HCO Test dry run)

**Release:** HCO20260714  
**Ticket:** SAW020_hco20260714_release · [#20](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/20)  
**Environment:** HCO Test (Production rehearsal)  
**Host:** `54.253.165.194` (`ip-172-31-3-32` / `i-0efcb96f5b2cf1b6a`)  
**Started / finished:** 2026-07-14  
**Verdict:** **Ready for the next HCO Production deployment** (install path validated; see smoke notes)

Status legend: `PENDING` · `IN PROGRESS` · `PASS` · `FAIL` · `BLOCKED` · `SKIPPED`

---

## 1. Ordered deployment steps

| Step | Action | Status | Evidence |
| ---: | ------ | ------ | -------- |
| 0 | Baseline discovery | PASS | Prerequisites present; AbERP release tickets mostly missing |
| 1 | SAW018 packins | PASS | View + 4× SYSTEM packins Completed (`1001029`–`1001032`) |
| 2 | SAW001 Paid filter | PASS | SQL 00→01→04→05→02→03 |
| 3 | SAW003 Staff Rostering Info | PASS | SQL 01…24→04 + JAR `1.1.0.2026071237` + restart |
| 4 | SAW007 Activity tabs | PASS | Portable SQL (01 + register + fix + 04 types) |
| 5 | SAW009 Support Day fields | PASS | SQL 00→05 |
| 6 | SAW010 Timesheet Approval Info | PASS | SQL 00→03 |
| 7–8 | SAW013 Forms + Create Request filter | PASS | SQL 00→01→02→03→05→04 |
| 9 | SAW015 Copy Dates From | PASS | SQL + JAR `7.1.0.202607131830` + restart |
| 10 | SAW014 Support Location ColumnSQL | PASS | SQL 00→01→04; WebUI grid Email/Phone populated |
| 11 | SAW017 Bulk Booking Generator | PASS | Generator stack JARs + bulk JAR + SQL 00→04 + restart |
| 12 | Release post-validation | PASS | Markers green; WebUI 200; Admin login OK |

---

## 2. SQL execution list

| Order | Ticket | Script / artefact | Result |
| ---: | ------ | ----------------- | ------ |
| 1a | SAW018 | `00-clear-stuck-package-imp.sql` | PASS (5 stuck cleared) |
| 1b | SAW018 | `01-APPLY-view.sql` / `hco_cred_missing_staff_v` | PASS |
| 1c | SAW018 | `03-mark-employee-infopanel-versions-ok.sql` | PASS |
| 1d | SAW018 | PackIn `*_SYSTEM_hco_credentials.zip` | PASS `1001029` |
| 1e | SAW018 | PackIn `*_SYSTEM_hco_employee.zip` | PASS `1001030` |
| 1f | SAW018 | PackIn `*_SYSTEM_hco_supportlocation.zip` | PASS `1001031` |
| 1g | SAW018 | PackIn `*_SYSTEM_hco_client.zip` (retry after clean stop) | PASS `1001032` |
| 2 | SAW001 | plugin `sql/00,01,04,05,02,03` | PASS |
| 3 | SAW003 | plugin `sql/01…24,04` | PASS |
| 4 | SAW007 | `01-add-link-columns` + register + fix user/contact + `04-ensure-activity-types` | PASS |
| 5 | SAW009 | plugin `sql/00…05` | PASS |
| 6 | SAW010 | plugin `sql/00…03` | PASS |
| 7–8 | SAW013 | plugin `sql/00,01,02,03,05,04` | PASS |
| 9 | SAW015 | plugin `sql/00,01,02,04` | PASS |
| 10 | SAW014 | ticket `sql/00,01,04` | PASS |
| 11 | SAW017 | plugin `sql/00…04` | PASS |

---

## 3. Build / compile steps

| Ticket | Build | Result |
|--------|-------|--------|
| SAW003 | Known-good JAR copied from prior Test host `13.210.248.141` (`1.1.0.2026071237`, 57977 bytes) | PASS |
| SAW015 | Known-good JAR from prior Test (`7.1.0.202607131830`) | PASS |
| SAW017 | ClientUpdate / ticket `jar/` stack + bulk JAR | PASS |

Staging tarball on host: `/tmp/HCO20260714/` (packs + plugins + jars).

---

## 4. Service restarts

| When | Action | Result |
|------|--------|--------|
| After each SAW018 PackInFolder | PackIn app stops Equinox — `idempiere` start + WebUI 200 | PASS |
| After SAW003 JAR | stop → kill leftover equinox if needed → start | PASS |
| After SAW015 JAR | stop → start | PASS |
| After SAW017 JARs | stop → start | PASS |

**Production tip:** Before `RUN_ApplyPackInFromFolder.sh`, fully stop iDempiere and kill leftover `org.eclipse.equinox.launcher`. Leaving the live server / partial Java causes `ClassCastException` in `Incremental2PackActivator` and skips the zip (seen on `hco_client`).

---

## 5. Issues encountered and resolutions

| # | Ticket | Issue | Resolution |
|---|--------|-------|------------|
| 1 | SAW018 | Initial batch PackInFolder failed (`GenericPO` → `X_AD_Package_Imp` ClassCast) | Apply **one zip at a time**; ensure main server fully stopped |
| 2 | SAW018 | `hco_client` failed while server still warm / leftover Java | `systemctl/init.d stop` + `pkill equinox` → PackIn → start; success as `20260714212209_SYSTEM_hco_client.zip` (`1001032`) |
| 3 | SAW018 | Stuck `ad_package_imp` Installing rows on baseline | `00-clear-stuck-package-imp.sql` |
| 4 | Host | Ticket host `54.253.165.194` ≠ prior playbook `13.210.248.141` | Dry-run intentionally on fresh host; prior Test already had most tickets |

**No HCO `*_UU` values changed** for pre-existing objects (Support Location window UU remained `6ef3c558-3ec8-4f0c-be40-89f35d8acebf`).

---

## 6. Validation results

### DB / install markers (all PASS)

| Check | Result |
|-------|--------|
| Paid Info criteria rows | 2 |
| Break Start InfoColumn UU | present |
| `AbERP_RequestSubmitted` column | present |
| Copy Dates From process UU | present |
| Bulk Generate Bookings process UU | present |
| Support Location Email ColumnSQL subquery | fixed |
| SAW017 DocAction → `BookingGen_DocList` | confirmed |
| SAW009 Support Start/End Day fields | present |
| Bundles.info staffinfo / skipdates / generator / bulk | registered |

### WebUI

| Check | Result | Notes |
|-------|--------|-------|
| `http://54.253.165.194/webui/` | PASS | HTTP 200; title `AvERP HCO Test001 20260712` |
| Admin login | PASS | SuperUser → Admin → Home |
| SAW014 Support Location grid Email/Phone | PASS | Grid shows Email / Phone / 2nd Phone with values (e.g. Murray) |
| Additional window-by-window UI clicks | PARTIAL | After Support Location open, ZK global-search dblclick did not reliably open other windows in the same session; reopen via Menu after Cache Reset / new login at Production cutover |
| Per-ticket verify SQL | PASS | Embedded in each install step |

---

## 7. Rollback notes

| Ticket | Rollback |
|--------|----------|
| SAW018 | Prefer DB backup restore; Package Maintenance uninstall is high risk on Support Location; view drop: `DROP VIEW IF EXISTS adempiere.hco_cred_missing_staff_v` |
| SAW001 | `sql/99-rollback.sql` |
| SAW003 | `sql/99-rollback.sql` + remove JAR / bundles.info + restart |
| SAW007 | Reverse portable tab registration carefully |
| SAW009 | `sql/99-rollback.sql` |
| SAW010 | `sql/99-rollback.sql` |
| SAW013 | `sql/99-rollback.sql` |
| SAW015 | `sql/99-rollback.sql` + remove JAR |
| SAW014 | `sql/99-rollback.sql` |
| SAW017 | Deactivate process/menu + stop bulk bundle |

Always Cache Reset after rollback.

---

## 8. Final deployment checklist

- [x] All ordered installs complete  
- [x] WebUI up  
- [x] Verify SQL / markers green  
- [x] Representative WebUI smoke (SAW014) + Admin login  
- [x] No HCO `*_UU` changed  
- [x] LEARNINGS / host docs updated  
- [x] **Ready for next HCO Production deployment**  

---

## 9. Post-deployment verification checklist (reuse on Production)

- [ ] WebUI HTTP 200 after final restart  
- [ ] Logs: no fatal ClassNotFound for release bundles  
- [ ] Cache Reset (System Admin) or fresh login  
- [ ] Smoke matrix:  
  - SAW018 objects / credentials missing-staff surfaces  
  - SAW001 Paid filter on Notification SR Invoice Send Info  
  - SAW003 Shift → Employee Search / Show Unmatched  
  - SAW007 Activity types on BG / SB / SA  
  - SAW009 Support Start/End Day lists on Service Booking Line  
  - SAW010 Break Start/End; clutter cols hidden  
  - SAW013 Request Submitted + Create template type filter  
  - SAW015 Copy Dates From  
  - SAW014 Support Location grid Email/Phone  
  - SAW017 Bulk Generate Bookings Yes/No + Drafted DocAction  

---

## 10. Production ordered runbook (summary)

1. Backup DB.  
2. Stage packs under `/tmp/HCO20260714/`.  
3. SAW018: clear stuck → view SQL → mark employee.infopanel versions → **stop server fully** → PackIn each `yyyymmddHHMM_SYSTEM_hco_*.zip` one at a time → start → verify Support Location UU unchanged.  
4. SAW001 SQL (no restart).  
5. SAW003 SQL + JAR `1237` + restart.  
6. SAW007 SQL.  
7. SAW009 SQL.  
8. SAW010 SQL.  
9. SAW013 SQL.  
10. SAW015 SQL + JAR + restart.  
11. SAW014 SQL.  
12. SAW017 generator stack JARs + bulk JAR + SQL + restart.  
13. Cache Reset · Admin smoke matrix · declare Production complete.

Per-ticket detail: each `Tickets/SAW###_…/DEPLOY.md` + Downloads `AbilityERP-ProdUpdate-SAW###_*`.

---

## Session detail

### Step 0 — Baseline

- Clean dry-run host vs previously installed `13.210.248.141`  
- Missing: Paid criteria, Break Start IC, Request Submitted, Copy Dates, Bulk process, cred view, release bundles  
- Present: prerequisite windows / CreateRequestFromTemplate / physical support-day columns  

### SAW018 note

Support Location UU before/after: `6ef3c558-3ec8-4f0c-be40-89f35d8acebf` unchanged.
