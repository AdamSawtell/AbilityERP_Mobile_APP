# SAW022 — Shift search defaults to current pay period

| | |
|--|--|
| **Ticket** | `SAW022_shift_period_search_default` |
| **Kind** | idempiere |
| **Status** | done (Test `13.210.248.141` smoke PASS) |
| **JAR** | No |
| **Environment** | HCO Test `13.210.248.141` |
| **Issue** | (created with this work) |

## Goal

When **Shift (Rostered)** opens in Search/Find, pre-fill **Roster Period** with the current AbERP pay period. User can clear or pick another period.

## Package

`idempiere-plugins/com.aberp.rosteredshift.perioddefault/`

## Dependencies

None (SQL-only AD_Field DefaultValue).

## Links

- [DEPLOY.md](./DEPLOY.md)
- [EXTERNAL-SUMMARY.md](./EXTERNAL-SUMMARY.md)
- [NOTES.md](./NOTES.md)
- [CHECKLIST.md](./CHECKLIST.md)
