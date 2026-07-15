# Compliance & Audit Hub (Phase 1 skeleton) — external summary

## Windows / processes / objects affected

| Type | Name | Notes |
|------|------|-------|
| Menu folder | Compliance & Audit Hub | Under Ability ERP when present |
| Window | Compliance Summary | Overall KPIs + Employee / Client / Incidents / Rostering / Documentation tabs |
| Window | Compliance Rules | Admin rule configuration |
| Tables | Compliance Rule / Result / Snapshot | New AbERP tables |
| View | Compliance Dashboard | Read-only pivoted KPIs for Summary |

## What’s done

Skeleton of the NDIS Compliance & Audit Hub is installed on the development server: data model, Configuration Rules window, and a read-only Summary window with functional category tabs.

## What changed

Users can open a central Compliance Summary and see the same KPI layout on each function tab (Employee, Client, Incidents, Rostering, Documentation). Numbers currently come from a development seed / stub snapshot pipeline — live rule evaluation and drill-down come in later phases.

## Impact

No change to existing operational windows (Employee, Rostering, Incidents, etc.). Summary is read-only.

## How to test

1. Log in as Admin / AbilityERP Admin
2. Open **Compliance & Audit Hub → Compliance Summary**
3. Confirm tabs and field layout
4. Open **Compliance Rules** (empty is OK)

## Access

AbilityERP Admin and Admin can open the new windows.

| Access | Name | Search key |
|--------|------|------------|
| Window | Compliance Summary | — |
| Window | Compliance Rules | — |

## Caveats

Refresh process, Audit Results Info Window, and the ten live compliance rules are not included in this skeleton drop.
