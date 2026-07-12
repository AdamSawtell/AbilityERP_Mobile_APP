# AbilityERP ticket registry (SAW###)

Allocate the next free `SAW###` before starting work. Keep this file in sync with GitHub issues.

Status: `done` | `in-progress` | `blocked`

| ID | Slug | Description | Status | GitHub | Notes / commits |
|----|------|-------------|--------|--------|-----------------|
| SAW001 | `paid_filter_invoice_send_info` | Paid (Yes/No/blank) search on Notification SR Invoice Send Info; UUID-safe SQL + client update pack | done | [#1](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/1) | `f9bc500`, `5e1dfab`, `501c3f2`; pack `Downloads\…SAW001_…` |
| SAW002 | `client_update_staging_loop` | Adopted staging install→review→fix loop + Downloads/prod pack rules + UUID portability | done | [#2](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/2) | `2509564`, `5ca275b`, `501c3f2` |
| SAW003 | `staff_rostering_info` | Staff Rostering Info Window rewrite, UX, leave/shift filters, needs-match | in-progress | [#3](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/3) | Base: `d0a38d1`…`68904b1`, `289e8a1`. **Another agent may be editing staffinfo — do not collide** |
| SAW004 | `rostering_chat` | Rostering Chat WebUI/API: reply, close, sync, layout, officer create | done | [#4](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/4) | `7dd5b5d`…`e41e267` |
| SAW005 | `leave_and_credentials_fixes` | Leave submit status codes; credentials list via user contact; leave UX | done | [#5](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/5) | `bfe6137`, `668663e`, `6740275` |

## Next ID

**SAW006**

## Naming reminder

`SAW###_<short_snake_function>` — see `.cursor/rules/ticket-ids.mdc`.
