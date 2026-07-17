## Summary

Configurable **Activity Audit** that reviews recently created/updated Contact Activities (`C_ContactActivity`) for organisation-specific words/phrases indicating risk, incident or compliance concern. Nightly incremental process creates review items with zoom to the Activity; authorised users mark reviewed. Separate historical reprocess for new terms.

## Kind

`idempiere`

## Home

[`Tickets/SAW027_activity_audit/`](Tickets/SAW027_activity_audit/)

## Deploy

**→ [`Tickets/SAW027_activity_audit/DEPLOY.md`](Tickets/SAW027_activity_audit/DEPLOY.md)**

| Item | Detail |
|------|--------|
| Host | Same as SAW025 — `3.27.207.215` |
| Plugin | `idempiere-plugins/com.aberp.activityaudit/` |
| JAR | Yes — nightly + historical processes + Open Activity + Reviewed validator |
| SQL | Ordered under `sql/` via `deploy.sh` |

### AbilityERP Admin access

| Access | Name | Search key |
|--------|------|------------|
| Window | Activity Audit Terms | — |
| Window | Activity Audit Review | — |
| Process | Activity Audit Nightly | `AbERP_ActivityAudit_Nightly` |
| Process | Historical Activity Audit | `AbERP_ActivityAudit_Historical` |
| Process | Open Activity | `AbERP_ActivityAudit_OpenActivity` |

## Scope

1. Activity Audit Terms configuration window (org-specific words/phrases, match type, risk, effective dates)
2. Nightly incremental scan of Activities updated in last 24h
3. Activity Audit Review window with outstanding queue + Reviewed workflow
4. Historical Activity Audit process (date range / new terms)
5. Process run logging; skip unchanged already-audited Activities

## External summary

**→ [`Tickets/SAW027_activity_audit/EXTERNAL-SUMMARY.md`](Tickets/SAW027_activity_audit/EXTERNAL-SUMMARY.md)**
