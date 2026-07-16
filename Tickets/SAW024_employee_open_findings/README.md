# SAW024 — Employee Open Findings POC

| | |
|--|--|
| **Status** | in-progress |
| **Kind** | idempiere |
| **GitHub** | [#24](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/24) |
| **Slug** | `SAW024_employee_open_findings` |
| **Depends on** | SAW023 (NDIS Audit Tool) |

## Deploy

**→ [`DEPLOY.md`](DEPLOY.md)**

## External ticket

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

Under **NDIS Audit Tool → Employee**, add **Open Findings**: why the issue exists, what to resolve, Zoom Across to **Credential Assignment**.

## Source of truth

| Item | Path |
|------|------|
| SQL | `idempiere-plugins/com.aberp.compliance/sql/18-employee-open-findings.sql` |
| JAR | None |

## Access

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |
| Window | Credential Assignment | — |
