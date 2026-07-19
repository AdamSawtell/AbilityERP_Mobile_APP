# SAW027 — Activity Audit

| | |
|--|--|
| **Status** | in-progress |
| **Kind** | idempiere |
| **GitHub** | [#27](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/27) |
| **Slug** | `SAW027_activity_audit` |
| **Dev host** | `3.27.207.215` |
| **Includes** | Formerly tracked as SAW028 (viewer links) + SAW029 (review UX) — **one function** |

## Deploy

**→ [`DEPLOY.md`](DEPLOY.md)**

## External ticket

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

One Activity Audit product: configurable terms → nightly/historical scan of Contact Activities → review queue with Open Activity → mark Reviewed; Activity Viewer Client / Employee / Support Location links; Review form grouped Activity → Match → Review → Audit.

## Source of truth

| Item | Path |
|------|------|
| Plugin | `idempiere-plugins/com.aberp.activityaudit/` |
| SQL | `…/sql/00`–`18` (via `deploy.sh`) |
| Engine | `…/engine/ActivityAuditEngine.java` |
| JAR | `com.aberp.activityaudit_7.1.0.202607180900` |

## Related IDs (merged)

| ID | Was | Now |
|----|-----|-----|
| SAW028 | Activity Viewer links | Part of this ticket — see DEPLOY / EXTERNAL-SUMMARY |
| SAW029 | Review field groups UX | Part of this ticket — see DEPLOY / EXTERNAL-SUMMARY |

Stub folders remain for history: `Tickets/SAW028_…`, `Tickets/SAW029_…` → point here.

## Access

| Access | Name | Search key |
|--------|------|------------|
| Window | Activity Audit Terms | — |
| Window | Activity Audit Review | — |
| Window | Activity Audit Runs | — |
| Window | Activity Viewer | — |
| Process | Activity Audit Nightly | `AbERP_ActivityAudit_Nightly` |
| Process | Historical Activity Audit | `AbERP_ActivityAudit_Historical` |
| Process | Open Activity | `AbERP_ActivityAudit_OpenActivity` |
| Process | Open Client | `AbERP_ActivityViewer_OpenClient` |
| Process | Open Employee | `AbERP_ActivityViewer_OpenEmployee` |
| Process | Open Support Location | `AbERP_ActivityViewer_OpenSupportLocation` |
