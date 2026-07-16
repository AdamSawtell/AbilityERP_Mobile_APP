# SAW023 — NDIS Audit Tool (external summary)

## What’s done

Organisation-level **NDIS Audit Tool** for AbilityERP: refresh compliance across Employee, Client, Incidents, Rostering, and Documentation; browse findings in **Compliance Results**.

## What changed

- Window **NDIS Audit Tool** with Organisation Audit summary and category tabs
- Process **Refresh Compliance** (`AbERP_Compliance_Refresh`)
- Seeded live rules (credentials, risks, incidents, rostering, onboarding docs)
- Info Window **Compliance Results** for filtering findings
- Window **Compliance Rules** for rule configuration

## Impact

Admins can score NDIS-related compliance gaps and drill into open findings without leaving WebUI.

## How to test

1. Log in as **Admin** (or AbilityERP Admin).
2. Open **NDIS Audit Tool** → click **Refresh Compliance**.
3. Confirm summary KPIs update; open category tabs for detail.
4. Open **Compliance Results** and filter by Status / Severity.
5. Open **Compliance Rules** and confirm rules are Active.

## Access

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Window | Compliance Rules | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |
| Info Window | Compliance Results | — |

Install SQL grants these to **AbilityERP Admin** (and **Admin** / System Administrator where applicable).
