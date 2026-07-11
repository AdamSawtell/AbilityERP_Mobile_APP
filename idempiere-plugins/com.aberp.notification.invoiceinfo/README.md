# Notification SR Invoice Send Info — Paid filter

Adds a **Paid** search parameter to **Notification SR Invoice Send Info**
(`AD_InfoWindow_UU = 8fb1cd46-ed81-4cb9-8b83-7662caed9e62`, ID `1000032`).

## Behaviour

| Paid parameter | Result |
|----------------|--------|
| Yes | `C_Invoice.IsPaid = 'Y'` only |
| No | `C_Invoice.IsPaid = 'N'` only |
| Blank | No payment-status filter (paid and unpaid) |

Uses existing `C_Invoice.IsPaid` via FROM alias `i` (`fromclause = C_Invoice i`).
No new DB column. No change to AbERP Notification Run process logic.

Implementation matches core **Invoice Info**: List reference `_YesNo` (319) for
optional Yes/No criteria, plus a Yes-No display column in the result grid.

## Install

On the iDempiere host:

```bash
cd /opt/ability-erp-pwa/idempiere-plugins/com.aberp.notification.invoiceinfo
chmod +x deploy.sh
sudo ./deploy.sh
```

Then **Cache Reset** (or log out/in).

## Rollback

```bash
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 \
  -f sql/99-rollback.sql
```

## Files

| File | Purpose |
|------|---------|
| `sql/00-preflight-uuids.sql` | Fail fast if Info Window UU missing |
| `sql/01-add-paid-criteria.sql` | Idempotent AD_InfoColumn insert/update |
| `sql/04-add-info-menu.sql` | Menu Action=I so the Info Window opens directly |
| `sql/02-verify.sql` | Confirm columns and criteria order |
| `sql/03-functional-check.sql` | Sample paid/unpaid rows + AD presence |
| `sql/99-rollback.sql` | Remove Paid InfoColumns + menu |
| `deploy.sh` | Apply migration on server |

**Note:** `AbERP Notification Run` → Create From needs
`com.logilite.crm.notification.webui.WCreateNotificationLines`. If that plugin jar is
missing, open the Info Window from the menu instead.
