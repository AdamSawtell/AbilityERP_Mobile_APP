# AbilityERP ticket registry (SAW###)

Allocate the next free `SAW###` before starting work. Keep this file in sync with GitHub issues.

**Agents sidebar title:** `SAW###_<short_snake_function>`

**Kind**

| Value | Meaning | `Tickets/` folder? |
|-------|---------|-------------------|
| `idempiere` | AD / plugin / WebUI / client pack | **Yes** — `Tickets/SAW###_<slug>/` |
| `both` | ERP drop **plus** required app/API dependency | **Yes** — ERP home + `Dependencies (app)` in README |
| `app` | Mobile/web only | No — stay in app tree |
| `meta` | Process/rules/review only | No |

Status: `done` | `in-progress` | `blocked`

| ID | Slug | Kind | Description | Status | GitHub | Home |
|----|------|------|-------------|--------|--------|------|
| SAW001 | `paid_filter_invoice_send_info` | idempiere | Paid filter on Notification SR Invoice Send Info | done | [#1](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/1) | [`Tickets/SAW001_…`](../Tickets/SAW001_paid_filter_invoice_send_info/) |
| SAW002 | `ticket_ids_and_update_loop` | meta | SAW### tickets + staging client-update loop + Tickets/ layout | done | [#2](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/2) | _(no folder)_ |
| SAW003 | `staff_rostering_info` | idempiere | Staff Rostering Info Window rewrite / UX / needs-match | in-progress | [#3](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/3) | [`Tickets/SAW003_…`](../Tickets/SAW003_staff_rostering_info/) |
| SAW004 | `rostering_chat` | both | Rostering Chat WebUI and sync | done | [#4](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/4) | [`Tickets/SAW004_…`](../Tickets/SAW004_rostering_chat/) |
| SAW005 | `leave_and_credentials_fixes` | app | Leave submit, approved-leave UX icons, credentials list | done | [#5](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/5) | _(app — no folder)_ |
| SAW006 | `requests_window_clone` | idempiere | New iDempiere window cloned from Requests | in-progress | [#6](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/6) | [`Tickets/SAW006_…`](../Tickets/SAW006_requests_window_clone/) |
| SAW007 | `activity_tab_integration` | idempiere | Activity tab on multiple windows; user/contact on other builds | done | [#7](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/7) | [`Tickets/SAW007_…`](../Tickets/SAW007_activity_tab_integration/) |
| SAW008 | `build_from_scratch_review` | meta | AbilityERP build-from-scratch / no AbilityVua fork review | done | [#8](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/8) | _(no folder)_ |

## Next ID

**SAW009**

## Naming reminder

`SAW###_<short_snake_function>` — see `.cursor/rules/ticket-ids.mdc` and [`Tickets/README.md`](../Tickets/README.md).
