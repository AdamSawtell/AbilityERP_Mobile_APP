# AbERP Rostered Shift — period search default (SAW022)

SQL-only: when **Shift (Rostered)** opens in Find/Search, **Roster Period** defaults to the current pay period.

```bash
chmod +x deploy.sh && ./deploy.sh
# then Cache Reset
```

Rollback: `sql/99-rollback.sql`
