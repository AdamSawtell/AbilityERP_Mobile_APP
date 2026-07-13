# AbilityERP ticket registry (SAW###)

Allocate the next free `SAW###` before starting work. Keep this file in sync with GitHub issues.

**Agents sidebar title:** `SAW###_<short_snake_function>`

**Deploy handoff (vital):** for Kind `idempiere` / `both`, `Tickets/SAW###_…/DEPLOY.md` + the GitHub issue **Deploy** section must be enough for a new agent to install on another build from this repo alone.

**External ticket handoff (vital):** `Tickets/SAW###_…/EXTERNAL-SUMMARY.md` — copy/paste for the customer ticket (done / changed / impact / test / Admin access). See also `docs/DEV-REQUIREMENTS.md` (AbilityERP Admin must get window/process/Info/form access).

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
| SAW003 | `staff_rostering_info` | idempiere | Staff Rostering Info Window rewrite / UX / needs-match / unmatched credential AND | done | [#3](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/3) | [`Tickets/SAW003_…`](../Tickets/SAW003_staff_rostering_info/) |
| SAW004 | `rostering_chat` | both | Rostering Chat WebUI and sync (Requests-window clone) | done | [#4](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/4) | [`Tickets/SAW004_…`](../Tickets/SAW004_rostering_chat/) |
| SAW005 | `leave_and_credentials_fixes` | app | Leave submit, approved-leave UX icons, credentials list | done | [#5](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/5) | _(app — no folder)_ |
| SAW006 | `requests_window_clone` | — | Merged into SAW004 (Requests clone = Rostering Chat) | done | [#6](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/6) | [`Tickets/SAW004_rostering_chat`](../Tickets/SAW004_rostering_chat/) |
| SAW007 | `activity_tab_integration` | idempiere | Activity tab on multiple windows; user/contact on other builds | done | [#7](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/7) | [`Tickets/SAW007_…`](../Tickets/SAW007_activity_tab_integration/) |
| SAW008 | `build_from_scratch_review` | meta | AbilityERP build-from-scratch / no AbilityVua fork review | done | [#8](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/8) | _(no folder)_ |
| SAW009 | `support_day_pattern_number` | idempiere | Service Booking Line Support Start/End Day show pattern day number | done | [#9](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/9) | [`Tickets/SAW009_…`](../Tickets/SAW009_support_day_pattern_number/) |
| SAW010 | `timesheet_approval_info_columns` | idempiere | Timesheet Approval Info: hide unused cols, dedupe staff, add Break Start/End | done | [#10](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/10) | [`Tickets/SAW010_…`](../Tickets/SAW010_timesheet_approval_info_columns/) |
| SAW011 | `accept_shift_request` | idempiere | Accept Shift Request: Response Log REQ → Employee tab assign | done | [#11](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/11) | [`Tickets/SAW011_…`](../Tickets/SAW011_accept_shift_request/) |
| SAW012 | `session_process_audit_perf` | idempiere | Session/Process Audit usable on huge tables (High Volume, indexes, retention) | in-progress | [#12](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/12) | [`Tickets/SAW012_…`](../Tickets/SAW012_session_process_audit_perf/) |
| SAW013 | `shift_change_form_enhancements` | idempiere | HCO Forms: auto Request Status + prevent duplicate Create + match template type | done | [#13](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/13) | [`Tickets/SAW013_…`](../Tickets/SAW013_shift_change_form_enhancements/) |
| SAW014 | `support_location_contact_grid` | idempiere | Support Location Email/Phone grid: replace @SQL= with subquery ColumnSQL | done | [#14](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/14) | [`Tickets/SAW014_…`](../Tickets/SAW014_support_location_contact_grid/) |
| SAW015 | `skip_dates_copy_from` | idempiere | Skip Dates: Copy Dates From existing record (AbERP_Dates) | in-progress | [#15](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/15) | [`Tickets/SAW015_…`](../Tickets/SAW015_skip_dates_copy_from/) |
| SAW016 | `leave_planning` | idempiere | Leave Planning window for workforce planners | in-progress | [#16](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/16) | [`Tickets/SAW016_…`](../Tickets/SAW016_leave_planning/) |
| SAW017 | `booking_generator_bulk` | idempiere | Booking Generator → Service Bookings bulk/block generation | in-progress (HCO E2E PASS; packs ready) | [#17](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/17) | [`Tickets/SAW017_…`](../Tickets/SAW017_booking_generator_bulk/) |
| SAW018 | `hco_release_packins` | idempiere | HCO release 2Packs (credentials/employee/client/support location) + missing-staff view | in-progress | [#18](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/18) | [`Tickets/SAW018_…`](../Tickets/SAW018_hco_release_packins/) |

## Next ID

**SAW019**

## Naming reminder

`SAW###_<short_snake_function>` — see `.cursor/rules/ticket-ids.mdc` and [`Tickets/README.md`](../Tickets/README.md).
