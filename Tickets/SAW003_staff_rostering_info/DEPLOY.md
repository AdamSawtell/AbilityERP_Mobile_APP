# SAW003 — Deploy to another build

**Ticket:** SAW003_staff_rostering_info · **Kind:** idempiere · **JAR:** Yes · **Status:** done (ready for agent deploy)

Info Window UU (must already exist): `2b4ab146-0809-47c6-96f3-8b841d60a6bf`

## Agent one-liner (preferred when repo is on the host)

```bash
cd idempiere-plugins/com.aberp.rostering.staffinfo
chmod +x build.sh deploy.sh
./deploy.sh
# builds JAR, applies SQL 01→20→04, restarts idempiere, waits for WebUI HTTP 200
# then: Cache Reset or logout/in
```

## Packages / packs

| Path | Use |
|------|-----|
| Repo | `idempiere-plugins/com.aberp.rostering.staffinfo/` |
| Staging pack | `Downloads\AbilityERP-ClientUpdate-SAW003_staff_rostering_info-20260712\` |
| Thin prod pack | `Downloads\AbilityERP-ProdUpdate-SAW003_staff_rostering_info-20260712\` |

Client hosts without git: use the **thin prod** or **staging** pack HOW-TO (manual JAR + ordered SQL). Do not require git pull as the primary path.

## Bundle

- Symbolic name: `com.aberp.rostering.staffinfo`
- Version in `deploy.sh` / MANIFEST / packs: **`1.1.0.2026071219`**
- Prefer `./build.sh` on the iDempiere host so the JAR version matches MANIFEST
- Pack ships `jar/com.aberp.rostering.staffinfo_1.1.0.2026071219.jar` (or flat JAR in thin prod)

## Ordered SQL (`deploy.sh`)

**Critical:** run in this order. Earlier scripts (esp. `03` / `05` / `09`) can re-show columns — **`20-hide-clutter-columns.sql` must stay last before verify** so the lean result grid sticks.

1. `01-indexes.sql`
2. `02-rewrite-infowindow.sql`
3. `03-rewrite-infocolumns.sql`
4. `05-hotfix-browser-smoke.sql`
5. `06-fix-shift-org.sql`
6. `07-eligibility-criteria.sql`
7. `08-enable-related-info.sql`
8. `09-find-fill-ux.sql`
9. `10-java-ux-org.sql`
10. `11-drop-redundant-criteria.sql`
11. `12-needs-match-criteria.sql`
12. `14-fix-show-unmatched-selectclause.sql`
13. `15-fix-onapprovedleave-criteria.sql`
14. `16-fix-nonnegative-id-criteria.sql`
15. `17-fix-hidden-multiselect-criteria.sql`
16. `18-fix-result-grid-readonly.sql` — displayed result cells read-only when a row is selected
17. `19-rename-staff-name.sql` — grid/criteria label **Staff Name** (was User Name)
18. `20-hide-clutter-columns.sql` — hide BP Name / Status / Business Partner / Agency Staff **from the result line**
19. `04-verify.sql`

Rollback: `sql/99-rollback.sql` then remove JAR / `bundles.info` entry and restart.

**Not in normal deploy:** `13-load-test-needs-match.sql`, `scripts/seed-staffinfo-e2e-shifts.sql` (dev/E2E only).

### What SQL `20` does (agents)

| Column | Grid (`isdisplayed`) | Criteria (`isquerycriteria`) |
|--------|----------------------|------------------------------|
| `BP_Name` | N | N |
| `R_Status_ID` (Status) | N | N |
| `C_BPartner_ID` | N (stays **active** for Related Info) | N |
| `AbERP_isagencystaff` | N | **Y** (filter pane only) |

## Restart / cache

- **Yes** `systemctl restart idempiere` (OSGi JAR)
- **Yes** Cache Reset or logout/in after restart (Info Window AD is cached)
- **Do not** wipe the full OSGi configuration cache as a “fix” (breaks other AbERP plugins)

## Manual JAR notes (client pack)

1. Copy JAR to `plugins/` and `customization-jar/` (per host runbook).
2. Ensure `bundles.info` has **one** line: `com.aberp.rostering.staffinfo,1.1.0.2026071219,plugins/<jar>,4,true` (remove older `staffinfo` lines first).
3. Apply SQL in the order above with `ON_ERROR_STOP=1`.
4. `sudo systemctl restart idempiere` — wait until WebUI returns HTTP 200.
5. Cache Reset / logout-in.

## WebUI smoke

1. **Shift (Rostered) → Employee** → open **Employee (User) / Agency Staff** search (or menu **Employee (User) / Agency Staff Rostering Info**).
2. Name search auto-wraps `%` wildcards; criteria label is **Staff Name**.
3. Layout: **Show Unmatched Staff** under Staff Name; **Show Unavailable Staff** under Employee; **All / Any** = AND when checked, OR when unchecked.
4. Default (from a shift) hides approved leave / overlap for the shift window; **On Approved Leave** / **Show Unmatched Staff** behave as labeled.
5. Top banner shows shift context + needs summary when opened from a shift.
6. **Result grid must NOT show:** BP Name, Status, Business Partner, Agency Staff – Approved for shifts.  
   **Filter pane may still show** Agency Staff – Approved for shifts.
7. Expected grid columns (approx.): Staff Name, Employee, Gender, BP Position, EMail, Phone, On Approved Leave, Has Future Shift (plus selection).
8. Selected-row editors in the grid stay display-only (`18`).
9. Related Info (Rostered Shift / Credentials / Alerts) still available.
10. Picking a contact fills BP (and org sync as designed).
11. Smoke as **AbilityERP Admin** (and Rostering Officer if used on the client).

## Agent pitfalls (from staging)

- After AD SQL alone, **Cache Reset** (or reopen Info) is required — stale MInfoWindow cache keeps old columns.
- Re-running only early SQL without `20` brings clutter columns back.
- SQL-only hotfixes do not need a JAR rebuild; Java UX changes do (`build.sh` + restart).
- Windows agents: OpenSSH `scp`/`ssh` works; avoid PowerShell `$host` (reserved). Prefer `deploy.sh` on the Linux host over remote-editing SQL by hand.
- Optional correctness seed (dev only): `scripts/seed-staffinfo-e2e-shifts.sql` + `scripts/verify-staffinfo-e2e-seed.sql`.

## Blockers / prerequisites

- Target must already have Info Window UU `2b4ab146-0809-47c6-96f3-8b841d60a6bf`.
- No app/API deploy required (Kind `idempiere`).
- Host needs Java 11 + iDempiere 7.1 libs to **build**; pack JAR can be used if pre-built.

## Agent prompt (copy/paste)

> Deploy SAW003 per `Tickets/SAW003_staff_rostering_info/DEPLOY.md` on staging (or the named Downloads pack). Prefer `./deploy.sh` when the repo is on the host. Run WebUI smoke (especially hidden grid columns + Staff Name / filter tick layout), then report pass/fail.

## AbilityERP Admin access (mandatory)

Install SQL / deploy must grant **AbilityERP Admin** access to every new or newly exposed **window**, **process**, **Info Window**, and **form** (and process access for toolbar buttons). See `docs/DEV-REQUIREMENTS.md`. After grant: Role Access Update or logout/in. Smoke as Admin.
