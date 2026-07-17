# SAW020 — HCO20260714 Test Release Deployment

| | |
|--|--|
| **Status** | done — HCO Test dry run PASS; Ready for next HCO Production deployment |
| **Kind** | idempiere |
| **GitHub** | [#20](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/20) |
| **Slug** | `SAW020_hco20260714_release` |
| **Release** | **HCO20260714** |
| **Environment** | HCO Test (dry run for next HCO Production) |
| **Host** | `54.253.165.194` (`ip-172-31-3-32` / `i-0efcb96f5b2cf1b6a`) |

## Deploy (other builds / Production) — start here

**→ [`DEPLOY.md`](DEPLOY.md)** — Production Deployment Runbook from this dry run  
**→ [`report/DEPLOYMENT-REPORT.md`](report/DEPLOYMENT-REPORT.md)** — full evidence log  
**→ [`report/RELEASE-UPDATES.md`](report/RELEASE-UPDATES.md)** — post dry-run additions and bumps (SAW003 **`1517`** + SQL `25`/`26`, SAW017 `160730`, SAW026 Vehicle Activity) to fold into Production

## External ticket (copy/paste)

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

Deploy the complete HCO20260714 release package to HCO Test in fixed order, validate each item, and retain documentation for reuse on HCO Production.

## Deployment order

| Order | Ticket | Description |
| ----: | ------ | ----------- |
| 1 | SAW018 | HCO release packins |
| 2 | SAW001 | Paid filter on Notification SR Invoice Send Info |
| 3 | SAW003 | Staff Rostering Info / Shift Employee Search |
| 4 | SAW007 | Activity tabs |
| 5 | SAW009 | Support Start/End Day pattern numbers |
| 6 | SAW010 | Timesheet Approval Info columns |
| 7–8 | SAW013 | HCO Forms enhancements + Create Request template filter |
| 9 | SAW015 | Skip Dates — Copy Dates From |
| 10 | SAW014 | Support Location Email/Phone ColumnSQL |
| 11 | SAW017 | Bulk Booking Generator |
| 12 | SAW026 | Vehicle Activity tab |

Per-ticket agent runbooks remain under each `Tickets/SAW###_…/DEPLOY.md`.

## Access (this dry run)

| | |
|--|--|
| SSH | `ubuntu@54.253.165.194` — key `C:\Users\sawte\Documents\SSH Keys\HCObusiness.pem` (also `~\.ssh\HCObusiness.pem`) |
| WebUI | `http://54.253.165.194/webui/` |
| Login | `SuperUser` / `HCOflamingo` |
| Smoke role | **Admin** |
| DB | `idempiere` / `adempiere` / `flamingo` |
| iDempiere home | `/opt/idempiere-server` |

**Note:** Prior HCO Test playbook host `13.210.248.141` (`Test`) already carries most of these tickets from earlier installs. This release dry-runs on **`54.253.165.194`** as a clean production rehearsal.

## Hard rules

1. Never change HCO `*_UU` values.
2. Resolve targets by `*_UU` or stable name — never hardcode `AD_*_ID`.
3. Append `Tickets/HCO_Deployment/LEARNINGS.md` after the release install.
4. Prefer Downloads ProdUpdate packs + ticket DEPLOY.md over ad-hoc SQL.

## Dependencies (app)

None for this release orchestration ticket.
