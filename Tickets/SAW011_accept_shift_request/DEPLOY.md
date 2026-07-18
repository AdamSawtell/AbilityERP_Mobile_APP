# SAW011 — Deploy to another build (agent)

**Ticket / slug:** `SAW011_accept_shift_request`  
**Kind:** idempiere · **JAR:** Yes (two bundles)

## Required host access

- SSH · `psql` · WebUI Admin · restart / OSGi  
- Prerequisite: **Shift (Rostered)** + **Response Log** + `AbERP_RosteredResponseLog`  
- Find and Fill also needs SAW003 Staff Rostering Info (UU `2b4ab146-0809-47c6-96f3-8b841d60a6bf`)

## Agent one-liner

```bash
# 1) Accept Shift Request
cd idempiere-plugins/com.aberp.rosteredshift.process
chmod +x build.sh deploy.sh && ./deploy.sh
# JAR com.aberp.rosteredshift.acceptrequest + sql/install-accept-shift-request.sql

# 2) Find and Fill (same ticket)
cd ../com.aberp.rostering.staffinfo
bash build.sh
# copy com.aberp.rostering.staffinfo_1.1.0.202607181830.jar → plugins/ + bundles.info
psql -v ON_ERROR_STOP=1 -d idempiere -f sql/27-response-log-find-fill.sql
# restart or refresh staffinfo bundle; Cache Reset / logout-in
```

## Bundles

| Piece | Bundle | Process |
|-------|--------|---------|
| Accept | `com.aberp.rosteredshift.acceptrequest` | `SHIFT_ACCEPT_REQUEST` |
| Find and Fill | `com.aberp.rostering.staffinfo` (`1.1.0.202607181830+`) | `AbERP_ResponseLog_FindFill` |

## AbilityERP Admin access

| Access | Name | Search key |
|--------|------|------------|
| Process | Accept Shift Request | `SHIFT_ACCEPT_REQUEST` |
| Process | Find and Fill | `AbERP_ResponseLog_FindFill` |
| Info Window | Employee (User) / Agency Staff Rostering Info | — |
| Window | Shift (Rostered) | — |

Roles granted when present: **AbilityERP Admin**, **Admin**, **Rostering Officer**, **Rostering**, **Rostering TL**.

## WebUI smoke

1. Pending **REQ** → **Accept Shift Request** → Employee filled · Reviewed · Published  
2. Unreviewed response + vacant Employee → **Find and Fill** → Info prefilled → OK → Employee filled · Reviewed  
3. Both buttons hidden when **Reviewed = Y**

## External ticket text

`Tickets/SAW011_accept_shift_request/EXTERNAL-SUMMARY.md`
