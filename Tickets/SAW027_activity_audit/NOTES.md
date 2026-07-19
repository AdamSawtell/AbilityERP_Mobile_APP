# SAW027 — Notes

## One function

Activity Audit is a **single** product under this ticket. Work formerly split as SAW028 (viewer links) and SAW029 (review UX) is included in plugin SQL `16`–`21` and JAR `7.1.0.202607191400`. Deploy / packs / external summary live here only.

## Environment

`3.27.207.215` (Audit Tool Build / HCO Test clone).

## Design decisions

- Source table **`C_ContactActivity`** — scan **Description** + **Comments** (no Subject).
- Incremental state in `AbERP_ActivityAuditProc` (Activity ID + audited `Updated`).
- Org `0` terms apply client-wide; org-specific terms apply to that org only.
- New terms → use **Historical Activity Audit**, not a forced full nightly rewind.
- **Reviewed** checkbox drives queue completion; Follow-Up checkbox hidden (use Review Status).
- Viewer zooms only named AbilityERP windows (Client / Employee / Support Location), not BP/User.

## HCO Future Deployments variables

| Variable | Value |
|----------|--------|
| Dev host | `3.27.207.215` |
| Plugin JAR | `com.aberp.activityaudit_7.1.0.202607191400` |
| Scheduler UU | `27a02790-c0d4-4f01-8e15-000000000001` |
| Window Review UU | `27a02750-c0d4-4f01-8e15-000000000001` |
| Tab Reviews UU | `27a02751-c0d4-4f01-8e15-000000000001` |
| FG Activity / Match / Review | `29a029fg-0001…` / `0002…` / `0003…` |
| FG Audit | `3551f0df-bb72-40ab-8b1c-c28a7fec9a46` |
| Production HCO | Not installed yet — never change existing HCO `*_UU` |

## Smoke results

### Core (2026-07-17)

- Bundle ACTIVE; 11 seed terms
- Activity `1641177` + Exact Word `fall` → Nightly `created=1`
- Review: MatchedTerms=`Fall`, ReviewStatus=`NW`

### Viewer links (2026-07-18, ex-SAW028)

Full show/hide + zoom matrix PASS: `1638777`, `1641172`, `1617870`, `1641170`, `1374218`.

### Review UX (2026-07-18, ex-SAW029)

Form groups Activity / Match / Review / Audit; Active with Activity Updated Audited; Follow-Up checkbox hidden; Open Activity in Activity group.

### E2E complete (2026-07-19) — PASS

| Step | Evidence |
|------|----------|
| Open Activity | Activity Viewer on `1638777` (Ambulance / review path) |
| Reviewed stamp | WebUI: IsReviewed=Y → Reviewed By SuperUser, Reviewed Date, ReviewStatus=`NF` (trigger `aberp_activityauditreview_stamp_reviewed`) |
| Nightly no-dup | Process summary `identified=1 skipped=1 processed=0 created=0`; `review_cnt=1` for activity `1638777`; runt `2026-07-19 18:57:43` |

Packs: `AbilityERP-ClientUpdate-SAW027_activity_audit-20260719`, `AbilityERP-ProdUpdate-SAW027_activity_audit-20260719`.
