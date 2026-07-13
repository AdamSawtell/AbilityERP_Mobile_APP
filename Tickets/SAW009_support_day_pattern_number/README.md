# SAW009 — Display service pattern day number on Service Booking Lines

| | |
|--|--|
| **Status** | done |
| **Kind** | idempiere |
| **GitHub** | [#9](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/9) |
| **Slug** | `SAW009_support_day_pattern_number` |

## Deploy (other builds)

**→ [`DEPLOY.md`](DEPLOY.md)** — required reading for any agent installing this ticket on another build.

```bash
cd idempiere-plugins/com.aberp.servicebooking.supportdays
chmod +x deploy.sh && sudo ./deploy.sh
# Cache Reset / logout-in. No iDempiere restart.
```

## External ticket (copy/paste)

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)** — paste into the customer/external ticket (not for agents).

## Goal

Make `C_OrderLine.AbERP_Support_Start_Day` and `AbERP_Support_End_Day` on Service Booking Line display the numbered service-pattern day format already used by Booking Generator – Service Pattern Line (`AbERP_ServicePattern`), e.g. `02 - Monday` / `09 - Monday`.

## Source of truth

- Plugin/SQL: `idempiere-plugins/com.aberp.servicebooking.supportdays/`
- Agent install: this folder’s `DEPLOY.md`
- HCO variables: `NOTES.md`

## Dependencies (app)

None — WebUI / Application Dictionary only.

## Packs

- Staging: `Downloads\AbilityERP-ClientUpdate-SAW009_support_day_pattern_number-20260713`
- Prod: `Downloads\AbilityERP-ProdUpdate-SAW009_support_day_pattern_number-20260713`
