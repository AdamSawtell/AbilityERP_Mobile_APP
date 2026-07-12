# SAW009 — Display service pattern day number on Service Booking Lines

| | |
|--|--|
| **Status** | done |
| **Kind** | idempiere |
| **GitHub** | [#9](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/9) |
| **Slug** | `support_day_pattern_number` |

## Deploy (other builds)

**→ [`DEPLOY.md`](DEPLOY.md)** — SQL-only; prefer thin prod pack when present.

## Goal

Make `C_OrderLine.AbERP_Support_Start_Day` and `AbERP_Support_End_Day` on Service Booking Line display the numbered service-pattern day format already used by Booking Generator – Service Pattern Line (`AbERP_ServicePattern`), e.g. `01 - Monday` / `08 - Monday`.

## Source of truth

- `idempiere-plugins/com.aberp.servicebooking.supportdays/`
- Discovery: `scripts/db-discovery-support-days*.sql`

## Dependencies (app)

None — WebUI / Application Dictionary only.

## Packs

- Staging: `Downloads\AbilityERP-ClientUpdate-SAW009_support_day_pattern_number-*`
- Prod: `Downloads\AbilityERP-ProdUpdate-SAW009_support_day_pattern_number-*`
