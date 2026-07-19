# SAW024 — Organisation Audit Findings navigation

| | |
|--|--|
| **Status** | in-progress |
| **Kind** | idempiere |
| **GitHub** | [#24](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/24) |
| **Slug** | `SAW024_employee_open_findings` |
| **Depends on** | SAW023 (NDIS Audit Tool); SAW025 population fields for SQL 40 DisplayLogic |

## Deploy

**→ [`DEPLOY.md`](DEPLOY.md)**

## External ticket

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

One function: **Findings navigation** on Organisation Audit — nested Findings under each category, **Open & Fix** to the source record, and Findings subtabs visible only after the parent category is selected (not on the lead page).

## Source of truth

| Item | Path |
|------|------|
| SQL | `idempiere-plugins/com.aberp.compliance/sql/18`–`34` (Findings nest, Open & Fix, menu) |
| SQL | `idempiere-plugins/com.aberp.compliance/sql/40-findings-parent-only-navigation.sql` |
| JAR | `com.aberp.compliance` (OpenComplianceSource / AEnv zoom) |

## Access

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Menu | Organisation Audit (folder) | — |
| Menu | Audit Hub | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |
| Process | Open & Fix | `AbERP_Compliance_OpenSource` |
| Window | Credential Assignment | — |
