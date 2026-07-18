# SAW029 — Activity Audit Review UX

| | |
|--|--|
| **Status** | done |
| **Kind** | idempiere |
| **GitHub** | [#29](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/29) |
| **Slug** | `SAW029_activity_audit_review_ux` |
| **Dev host** | `3.27.207.215` |

## Deploy

**→ [`DEPLOY.md`](DEPLOY.md)**

## External ticket

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

Tidy **Activity Audit Review** form with collapsible field groups so reviewers see a clear flow: **Activity** → **Match** → **Review** → **Audit**.

## Source of truth

| Item | Path |
|------|------|
| Plugin | `idempiere-plugins/com.aberp.activityaudit/` |
| SQL | `…/sql/18-review-field-groups.sql` |
| JAR | No — AD/SQL only |

## Overlap

Extends SAW027 Activity Audit Review window AD. Does not change engine/JAR logic.

## Access

| Access | Name | Search key |
|--------|------|------------|
| Window | Activity Audit Review | — |
