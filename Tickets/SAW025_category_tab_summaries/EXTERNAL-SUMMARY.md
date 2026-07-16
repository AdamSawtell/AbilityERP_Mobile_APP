# SAW025 — Category tab summaries (external)

## What’s done

Each Organisation Audit category tab now starts with a **population summary**, a **90-day change**, and an expanded set of **readiness / findings / category KPIs** in the same two-column readonly layout as before.

## What changed

### Population (all tabs)

| Tab | Summary | Change |
|-----|---------|--------|
| Employee | Active Employees | Change (90d) |
| Client | Active Clients (Support Receiver) | Change (90d) |
| Incidents | Active Incidents (open) | Change (90d) |
| Rostering | Current Roster | Next Roster (not 90d avg) |
| Documentation | Total Documents | Change (90d) |

### Shared KPIs (all category tabs)

Readiness Score, Status (R/A/G), Open Findings, Critical Open, Open >7/30/90d, New Findings (30d), Resolved (30d), Top Finding.

### Category-specific KPIs

| Tab | Extra KPIs |
|-----|------------|
| Employee | Screening Expired / Due (30d), Credentials Current %, New Starters Missing Docs, Unavailable Today, Rostered This Period |
| Client | Risk Reviews Overdue / Due (30d), No Support (30d), Plan Reviews Due (30d), Plans Expired, Assessments Current |
| Incidents | Closed (30d), Investigations Overdue, Outstanding Actions, Reportable Open, Median Days Open, Oldest Open (days) |
| Rostering | Current/Next Fill Rate %, Current/Next Unfilled, Current/Next Filled, Current/Next Cancelled, Current/Next Missing Cred |
| Documentation | Expired / Due (30d) / Current Documents, Current %, Onboarding Expired, Added (90d), Expired in 90d, Missing Evidence |

## Impact

Admins get workforce, client, incident, roster and document context above the Open Findings list — without leaving the tab.

## How to test

1. Open **Organisation Audit → Audit Hub**
2. On each of Employee / Client / Incidents / Rostering / Documentation, confirm the summary and KPI fields at the top populate (not blank) and no error dialog appears
3. Spot-check: Active Clients ≈ Client window count; Rostering Fill Rate near 100% when most shifts are filled

## Access

AbilityERP Admin already has the window/process from SAW023.

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |

## Windows / processes / objects affected

| Object | Name | Notes |
|--------|------|-------|
| Window | NDIS Audit Tool | Population + KPI fields on category tabs |
| Table/View | AbERP_ComplianceDashboard | Population columns + virtual KPI columns |
| Table | AbERP_ComplianceSnapshot | `PopulationCount` |
| DB functions | `aberp_compliance_*` | Live KPI calculations |
| Process | Refresh Compliance | Stores population on refresh |
