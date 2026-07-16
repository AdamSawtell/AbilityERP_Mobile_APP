# SAW020 — Deploy HCO20260714 (agent / Production runbook)

**Ticket / slug:** `SAW020_hco20260714_release`  
**Release:** HCO20260714  
**Kind:** idempiere · **JAR:** Yes (SAW003 / SAW015 / SAW017 + optional SAW007 marker)  
**GitHub:** [#20](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/20)  
**Evidence:** [`report/DEPLOYMENT-REPORT.md`](report/DEPLOYMENT-REPORT.md)

This file is the **Production Deployment Runbook** distilled from the HCO Test dry run on `54.253.165.194`.

## Required host access

| Need | Why |
|------|-----|
| SSH to iDempiere host | Copy packs, run SQL, OSGi / restart |
| `psql` on `idempiere` / `adempiere` | Migrations + verify |
| WebUI **System Administrator** | SAW018 Pack In from Folder (preferred) |
| WebUI **Admin** | Cache Reset + smoke each ticket |
| Java 11 | Build JARs on host when pack JARs not used |

## Target (HCO Test dry run)

| | |
|--|--|
| Host | `54.253.165.194` |
| SSH | `ubuntu@54.253.165.194` + `HCObusiness.pem` |
| WebUI | `http://54.253.165.194/webui/` — SuperUser / HCOflamingo → **Admin** |
| DB | `idempiere` · `adempiere` · `flamingo` |
| Home | `/opt/idempiere-server` |

Hard rules: never change existing HCO `*_UU`; fix AbilityERP SQL/process instead.

## Staging area on host

```text
/tmp/HCO20260714/
  SAW018/ … SAW017/     # thin ProdUpdate packs (or client packs)
```

## Ordered install (mandatory)

| # | Ticket | Artifacts | Restart? | Cache Reset? |
|---|--------|-----------|----------|--------------|
| 1 | SAW018 | SQL view + 4× `*_SYSTEM_hco_*.zip` PackIn | Maybe (PackInFolder stops OSGi app) | Yes |
| 2 | SAW001 | SQL only (`com.aberp.notification.invoiceinfo`) | No | Yes |
| 3 | SAW003 | SQL through **`26`** + JAR `com.aberp.rostering.staffinfo_1.1.0.2026071517` | **Yes** | Yes |
| 4 | SAW007 | SQL (+ optional marker JAR) | If JAR | Yes |
| 5 | SAW009 | SQL only | No | Yes |
| 6 | SAW010 | SQL only | No | Yes |
| 7–8 | SAW013 | SQL only (`00`→`01`→`02`→`03`→`05`→`04`) | No | Yes |
| 9 | SAW015 | SQL + JAR `com.aberp.skipdates.copyfrom_7.1.0.202607131830` | **Yes** (stop then start) | Yes |
| 10 | SAW014 | SQL only | No | Yes |
| 11 | SAW017 | Generator stack (if missing) + bulk JAR **`7.1.0.202607160730`** + SQL `00`–`04` | **Yes** | Yes |

After each ticket: verify SQL markers → Cache Reset / logout-in → WebUI smoke (see per-ticket DEPLOY.md).

**Post dry-run JAR bumps** (already applied on Test; fold into Production): see [`report/RELEASE-UPDATES.md`](report/RELEASE-UPDATES.md) (SAW003 `1516`, SAW017 `160730`).

### Per-ticket pointers

| Ticket | Deploy runbook | Thin pack (Downloads) |
|--------|----------------|------------------------|
| SAW018 | `Tickets/SAW018_hco_release_packins/DEPLOY.md` | `AbilityERP-ProdUpdate-SAW018_hco_release_packins-20260713` |
| SAW001 | `Tickets/SAW001_paid_filter_invoice_send_info/DEPLOY.md` | `AbilityERP-ProdUpdate-SAW001_paid_filter_invoice_send_info-20260712` |
| SAW003 | `Tickets/SAW003_staff_rostering_info/DEPLOY.md` | Prefer JAR **`1517`** + SQL through **`26`** (`release/…1517.jar`) — see RELEASE-UPDATES |
| SAW007 | `Tickets/SAW007_activity_tab_integration/DEPLOY.md` | `AbilityERP-ProdUpdate-SAW007_activity_tab_integration-20260712` |
| SAW009 | `Tickets/SAW009_support_day_pattern_number/DEPLOY.md` | `AbilityERP-ProdUpdate-SAW009_support_day_pattern_number-20260713` |
| SAW010 | `Tickets/SAW010_timesheet_approval_info_columns/DEPLOY.md` | `AbilityERP-ProdUpdate-SAW010_timesheet_approval_info_columns-20260712` |
| SAW013 | `Tickets/SAW013_shift_change_form_enhancements/DEPLOY.md` | `AbilityERP-ProdUpdate-SAW013_shift_change_form_enhancements-20260713` |
| SAW015 | `Tickets/SAW015_skip_dates_copy_from/DEPLOY.md` | `AbilityERP-ProdUpdate-SAW015_skip_dates_copy_from-20260713` |
| SAW014 | `Tickets/SAW014_support_location_contact_grid/DEPLOY.md` | `AbilityERP-ProdUpdate-SAW014_support_location_contact_grid-20260713` |
| SAW017 | `Tickets/SAW017_booking_generator_bulk/DEPLOY.md` | **`AbilityERP-ProdUpdate-SAW017_booking_generator_bulk-20260716`** (bulk `…160730`) |

## AbilityERP Admin access

Each ticket’s SQL grants **Admin** + **AbilityERP Admin** where new Info / process / menu objects are created (SAW001, SAW015, SAW017, etc.). Smoke as **Admin** on HCO.

## Rollback (high level)

| Ticket | Rollback |
|--------|----------|
| SAW018 | Package Maintenance uninstall (high risk on Support Location) — prefer DB backup restore; drop view `hco_cred_missing_staff_v` |
| SAW001 | `sql/99-rollback.sql` |
| SAW003 | `sql/99-rollback.sql` + remove JAR / bundles.info + restart |
| SAW007 | Deactivate added tabs / reverse portable SQL carefully |
| SAW009 | `sql/99-rollback.sql` |
| SAW010 | `sql/99-rollback.sql` |
| SAW013 | `sql/99-rollback.sql` |
| SAW015 | `sql/99-rollback.sql` + remove JAR |
| SAW014 | `sql/99-rollback.sql` |
| SAW017 | Deactivate process/menu + stop bulk bundle |

Always Cache Reset after rollback.

## Post-deploy verification (release)

1. WebUI HTTP 200; no fatal OSGi errors for AbERP release bundles.  
2. All verify SQL from per-ticket packs green.  
3. Smoke matrix in `report/DEPLOYMENT-REPORT.md` all Pass.  
4. No HCO `*_UU` values altered for pre-existing objects.  
5. Mark release **Ready for next HCO Production deployment**.
