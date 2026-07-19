# SAW025 — Category KPIs & layout (external)

## What’s done

The Organisation Audit lead page and each category tab show population, readiness, and category KPIs in a progressive layout. Primary calculations include visible plain-language explanations; secondary trends and compliance breakdowns remain available in collapsed sections.

### Page layout

- **At a glance** — population, readiness, status and current findings counts, with calculation explanations
- **Action required** — category-specific operational KPIs and a visible calculation guide
- **Trends and ageing** — collapsed by default
- **Compliance breakdown** — collapsed by default

The lead page explains the overall readiness score, traffic light, total checks, compliant/warning/non-compliant/critical counts and refresh time.

Findings lists and **Open & Fix** are covered by the separate Findings navigation work (SAW024).

## What changed

### Population (all tabs)

| Tab | Summary | Change |
|-----|---------|--------|
| Employee | Active Employees | Change (90d) |
| Client | Active Clients (Support Receiver) | Change (90d) |
| Incidents | Active Incidents (open) | Change (90d) |
| Rostering | Current Roster | Next Roster (not 90d avg) |
| Documentation | Total Documents | Change (90d) |
| Support Location | Active Support Locations | Change (90d) |

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
| Support Location | Vacant Locations, SDA Enrolled, Wheelchair Accessible, Bushfire Danger Area, Meets Expectations |

## Impact

Admins get workforce, client, incident, roster, document and support-location context without leaving the category tab. Persistent explanations make the primary calculations understandable, while collapsed secondary sections reduce page clutter.

## How to test

1. Open **Organisation Audit → Audit Hub**
2. On the lead page, confirm explanations appear beside each overall calculation
3. On each category tab (including **Support Location**), use form/detail view and confirm **At a glance** and **Action required** are open
4. Confirm explanation text appears under population, readiness/status, findings counts and category action calculations
5. Confirm **Trends and ageing** and **Compliance breakdown** are collapsed
6. Spot-check: Active Clients ≈ Client window count; Rostering Fill Rate near 100% when most shifts are filled; Support Location Active count ≈ Support Location window

## Access

AbilityERP Admin already has the window/process from SAW023.

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |

## Windows / processes / objects affected

| Object | Name | Notes |
|--------|------|-------|
| Window | NDIS Audit Tool | Grouped KPI fields + persistent explainers |
| Table/View | AbERP_ComplianceDashboard | Population columns + virtual KPI columns |
| Table | AbERP_ComplianceSnapshot | `PopulationCount` |
| DB functions | `aberp_compliance_*` | Live KPI calculations |
| Process | Refresh Compliance | Stores population on refresh |
