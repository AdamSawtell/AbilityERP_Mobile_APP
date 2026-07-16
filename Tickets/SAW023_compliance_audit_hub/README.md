# SAW023 — Compliance & Audit Hub (NDIS Audit Tool)

| | |
|--|--|
| **Status** | in-progress (skeleton) |
| **Kind** | idempiere |
| **GitHub** | [#23](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/23) |
| **Slug** | `SAW023_compliance_audit_hub` |
| **Dev host** | `3.27.207.215` |

## Deploy

**→ [`DEPLOY.md`](DEPLOY.md)**

## External ticket

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

Centralised NDIS Compliance & Audit Hub: Summary window (overall KPIs + Employee / Client / Incidents / Rostering / Documentation tabs), configurable rules, results, snapshots, refresh process, Audit Results Info Window.

## Source of truth

| Item | Path |
|------|------|
| Plugin / SQL | `idempiere-plugins/com.aberp.compliance/` |
| AD SQL | `sql/00` … `sql/09` |

## Access

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Window | Compliance Rules | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |

## Phase plan

1. **Skeleton** — tables, refs, stub dashboard VIEW, NDIS Audit Tool + Rules windows, menu ✅
2. **Refresh process + OSGi** — toolbar button + factory (stub → live later) 🔄
3. Category views + rules (Employee first)
4. Info Window + packs
