# com.aberp.skipdates.copyfrom — SAW015

OSGi process plugin: **Copy Dates From** on the **Skip Dates** window (`AbERP_Skip_Dates`).

Copies all `AbERP_Dates` lines from a selected source Skip Dates header into the current header (new IDs; source unchanged). Shows the date-review warning (process Help + result message) and reports how many lines were copied.

## Agent install (other builds)

**→ [`Tickets/SAW015_skip_dates_copy_from/DEPLOY.md`](../../Tickets/SAW015_skip_dates_copy_from/DEPLOY.md)**

```bash
cd idempiere-plugins/com.aberp.skipdates.copyfrom
chmod +x build.sh deploy.sh
./deploy.sh
# Cache Reset / logout-in; smoke as Admin
```

## Pattern

Same UX approach as Service Booking **Copy Lines** (`org.compiere.process.CopyFromOrder`): button field + Search parameter for the source document.

## Bundle

| | |
|--|--|
| Symbolic name | `com.aberp.skipdates.copyfrom` |
| Class | `com.aberp.skipdates.copyfrom.CopyDatesFrom` |
| Version | `7.1.0.202607131830` |

## SQL order

`sql/00-preflight.sql` → `01-install-copy-dates-from.sql` → `02-button-window-style.sql` → `04-verify.sql`

## Ticket

`Tickets/SAW015_skip_dates_copy_from/`
