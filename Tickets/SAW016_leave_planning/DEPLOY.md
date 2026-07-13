# SAW016 — Deploy (agent)

**Kind:** idempiere · **JAR:** No · **Host:** HCO Test / client clone with `psql` + WebUI Admin

## One-liner

```bash
cd idempiere-plugins/com.aberp.leave.planning/sql
# optional: bump AD_* sequences if nextid collides (see Tickets/.../sql/00-bump-sequences.sql)
psql -d idempiere -U adempiere -v ON_ERROR_STOP=1 \
  -f 00-preflight.sql \
  -f 01-create-table.sql \
  -f 08-summary-functions.sql \
  -f 02-ad-table-columns.sql \
  -f 03-leave-virtual-columns.sql \
  -f 04-window-tabs-fields.sql \
  -f 09-planning-line.sql \
  -f 10-ad-planning-line.sql \
  -f 05-menu-access.sql \
  -f 06-report.sql \
  -f 07-verify.sql
# WebUI: Cache Reset → logout/in → open Leave Planning
```

Rollback: `99-rollback.sql` (extend for line table/functions as needed).

## AbilityERP Admin access

Window **Leave Planning** + process **Leave Planning Report** granted by role **name** to AbilityERP Admin, Admin, Rostering, Rostering TL, People and Culture, Manager People and Culture (and mirrored from Unavailability & Leave access).

## WebUI smoke

1. Cache Reset + re-login as Admin.
2. Menu → **Leave Planning**.
3. New/open record: Start/End dates, **All Locations** = Y → Save.
4. Summary by Approver Status / Status+Leave Type populated.
5. **Leave Records** tab: overlapping leave, sorted by Approver Status; Zoom **Leave Record** → existing Submit Leave / Approver Status.
6. Uncheck All Locations, pick Service Locations → Save → lines refresh (no duplicate leave IDs).
7. Toolbar Export / **Leave Planning Report** process.

## Safety

- Does not create separate leave rows; bridge `AbERP_Leave_Planning_Line` only stores IDs.
- Does not change leave approval workflow.
- Never change existing client `*_UU` on HCO.
