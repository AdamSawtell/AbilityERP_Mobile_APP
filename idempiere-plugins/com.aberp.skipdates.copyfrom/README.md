# com.aberp.skipdates.copyfrom — SAW015

OSGi process plugin: **Copy Dates From** on the **Skip Dates** window (`AbERP_Skip_Dates`).

Copies all `AbERP_Dates` lines from a selected source Skip Dates header into the current header (new IDs; source unchanged). Shows the date-review warning (process Help + result message) and reports how many lines were copied.

## Pattern

Same UX approach as Service Booking **Copy Lines** (`org.compiere.process.CopyFromOrder`): toolbar/button field + Search parameter for the source document.

## Bundle

| | |
|--|--|
| Symbolic name | `com.aberp.skipdates.copyfrom` |
| Class | `com.aberp.skipdates.copyfrom.CopyDatesFrom` |
| Version | `7.1.0.202607131830` |

## Install on host

```bash
cd /path/to/com.aberp.skipdates.copyfrom
chmod +x build.sh deploy.sh
./deploy.sh
```

Then **Cache Reset** or logout/in. Smoke as **Admin**.

## SQL only (after JAR is already installed)

```bash
psql -d idempiere -v ON_ERROR_STOP=1 \
  -f sql/00-preflight.sql \
  -f sql/01-install-copy-dates-from.sql \
  -f sql/04-verify.sql
```

## Ticket

`Tickets/SAW015_skip_dates_copy_from/`
