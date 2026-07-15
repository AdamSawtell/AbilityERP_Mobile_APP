# SAW022 — Notes

## Design

Find/Lookup on this build **does not apply** `AD_Field.DefaultValue` for virtual `AbERP_PR_Period_ID` (verified with literal period id still blank in Lookup Record).

**Ship approach:** shared `AD_UserQuery` `* Current Pay Period` (`ad_userquery_uu` `6b2c9e11-4d8a-4f01-9b2e-a022shift001`) with `IsDefault=Y` and dynamic `@SQL=EXISTS (... AbERP_PR_Period ... LOCALTIMESTAMP ...)`.

- Clears via `** New Query **` or any other saved query (locations etc. still work).
- Field DefaultValue still set with `AS DefaultValue` for best-effort New/Find on other builds.

## Install log

- 2026-07-15: Applied on `13.210.248.141` (Test). Logout/in. Smoke: Saved Query `* Current Pay Period` selected; OK → **1/2797** rows.

## HCO Future Deployments variables

| Variable | Value on 13.210.248.141 (Test) |
|----------|--------------------------------|
| Window UU | `7c269a7e-65dd-4287-8d53-f7f3ca09ee00` |
| Tab UU | `29867696-9561-462f-89f9-f92c26c8ea02` |
| Field UU Roster Period | `9099644b-d5cf-4b32-9921-1776cac6bd66` |
| UserQuery UU | `6b2c9e11-4d8a-4f01-9b2e-a022shift001` |
| Local field_id (hint only) | 1005884 |
| Smoke role | Admin (SuperUser) |
| Never change | Existing `*_UU` values |
