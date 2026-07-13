# Agent deploy readiness (final review)

Point agents at **`Tickets/SAW###_<slug>/DEPLOY.md`** (not chat history).

| Ticket | Slug | Agent-ready? | Notes |
|--------|------|--------------|-------|
| SAW001 | `paid_filter_invoice_send_info` | Yes (SQL) | Thin prod pack; menu tree placement verify |
| SAW002 | meta | N/A | Not an ERP install |
| SAW003 | `staff_rostering_info` | Yes | Related Info ID risk called out; packs present |
| SAW004 | `rostering_chat` | Yes with caveat | Must confirm Rostering Officer id vs `1000012`; use exact SQL list |
| SAW005 | app | N/A | App deploy |
| SAW006 | merged → SAW004 | Use SAW004 | |
| SAW007 | `activity_tab_integration` | Yes (portable default) | `deploy.sh` now portable; never seed SQL on other builds |
| SAW008 | meta | N/A | |
| SAW009 | `support_day_pattern_number` | Yes | Prefer `sql/run-install.sh` or packs |
| SAW010 | `timesheet_approval_info_columns` | Yes (columns) | Approve process JAR separate |
| SAW011 | `accept_shift_request` | Yes with caveat | Confirm Published `R_Status_ID`; packs created; use install SQL only |
| SAW012 | `session_process_audit_perf` | Partial | Large-table indexes/purge — follow DEPLOY + maintenance window |
| SAW013 | `shift_change_form_enhancements` | Yes | See ticket DEPLOY |
| SAW014 | `support_location_contact_grid` | Yes (SQL) | AD ColumnSQL only; Cache Reset; no JAR/restart; packs `*20260713*` |

Each installable folder has: `README`, `DEPLOY`, `EXTERNAL-SUMMARY`, `NOTES`, `CHECKLIST`.
