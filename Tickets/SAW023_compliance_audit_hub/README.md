# SAW023 — Compliance & Audit Hub (NDIS Audit Tool)

| | |
|--|--|
| **Status** | done |
| **Kind** | idempiere |
| **GitHub** | [#23](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/23) |
| **Slug** | `SAW023_compliance_audit_hub` |
| **Dev host** | `3.27.207.215` |

## Deploy

**→ [`DEPLOY.md`](DEPLOY.md)**

## External ticket

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

Centralised NDIS Compliance & Audit Hub: Organisation Audit KPIs + Employee / Client / Incidents / Rostering / Documentation tabs, configurable rules, results, snapshots, Refresh Compliance process, Compliance Results Info Window.

## Source of truth

| Item | Path |
|------|------|
| Plugin / SQL | `idempiere-plugins/com.aberp.compliance/` |
| AD SQL | `sql/00` … `sql/17` |
| JAR | `com.aberp.compliance_7.1.0.202607161100.jar` |

## Access

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Window | Compliance Rules | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |
| Info Window | Compliance Results | — |

## Phase plan

1. **Skeleton** — tables, refs, dashboard VIEW, NDIS Audit Tool + Rules windows, menu ✅
2. **Refresh process + OSGi** — toolbar button + factory ✅
3. **Employee + remaining category rules** ✅
4. **Info Window + client packs** ✅
