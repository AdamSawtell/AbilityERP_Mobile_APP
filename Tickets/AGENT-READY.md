# Agent deploy readiness (final review)

Point agents at **`Tickets/SAW###_<slug>/DEPLOY.md`** (not chat history).

| Ticket | Slug | Agent-ready? | Notes |
|--------|------|--------------|-------|
| SAW001 | `paid_filter_invoice_send_info` | Yes (SQL) | Thin prod pack; menu tree placement verify |
| SAW002 | meta | N/A | Not an ERP install |
| SAW003 | `staff_rostering_info` | Yes | JAR `1227`; SQL `01→24→04`; unmatched credential AND; HCO E2E pass; GitHub [#3] |
| SAW004 | `rostering_chat` | Yes with caveat | Must confirm Rostering Officer id vs `1000012`; use exact SQL list |
| SAW005 | app | N/A | App deploy |
| SAW006 | merged → SAW004 | Use SAW004 | |
| SAW007 | `activity_tab_integration` | Yes (portable default) | `deploy.sh` now portable; never seed SQL on other builds |
| SAW008 | meta | N/A | |
| SAW009 | `support_day_pattern_number` | Yes | `deploy.sh` / `DEPLOY.md`; never overwrite existing column/field UUs |
| SAW010 | `timesheet_approval_info_columns` | Yes (columns) | Approve process JAR separate |
| SAW011 | `accept_shift_request` | Yes with caveat | Confirm Published `R_Status_ID`; packs created; use install SQL only |
| SAW012 | `session_process_audit_perf` | Partial | Large-table indexes/purge — follow DEPLOY + maintenance window |
| SAW013 | `shift_change_form_enhancements` | Yes (SQL) | No JAR; ordered `00→01→02→03→05→04`; Cache Reset; Logilite CreateRequestFromTemplate is prerequisite; packs `*20260713*` |
| SAW014 | `support_location_contact_grid` | Yes (SQL) | AD ColumnSQL only; Cache Reset; no JAR/restart; packs `*20260713*` |
| SAW015 | `skip_dates_copy_from` | Yes (JAR+SQL) | `deploy.sh` or pack HOW-TO; stop/start; Cache Reset; Admin process access |

Each installable folder has: `README`, `DEPLOY`, `EXTERNAL-SUMMARY`, `NOTES`, `CHECKLIST`.
