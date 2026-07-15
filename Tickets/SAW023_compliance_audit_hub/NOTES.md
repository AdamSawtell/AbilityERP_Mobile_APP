# SAW023 — Notes

## Decisions

- Support Location FK: `AbERP_Support_Location_ID` → `aberp_support_location` / AD `AbERP_Support_Location`
- Employee FK: `AD_User_ID`
- Summary UI: Summary tab + functional category tabs (breadcrumb tab switcher in ZK)
- Dashboard: VIEW `aberp_compliancedashboard` registered as `AbERP_ComplianceDashboard` (IsView=Y); one row per AD_Client
- EntityType: `Ab_ERP`

## Dev host

| | |
|--|--|
| Host | `3.27.207.215` |
| SSH | `ubuntu@…` + `Documents\SSH Keys\HCObusiness.pem` |
| WebUI | `http://3.27.207.215/webui/` |
| Login | SuperUser / `HCOflamingo` · client **HCO** · role **Admin** |

## Smoke (2026-07-16)

- SQL verify: tables 3, view 1, AD tables 4, windows 2, summary tabs 6, seed snaps multi-client
- Compliance Summary: Audit Readiness 76.4, Traffic Light Red, Total Items 1,234
- Employee tab: Total 412, Compliant 389, identical field template
- Category tabs via Summary ▼ breadcrumb: Employee, Client, Incidents, Rostering, Documentation

## Scope sources

- Obsidian: Compliance & Audit Hub (Phase 1) — iDempiere
- Obsidian: Pre-Build Review Gate

## HCO Future Deployments variables

(none yet — this `3.27.207.215` build is labelled Audit Tool Build V1 / HCO Test; not production HCO)
