# SAW007 ? Activity tab integration

| | |
|--|--|
| **Status** | done |
| **Kind** | idempiere |
| **GitHub** | [#7](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/7) |
| **Slug** | `SAW007_activity_tab_integration` |

## Deploy (other builds)

**? [`DEPLOY.md`](DEPLOY.md)** ? use portable `register-contactactivity-tabs.sql` on other builds (not seed window IDs alone).

## External ticket (copy/paste)

**? [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)** ? paste into the customer/external ticket (not for agents).

## Goal

Activity tab on multiple windows; user/contact wiring on other builds as needed.

## Source of truth

- `idempiere-plugins/com.aberp.contactactivity.tabs/`
- Related SQL under that package / install docs

## Dependencies (app)

None unless a client build requires matching app behaviour ? note here if so.

## Packs

- `AbilityERP-*-SAW007_activity_tab_integration-*`
