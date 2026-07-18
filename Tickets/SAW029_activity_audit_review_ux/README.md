# SAW029 — Activity Audit Review UX

| | |
|--|--|
| **Status** | done |
| **Kind** | idempiere |
| **GitHub** | [#29](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/29) |
| **Slug** | `SAW029_activity_audit_review_ux` |
| **Dev host** | `3.27.207.215` |
| **Packs** | `AbilityERP-*-SAW029_activity_audit_review_ux-20260718` |

## Deploy (agents)

**→ [`DEPLOY.md`](DEPLOY.md)** — preflight → apply `18-review-field-groups.sql` → verify → Cache Reset → smoke.

Helpers: [`sql/00-preflight.sql`](sql/00-preflight.sql), [`sql/95-verify.sql`](sql/95-verify.sql), [`sql/99-rollback.sql`](sql/99-rollback.sql).

## External ticket

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

Tidy **Activity Audit Review** form with collapsible field groups: **Activity** → **Match** → **Review** → **Audit**. Place **Active** in Audit; hide redundant Follow-Up checkbox.

## Source of truth

| Item | Path |
|------|------|
| Plugin | `idempiere-plugins/com.aberp.activityaudit/` |
| SQL | `…/sql/18-review-field-groups.sql` |
| JAR | No — AD/SQL only |
| Prerequisite | SAW027 Activity Audit Review window + Audit field group |

## Overlap

Extends SAW027 Activity Audit Review window AD. Does not change engine/JAR logic. Independent of SAW028 (Activity Viewer links).

## Access

| Access | Name | Search key |
|--------|------|------------|
| Window | Activity Audit Review | — |
| Process | Open Activity | `AbERP_ActivityAudit_OpenActivity` |
