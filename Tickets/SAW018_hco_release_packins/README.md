# SAW018 — HCO Release Packins

| | |
|--|--|
| **Status** | in-progress (HCO Test packins applied 2026-07-13; redeploy artifacts ready) |
| **Kind** | idempiere |
| **GitHub** | [#18](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/18) |
| **Slug** | `SAW018_hco_release_packins` |
| **HCO host** | `32.236.127.117` (same as SAW010) |

## Deploy (other builds) — start here

**→ [`DEPLOY.md`](DEPLOY.md)** — agent install runbook (packin order, SQL view, stuck-import clear, smoke, packs).

## External ticket (copy/paste)

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

Install the pre-built HCO release 2Packs (client / credentials / employee / support location) onto HCO Test, capture issues/fixes, and keep artifacts ready to redeploy to another environment.

## Source of truth

| Path | Purpose |
|------|---------|
| `packins/*.zip` | 2Pack zip files (from `D:\HCO Release Packins`) |
| `sql/01-hco_cred_missing_staff_v.sql` | DB view required by credentials pack |
| `sql/00-clear-stuck-package-imp.sql` | Unblock PackIn when imports stuck in Installing |
| `hco/` | Preflight / verify outputs from HCO installs |

## Dependencies (app)

None.

## Packs

- Staging: `Downloads\AbilityERP-ClientUpdate-SAW018_hco_release_packins-20260713`
- Thin prod: `Downloads\AbilityERP-ProdUpdate-SAW018_hco_release_packins-20260713`
