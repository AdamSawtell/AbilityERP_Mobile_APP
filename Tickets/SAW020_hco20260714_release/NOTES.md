# SAW020 — Notes

## HCO Future Deployments variables

### HCO Test dry-run host (HCO20260714)

| Variable | Value |
|----------|--------|
| Public IP | `54.253.165.194` |
| Hostname | `ip-172-31-3-32` |
| Instance ID | `i-0efcb96f5b2cf1b6a` |
| Private IP | `172.31.3.32` |
| SSH key | `C:\Users\sawte\Documents\SSH Keys\HCObusiness.pem` (working copy also `~\.ssh\HCObusiness.pem`) |
| WebUI | `http://54.253.165.194/webui/` |
| SuperUser password | `HCOflamingo` |
| Smoke role | Admin |
| DB | idempiere / adempiere / flamingo |
| iDempiere home | `/opt/idempiere-server` |
| Staging dir | `/tmp/HCO20260714/` |

### Prior HCO Test (already installed — do not confuse)

| Variable | Value |
|----------|--------|
| Public IP | `13.210.248.141` |
| Hostname | `Test` |
| Instance ID | `i-082378c076a2ed17d` |
| Note | Carries SAW001–018 installs from 2026-07-12/13 |

### Baseline before HCO20260714 on `54.253.165.194` (2026-07-14)

| Marker | State |
|--------|--------|
| Paid Info criteria | MISSING |
| Staff Rostering Info window UU | present (bundle absent) |
| Timesheet Break Start InfoColumn | MISSING |
| SAW013 Request Submitted column | MISSING |
| Copy Dates From process | MISSING |
| Support Location Email ColumnSQL | still `@SQL=` |
| `hco_cred_missing_staff_v` | MISSING |
| Bulk Generate Bookings process | MISSING |
| `c_orderline.aberp_support_start_day` | EXISTS (physical) |
| Key AbERP release bundles in `bundles.info` | none |

## Decisions

1. Dry-run target is **`54.253.165.194`** per release ticket (not the earlier `13.210.248.141` Test host).
2. Prefer thin ProdUpdate packs from Downloads for Production-shaped installs.
3. SAW013 items 7 and 8 in the release list are one SQL pack (forms + template filter).

## Open / risks

- SAW018 PackIn may need legacy `employee.infopanel` Incremental2Pack cleared (see SAW018 NOTES).
- SAW017 needs generator stack JARs if Generate Bookings bytecode is not ACTIVE.
- Prefer `systemctl stop` then `start` (or init.d) over bare `restart` when Java is already down.

## Session log

See [`report/DEPLOYMENT-REPORT.md`](report/DEPLOYMENT-REPORT.md).

### HCO20260714 dry-run outcome (2026-07-14)

| Item | Value |
|------|--------|
| Verdict | Ready for next HCO Production deployment |
| SAW018 package_imp | `1001029` credentials · `1001030` employee · `1001031` supportlocation · `1001032` client |
| Support Location UU | unchanged `6ef3c558-3ec8-4f0c-be40-89f35d8acebf` |
| Key JARs | staffinfo `1237` · skipdates `202607131830` · bulk `202607132235` + generator stack |
