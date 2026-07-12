# SAW001 — Deploy to another build (agent)

**Ticket / slug:** `SAW001_paid_filter_invoice_send_info`  
**Kind:** idempiere · **JAR:** No · **Status:** done

## Required host access

- SSH to iDempiere host  
- `psql` as postgres (or equivalent) on DB `idempiere` / schema `adempiere`  
- WebUI AbilityERP Admin (Cache Reset / logout-in)

## Agent one-liner

```bash
cd idempiere-plugins/com.aberp.notification.invoiceinfo
chmod +x deploy.sh && sudo ./deploy.sh
# Cache Reset or logout/in. No iDempiere restart.
```

## Package

`idempiere-plugins/com.aberp.notification.invoiceinfo/`

Target Info Window UU: `8fb1cd46-ed81-4cb9-8b83-7662caed9e62` (must exist — preflight fails closed).

## Ordered SQL (`deploy.sh`)

1. `sql/00-preflight-uuids.sql`  
2. `sql/01-add-paid-criteria.sql`  
3. `sql/04-add-info-menu.sql` (parent folder by name **Ability ERP**; never overwrites an existing menu UU)  
4. `sql/05-grant-admin-infowindow-access.sql` (roles **Admin** + **AbilityERP Admin** by name)  
5. `sql/02-verify.sql`  
6. `sql/03-functional-check.sql`  

Rollback: `sql/99-rollback.sql`

## AbilityERP Admin access

- `05-grant-admin-infowindow-access.sql` grants Info Window access to roles named **Admin** and **AbilityERP Admin**.  
- Menu entry is added under **Ability ERP** when that summary folder exists.  
- Smoke as the client’s operational Admin role (on HCO: SuperUser → **Admin**).

## HCO Future Deployments variables

See `NOTES.md` → **HCO Future Deployments variables** (local IDs, role/menu parent lessons). Do not change HCO `*_UU` values.

## Restart / cache

- **No** restart · **Yes** Cache Reset / logout-in

## WebUI smoke

1. Open **Notification SR Invoice Send Info**.  
2. Paid = Yes / No / blank with valid dates.  
3. Confirm grid Paid column; selection still usable for notification run if present.

## Portability risks

- Menu SQL may use tree parent hints — verify menu placement on target.  
- Create From needs Logilite form JAR (pre-existing); use menu if missing.

## Packs

- Staging: `Downloads\AbilityERP-ClientUpdate-SAW001_paid_filter_invoice_send_info-*`
- Thin prod: `Downloads\AbilityERP-ProdUpdate-SAW001_paid_filter_invoice_send_info-20260712\`

## External ticket text

`Tickets/SAW001_paid_filter_invoice_send_info/EXTERNAL-SUMMARY.md`
