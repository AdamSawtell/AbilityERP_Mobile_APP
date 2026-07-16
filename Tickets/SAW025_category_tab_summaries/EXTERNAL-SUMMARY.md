# SAW025 — Category tab summaries (external)

## What’s done

Each Organisation Audit category tab now starts with a **population summary** and a **90-day change** figure (layout will be refined in later reviews).

## What changed

| Tab | Summary | Change |
|-----|---------|--------|
| Employee | Active Employees | Change (90d) |
| Client | Active Clients | Change (90d) |
| Incidents | Active Incidents (open) | Change (90d) |
| Rostering | Shifts (Current Period) | vs 90d Period Avg |
| Documentation | Total Documents | Change (90d) |

## Impact

Admins see headcount / volume context above compliance KPIs without leaving the tab.

## How to test

1. Open **Organisation Audit → Audit Hub**
2. On **Employee**, confirm Active Employees and Change (90d) sit at the top
3. Spot-check Client, Incidents, Rostering, Documentation

## Access

AbilityERP Admin already has the window/process from SAW023.

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |

## Windows / processes / objects affected

| Object | Name | Notes |
|--------|------|-------|
| Window | NDIS Audit Tool | New fields on category tabs |
| Table/View | AbERP_ComplianceDashboard | Population columns |
| Table | AbERP_ComplianceSnapshot | `PopulationCount` |
| Process | Refresh Compliance | Stores population on refresh |
