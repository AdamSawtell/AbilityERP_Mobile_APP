# SAW027 — Activity Audit

| | |
|--|--|
| **Status** | in-progress |
| **Kind** | idempiere |
| **GitHub** | [#27](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/27) |
| **Slug** | `SAW027_activity_audit` |
| **Dev host** | `3.27.207.215` (same as SAW025) |

## Deploy

**→ [`DEPLOY.md`](DEPLOY.md)**

## External ticket

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

Configurable org-specific Activity Audit words/phrases; nightly incremental scan of `C_ContactActivity` (Description + Comments); review queue with Open Activity zoom and Reviewed workflow; historical reprocess for new terms.

## Source of truth

| Item | Path |
|------|------|
| Plugin | `idempiere-plugins/com.aberp.activityaudit/` |
| SQL | `idempiere-plugins/com.aberp.activityaudit/sql/00`–`09` |
| Engine | `…/src/com/aberp/activityaudit/engine/ActivityAuditEngine.java` |
| JAR | `com.aberp.activityaudit_7.1.0.202607171400` |

## Access

| Access | Name | Search key |
|--------|------|------------|
| Window | Activity Audit Terms | — |
| Window | Activity Audit Review | — |
| Window | Activity Audit Runs | — |
| Process | Activity Audit Nightly | `AbERP_ActivityAudit_Nightly` |
| Process | Historical Activity Audit | `AbERP_ActivityAudit_Historical` |
| Process | Open Activity | `AbERP_ActivityAudit_OpenActivity` |
