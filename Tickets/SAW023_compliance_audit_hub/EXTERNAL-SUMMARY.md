# Compliance & Audit Hub (Phase 1 skeleton) — external summary

## Windows / processes / objects affected

| Type | Name | Notes |
|------|------|-------|
| Menu folder | NDIS Audit Tool | Under Ability ERP when present |
| Window | NDIS Audit Tool | Organisation Audit header + Employee / Client / Incidents / Rostering / Documentation tabs |
| Window | Compliance Rules | Admin rule configuration |
| Tables | Compliance Rule / Result / Snapshot | New AbERP tables |
| View | Compliance Dashboard | Read-only pivoted KPIs for Organisation Audit |

## What’s done

Skeleton of the NDIS Audit Tool is installed on the development server: data model, Compliance Rules window, and a read-only audit window with Organisation Audit header plus category tabs.

## What changed

Users can open **NDIS Audit Tool** (Admin role) and see organisation-wide audit readiness KPIs, then drill into Employee, Client, Incidents, Rostering, and Documentation tabs. Numbers currently come from a development seed / stub snapshot pipeline — live rule evaluation and drill-down come in later phases.

## Impact

No change to existing operational windows (Employee, Rostering, Incidents, etc.). NDIS Audit Tool is read-only.

## How to test

1. Log in as Admin / AbilityERP Admin
2. Search for **NDIS Audit Tool** (or Ability ERP → NDIS Audit Tool)
3. Confirm Organisation Audit header KPIs and category tabs
4. Open **Compliance Rules** (empty is OK)

## Access

AbilityERP Admin and Admin can open the new windows.

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Window | Compliance Rules | — |

## Caveats

Refresh process, Audit Results Info Window, and the ten live compliance rules are not included in this skeleton drop.
