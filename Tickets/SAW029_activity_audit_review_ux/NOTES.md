# SAW029 — Notes

## Field groups (UU)

| Group | UU | Collapsed default |
|-------|----|-------------------|
| Activity | `29a029fg-0001-4f01-8e15-000000000001` | N |
| Match | `29a029fg-0002-4f01-8e15-000000000001` | N |
| Review | `29a029fg-0003-4f01-8e15-000000000001` | N |
| Audit | `3551f0df-bb72-40ab-8b1c-c28a7fec9a46` | Y (owned by SAW027) |

## Form flow

Activity Date + Open Activity → Client / Employee / Type → Match terms / category / risk / extract → Review decision fields → Audit.

## Review flags vs Review Status

| Field | Keep on form? | Why |
|-------|---------------|-----|
| Review Status | Yes | Primary outcome (New / Under Review / Follow-Up Required / …) |
| Reviewed | Yes | One-click complete: stamps Reviewed By/Date, sets status to NF when New/Under Review, clears outstanding queue (`IsReviewed='N'` filter) |
| Follow-Up Required | No (hidden) | Duplicate of Review Status = **Follow-Up Required** (`FU`) — not used by engine |
| Active | Audit group | Same line as Activity Updated Audited; still on tab so WebUI edit context works |

## Staging smoke (2026-07-18 · `3.27.207.215`)

- Groups Activity / Match / Review / Audit present
- Audit expanded: **Active** same line as **Activity Updated Audited**
- Follow-Up Required checkbox absent on form
- Open Activity remains in Activity group
- Commits: `3a51fba` (groups), `37f0a52` (Active/Follow-Up), docs/packs follow-up

## HCO Future Deployments variables

| Variable | Value |
|----------|--------|
| Window UU | `27a02750-c0d4-4f01-8e15-000000000001` |
| Tab UU | `27a02751-c0d4-4f01-8e15-000000000001` |
| FG Activity | `29a029fg-0001-4f01-8e15-000000000001` |
| FG Match | `29a029fg-0002-4f01-8e15-000000000001` |
| FG Review | `29a029fg-0003-4f01-8e15-000000000001` |
| FG Audit (existing) | `3551f0df-bb72-40ab-8b1c-c28a7fec9a46` |
| Apply SQL | `idempiere-plugins/com.aberp.activityaudit/sql/18-review-field-groups.sql` |
| JAR | None |
| Prerequisite | SAW027 installed (window + Audit FG) |

**Never change existing HCO `*_UU` values.** Only INSERT new field groups with the fixed UUs above when missing.

## Packs

- `Downloads\AbilityERP-ClientUpdate-SAW029_activity_audit_review_ux-20260718\`
- `Downloads\AbilityERP-ProdUpdate-SAW029_activity_audit_review_ux-20260718\`
