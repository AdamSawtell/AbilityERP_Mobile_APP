# SAW003 — Deploy to another build

**Ticket:** SAW003_staff_rostering_info · **Kind:** idempiere · **JAR:** Yes · **Status:** done (ready for agent deploy)

Info Window UU (must already exist): 2b4ab146-0809-47c6-96f3-8b841d60a6bf

## Agent one-liner (preferred when repo is on the host)

bash
cd idempiere-plugins/com.aberp.rostering.staffinfo
chmod +x build.sh deploy.sh
./deploy.sh
# builds JAR, applies SQL 01→20→04, restarts idempiere, waits for WebUI HTTP 200
# then: Cache Reset or logout/in


## Packages / packs

| Path | Use |
|------|-----|
| Repo | idempiere-plugins/com.aberp.rostering.staffinfo/ |
| Staging pack | Downloads\AbilityERP-ClientUpdate-SAW003_staff_rostering_info-20260712\ |
| Thin prod pack | Downloads\AbilityERP-ProdUpdate-SAW003_staff_rostering_info-20260712\ |

Client hosts without git: use the **thin prod** or **staging** pack HOW-TO (manual JAR + ordered SQL). Do not require git pull as the primary path.

## Bundle

- Symbolic name: com.aberp.rostering.staffinfo
- Version in deploy.sh / MANIFEST: 1.1.0.2026071219 (rebuild on host via build.sh for exact match)
- Pack may ship the newest release/*.jar available; if versions differ, **run build.sh on the iDempiere host** before install

## Ordered SQL (deploy.sh)

1. 01-indexes.sql
2. 02-rewrite-infowindow.sql
3. 03-rewrite-infocolumns.sql
4. 05-hotfix-browser-smoke.sql
5. 06-fix-shift-org.sql
6. 07-eligibility-criteria.sql
7. 08-enable-related-info.sql
8. 09-find-fill-ux.sql
9. 10-java-ux-org.sql
10. 11-drop-redundant-criteria.sql
11. 12-needs-match-criteria.sql
12. 14-fix-show-unmatched-selectclause.sql
13. 15-fix-onapprovedleave-criteria.sql
14. 16-fix-nonnegative-id-criteria.sql
15. 17-fix-hidden-multiselect-criteria.sql
16. 18-fix-result-grid-readonly.sql
17. 19-rename-staff-name.sql
18. 20-hide-clutter-columns.sql
19. 04-verify.sql

Rollback: sql/99-rollback.sql then remove JAR / bundles.info entry and restart.

Not in normal deploy: 13-load-test-needs-match.sql.

## Restart / cache

- **Yes** systemctl restart idempiere (OSGi JAR)
- **Yes** Cache Reset or logout/in after restart

## Manual JAR notes (client pack)

1. Copy JAR to plugins/ and customization-jar/ (per host runbook).
2. Ensure bundles.info has one line: com.aberp.rostering.staffinfo,<version>,plugins/<jar>,4,true (remove older staffinfo lines first).
3. Apply SQL in the order above with ON_ERROR_STOP=1.
4. sudo systemctl restart idempiere — wait until WebUI returns HTTP 200.
5. Cache Reset / logout-in.

## WebUI smoke

1. **Shift (Rostered) → Employee** → open **Employee (User) / Agency Staff** search.
2. Name search auto-wraps % wildcards.
3. Default hides approved leave / overlap for the shift window; **On Approved Leave** / **Show Unmatched Staff** behave as labeled.
4. Top banner shows shift context + needs summary when opened from a shift.
5. Related Info (Rostered Shift / Credentials / Alerts) still available.
6. Picking a contact fills BP (and org sync as designed).

## Blockers / prerequisites

- Target must already have Info Window UU 2b4ab146-0809-47c6-96f3-8b841d60a6bf.
- No app/API deploy required (Kind idempiere).
- Host needs Java 11 + iDempiere 7.1 libs to **build**; pack JAR can be used if pre-built.

## Agent prompt (copy/paste)

> Deploy SAW003 per Tickets/SAW003_staff_rostering_info/DEPLOY.md on staging (or the named Downloads pack). Run WebUI smoke, then report pass/fail.

## AbilityERP Admin access (mandatory)

Install SQL / deploy must grant **AbilityERP Admin** access to every new or newly exposed **window**, **process**, **Info Window**, and **form** (and process access for toolbar buttons). See docs/DEV-REQUIREMENTS.md. After grant: Role Access Update or logout/in. Smoke as Admin.
