# Activity Audit

## Windows / processes / objects affected

| Type | Name | Notes |
|------|------|--------|
| Window | Activity Audit Terms | Configurable words/phrases; Change History tab |
| Window | Activity Audit Review | Outstanding flagged Activities; mark Reviewed |
| Window | Activity Audit Runs | Nightly / historical process log |
| Window | Activity Viewer | Open Activity target; Client / Employee / Support Location links |
| Process | Activity Audit Nightly | Incremental scan (last 24 hours) + scheduler |
| Process | Historical Activity Audit | Date-range / new-term reprocess |
| Process | Open Activity | Review → Activity Viewer |
| Process | Open Client | Activity Viewer → Client window |
| Process | Open Employee | Activity Viewer → Employee window |
| Process | Open Support Location | Activity Viewer → Support Location window |

## Done

Organisations can maintain audit words and phrases. A nightly process flags Contact Activities that match, and reviewers work a queue: open the activity, decide, mark Reviewed. From Activity Viewer, Client / Employee / Support Location open the correct AbilityERP windows. The Review form is grouped so the match and the decision are easy to scan.

## What changed (behaviour)

- **Activity Audit** menu under Ability ERP (Terms, Review, Runs, Nightly, Historical)
- Terms: Exact Word / Exact Phrase / Contains; risk; category; effective dates; organisation
- Nightly incremental scan of Activities created or updated in the previous 24 hours
- One review per Activity when matches exist (multiple terms on the same review)
- **Reviewed** stamps Reviewed By / Date and clears the outstanding queue
- Review form sections: **Activity** → **Match** → **Review** → **Audit**
- Use **Review Status** for Follow-Up Required (separate Follow-Up checkbox not shown)
- Activity Viewer **Activity Links**: Client / Employee / Support Location when resolvable
- Historical process for new terms against a date range

## Impact / who is affected

Compliance / quality / operations staff who review significant events in Activities. AbilityERP Admin can configure terms and run processes after install.

## How to test

1. Log in as Admin / AbilityERP Admin
2. **Activity Audit Terms** — confirm sample terms (or add one)
3. Update an Activity Description/Comments with a configured word → Save
4. Run **Activity Audit Nightly**
5. **Activity Audit Review** — confirm the match; form shows Activity / Match / Review / Audit
6. **Open Activity** → read the source; check **Reviewed** → item leaves the outstanding list
7. Second Nightly run does not recreate the row while the Activity is unchanged
8. On Activity Viewer, use Client / Employee / Support Location when those links apply

## Access

**AbilityERP Admin** (and Admin where granted) can use Activity Audit after install and re-login / Cache Reset.

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
