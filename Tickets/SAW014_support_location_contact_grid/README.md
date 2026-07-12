# SAW014 — Support Location contact grid columns

| | |
|--|--|
| **Status** | done |
| **Kind** | idempiere |
| **GitHub** | [#14](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/14) |
| **Slug** | `SAW014_support_location_contact_grid` |

## Deploy (other builds)

**→ [`DEPLOY.md`](DEPLOY.md)** — SQL-only; Cache Reset; no JAR.

## External ticket (copy/paste)

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

In **Support Location** Grid View, **Email**, **Phone**, and **Phone 2** must show for every row on load — not only after selecting a record.

## Root cause

`AbERP_Email` / `AbERP_Phone` / `AbERP_Phone2` used `@SQL=` virtual columns. In iDempiere 7 those are evaluated only for the current/selected row in Grid View.

## Fix

Replace `@SQL=` with correlated subquery `ColumnSQL` reading live from `C_BPartner_Location` (same pattern as existing `AbERP_Location_Address`). Also converted `AbERP_LocationName` and `AbERP_Location_IsActive` (same defect). No data duplication; no new physical columns.

## Source of truth

- `Tickets/SAW014_support_location_contact_grid/sql/`

## Dependencies (app)

None.

## Packs

- `AbilityERP-ClientUpdate-SAW014_support_location_contact_grid-<YYYYMMDD>`
- Thin prod: `AbilityERP-ProdUpdate-SAW014_support_location_contact_grid-<YYYYMMDD>`
