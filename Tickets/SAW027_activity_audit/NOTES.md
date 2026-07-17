# SAW027 — Notes

## Environment

Same as SAW025: `3.27.207.215` (Audit Tool Build V1 / HCO Test clone).

## Design decisions

- Source table is **`C_ContactActivity`** (Contact Activity tabs). There is no Subject column — scan **Description** + **Comments**.
- Incremental state in `AbERP_ActivityAuditProc` keyed by Activity ID + audited `Updated` timestamp.
- Term table has AD Change Log enabled (`IsChangeLog=Y`). Child **Change History** tab is available for optional custom trail rows.
- Org `0` terms apply to all orgs on the client; org-specific terms apply only to that org.
- New terms do not force a full historical scan; use **Historical Activity Audit**.

## HCO Future Deployments variables

(none yet — not installed on production HCO)

| Variable | Value |
|----------|--------|
| Dev host | `3.27.207.215` |
| Plugin version | `7.1.0.202607171000` |
| Scheduler UU | `27a02790-c0d4-4f01-8e15-000000000001` |

## Smoke results

- **2026-07-17** on `3.27.207.215` (HCO client):
  - Bundle `com.aberp.activityaudit_7.1.0.202607171400` ACTIVE
  - Seeded 11 terms on AbilityERP + HCO
  - Updated Activity `1641177` with Exact Word `fall`
  - Ran **Activity Audit Nightly** → `identified=1 processed=1 created=1 errors=0`
  - Review row: MatchedTerms=`Fall`, ReviewStatus=`NW`
- JAR: `com.aberp.activityaudit_7.1.0.202607171400`
