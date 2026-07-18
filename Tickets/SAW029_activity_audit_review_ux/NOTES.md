# SAW029 — Notes

## Field groups (UU)

| Group | UU | Collapsed default |
|-------|----|-------------------|
| Activity | `29a029fg-0001-4f01-8e15-000000000001` | N |
| Match | `29a029fg-0002-4f01-8e15-000000000001` | N |
| Review | `29a029fg-0003-4f01-8e15-000000000001` | N |
| Audit | `3551f0df-bb72-40ab-8b1c-c28a7fec9a46` | Y |

## Form flow

Activity Date + Open Activity → Client / Employee / Type → Match terms / category / risk / extract → Review decision fields → Audit.

## Review flags vs Review Status

| Field | Keep on form? | Why |
|-------|---------------|-----|
| Review Status | Yes | Primary outcome (New / Under Review / Follow-Up Required / …) |
| Reviewed | Yes | One-click complete: stamps Reviewed By/Date, sets status to NF when New/Under Review, clears outstanding queue (`IsReviewed='N'` filter) |
| Follow-Up Required | No (hidden) | Duplicate of Review Status = **Follow-Up Required** (`FU`) — not used by engine |
| Active | Audit group | Same line as Activity Updated Audited; still on tab so WebUI edit context works |

## HCO Future Deployments variables

- Window UU: `27a02750-c0d4-4f01-8e15-000000000001`
- Tab UU: `27a02751-c0d4-4f01-8e15-000000000001`
- Never change existing HCO `*_UU` values; only INSERT new field groups with fixed UUs above
