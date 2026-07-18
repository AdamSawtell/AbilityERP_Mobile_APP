# Activity Audit Review — clearer form layout

## Windows / processes / objects affected

| Type | Name | Notes |
|------|------|--------|
| Window | Activity Audit Review | Form field groups and field order only |
| Field groups | Activity, Match, Review | New AbERP collapsible groups |
| Field group | Audit | Existing AbERP group (collapsed); now holds Active |
| Process | Open Activity | Unchanged; still on the form (`AbERP_ActivityAudit_OpenActivity`) |

## Done

The Activity Audit Review form is reorganised into clear sections so reviewers can work faster.

## What changed

Fields are grouped:

- **Activity** — date, client, employee, activity type, and **Open Activity**
- **Match** — matched terms, category, risk level, and the matched text extract
- **Review** — status, **Reviewed** (completes the item), reviewer, dates, notes
- **Audit** — Active + system timestamps (collapsed by default)

Use **Review Status** for outcomes such as Follow-Up Required. The separate Follow-Up checkbox is hidden (it duplicated status).

No change to how activities are scanned or which rows appear in the queue.

## Impact

Easier to scan a review: see what was flagged, why, then record the decision.

## How to test

1. Open **Activity Audit Review**
2. Open any review in form view (toggle off grid if needed)
3. Confirm the four groups; expand **Audit** and check **Active** sits with **Activity Updated Audited**
4. Confirm there is no separate Follow-Up Required checkbox
5. Confirm **Open Activity** still opens the source activity

## Access

AbilityERP Admin (and Admin where granted) keep window access from the Activity Audit install. No new role grants are required for this layout change.

| Access | Name | Search key |
|--------|------|------------|
| Window | Activity Audit Review | — |
| Process | Open Activity | `AbERP_ActivityAudit_OpenActivity` |
