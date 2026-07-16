# SAW025 — Category tab population summaries

| | |
|--|--|
| **Status** | in-progress |
| **Kind** | idempiere |
| **GitHub** | [#25](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/25) |
| **Slug** | `SAW025_category_tab_summaries` |
| **Depends on** | SAW023 / SAW024 (NDIS Audit Tool) |

## Deploy

**→ [`DEPLOY.md`](DEPLOY.md)**

## External ticket

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

At the top of each Organisation Audit category tab, show a population summary and 90-day change. Tab layout will be refined in later reviews.

## Source of truth

| Item | Path |
|------|------|
| SQL | `idempiere-plugins/com.aberp.compliance/sql/35-category-population-summary.sql` |
| Engine | `idempiere-plugins/com.aberp.compliance/src/com/aberp/compliance/ComplianceEngine.java` |
| JAR | `com.aberp.compliance_7.1.0.202607170530` |

## Access

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |
