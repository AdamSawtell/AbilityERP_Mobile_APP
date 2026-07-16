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
- NDIS Audit Tool: Audit Readiness 76.4, Traffic Light Red, Total Items 1,234
- Employee tab: Total 412, Compliant 389, identical field template
- Category tabs via Organisation Audit detail: Employee, Client, Incidents, Rostering, Documentation
- Phase 2: OSGi `com.aberp.compliance` ACTIVE; **Refresh Compliance** stub OK
- Phase 3: Employee rules live — Refresh wrote 123 NC + 65 WARN + 8 CRIT; W snapshot 9060 / score 98.20 / Red
- Phase 3b/4: 10 active rules (W3/P2/I2/R2/D1); Info Window Compliance Results; packs 20260716; JAR `7.1.0.202607161100`

## Phase 3 rule sources

| Rule | Source |
|------|--------|
| Employee credential expired | `aberp_credentialassignment.aberp_expirydate < today` |
| Credential expires within 30 days | expiry within `DaysBeforeExpiry` (30) |
| Worker screening expired | expired + name matches Worker Screening / Working with Child |
| Risk assessment overdue | `aberp_risks.validto < today` |
| Missing active Service Agreement | seeded; skipped when SA table has no usable dates |
| Incident investigation overdue | `aberp_incident` past due, not Closed |
| Outstanding incident actions | `hco_incident_actions` active + incomplete |
| Upcoming shift unfilled | `aberp_rostered_shift` next N days, no staff |
| Staff assigned without required credential | shift staff + rostering needs CRD |
| Onboarding documentation expired | credential assignments in Onboarding Documentation category |

## Scope sources

- Obsidian: Compliance & Audit Hub (Phase 1) — iDempiere
- Obsidian: Pre-Build Review Gate

## HCO Future Deployments variables

(none yet — this `3.27.207.215` build is labelled Audit Tool Build V1 / HCO Test; not production HCO)
