# Activity Audit — external summary

## Windows / processes / objects affected

| Object | Type | Notes |
|--------|------|--------|
| Activity Audit Terms | Window | Maintain org-specific audit words/phrases |
| Change History | Tab | Term change history (plus AD change log) |
| Activity Audit Review | Window | Outstanding flagged Activities; mark Reviewed |
| Activity Audit Runs | Window | Nightly / historical process log |
| Activity Audit Nightly | Process + scheduler | Scans Activities updated in last 24 hours |
| Historical Activity Audit | Process | Date-range / new-term reprocess |
| Open Activity | Process / button | Zoom to original Contact Activity |

## What’s done

Organisations can maintain their own list of audit words and phrases (for example Hospital, Ambulance, Fall, Medication error). A nightly process reviews recently updated Activities and creates a review item when a configured term is found. Reviewers open the original Activity, assess it, and mark it Reviewed. Unchanged Activities are not flagged again.

## What changed (behaviour)

- New **Activity Audit** menu under Ability ERP
- Terms are configurable without deployment (Exact Word / Exact Phrase / Contains; risk; category; effective dates; organisation)
- Nightly incremental scan of Activities created or updated in the previous 24 hours
- One review record per Activity when matches exist (multiple terms on the same review)
- Reviewed checkbox stamps Reviewed By / Date and moves the item out of the outstanding queue
- Historical process available for checking new terms against a selected date range

## Impact / who is affected

Compliance / quality / operations staff who review significant events in Activities. AbilityERP Admin can configure terms and run processes after install.

## How to test

1. Log in as Admin / AbilityERP Admin
2. Open **Activity Audit Terms** and confirm sample terms (or add `ambulance`)
3. Update an Activity so Description or Comments includes a configured word
4. Run **Activity Audit Nightly**
5. Open **Activity Audit Review**, confirm the match, use **Open Activity**, then check **Reviewed**
6. Confirm the item leaves the outstanding list and that a second nightly run does not recreate it while the Activity is unchanged

## Access

**AbilityERP Admin** (and Admin) can use Activity Audit after install and re-login / Cache Reset.

| Access | Name | Search key |
|--------|------|------------|
| Window | Activity Audit Terms | — |
| Window | Activity Audit Review | — |
| Window | Activity Audit Runs | — |
| Process | Activity Audit Nightly | `AbERP_ActivityAudit_Nightly` |
| Process | Historical Activity Audit | `AbERP_ActivityAudit_Historical` |
| Process | Open Activity | `AbERP_ActivityAudit_OpenActivity` |
