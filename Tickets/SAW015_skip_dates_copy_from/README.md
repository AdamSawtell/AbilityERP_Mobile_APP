# SAW015 — Skip Dates: Copy Dates From

| | |
|--|--|
| **Status** | in-progress (HCO Test installed + WebUI smoke pass; UAT ready) |
| **Kind** | idempiere |
| **GitHub** | [#15](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/15) |
| **Slug** | `SAW015_skip_dates_copy_from` |
| **HCO host** | `32.236.127.117` (same as SAW012) |

## Deploy (other builds)

**→ [`DEPLOY.md`](DEPLOY.md)** — JAR + SQL; Admin process access; stop/start iDempiere; Cache Reset.

## External ticket (copy/paste)

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

On **Skip Dates** (`AbERP_Skip_Dates`), **Copy Dates From** copies all `AbERP_Dates` lines from a selected source header into the current header — with a date-review warning and a copy count. Same UX approach as Service Booking **Copy Lines**.

## Source of truth

- Plugin: `idempiere-plugins/com.aberp.skipdates.copyfrom/`
- Class: `com.aberp.skipdates.copyfrom.CopyDatesFrom`
- AD: `sql/01-install-copy-dates-from.sql`

## Dependencies (app)

None.

## Packs

- `AbilityERP-ClientUpdate-SAW015_skip_dates_copy_from-20260713`
- Thin prod: `AbilityERP-ProdUpdate-SAW015_skip_dates_copy_from-20260713`
