# SAW001 — Deploy to another build

**Ticket:** `SAW001_paid_filter_invoice_send_info` · **Kind:** idempiere · **JAR:** No (AD SQL only)

## Agent one-liner

```bash
cd idempiere-plugins/com.aberp.notification.invoiceinfo
chmod +x deploy.sh && sudo ./deploy.sh
# then Cache Reset (or logout/in). No iDempiere restart.
```

## Package

`idempiere-plugins/com.aberp.notification.invoiceinfo/`

## Ordered SQL (if not using deploy.sh)

1. `sql/00-preflight-uuids.sql` — fails if Info Window UU missing  
2. `sql/01-add-paid-criteria.sql`  
3. `sql/04-add-info-menu.sql`  
4. `sql/02-verify.sql`  
5. `sql/03-functional-check.sql`  

Rollback: `sql/99-rollback.sql`

Target Info Window UU: `8fb1cd46-ed81-4cb9-8b83-7662caed9e62`

## Restart / cache

- **No** `systemctl restart idempiere`
- **Yes** Cache Reset or logout/in

## WebUI smoke

1. Open **Notification SR Invoice Send Info** (menu; or Create From if Logilite form is present).
2. Confirm **Paid** criteria: blank / Yes / No.
3. With valid dates + doc status: Yes → paid only; No → unpaid only; blank → both.
4. Selected rows still usable with AbERP Notification Run when that flow exists.

## Blockers / notes

- Create From may fail without `com.logilite.crm.notification.webui.WCreateNotificationLines` — open Info Window from menu instead (pre-existing).
- Thin prod Downloads pack may be missing; staging pack name pattern: `AbilityERP-ClientUpdate-SAW001_paid_filter_invoice_send_info-*`.

## Packs

- Staging (if present): `Downloads\AbilityERP-ClientUpdate-SAW001_paid_filter_invoice_send_info-*`
- Prod: create `AbilityERP-ProdUpdate-SAW001_…` before client go-live (least files: apply + rollback + HOW-TO)
