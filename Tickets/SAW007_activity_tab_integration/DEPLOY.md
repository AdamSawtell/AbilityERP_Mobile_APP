# SAW007 — Deploy to another build

**Ticket:** `SAW007_activity_tab_integration` · **Kind:** idempiere · **JAR:** marker-only (still install via deploy)

## Agent one-liner (other builds — portable)

```bash
cd idempiere-plugins/com.aberp.contactactivity.tabs
# Prefer UU/name scripts — do NOT rely on seed window IDs in sql/02 alone:
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 \
  -f register-contactactivity-tabs.sql \
  -f fix-activity-user-contact.sql
# Optional: -f hide-activity-user-contact.sql
# Install/start marker bundle if required by host runbook, then Cache Reset / logout-in
```

Seed-oriented path (may hardcode window IDs — verify first):

```bash
chmod +x build.sh deploy.sh && ./deploy.sh   # sql/01 → 02 → 03 + restart
```

## Package

`idempiere-plugins/com.aberp.contactactivity.tabs/`

Also see `INSTALL-CONTACT-ACTIVITY-TABS.md` if present in package.

## Ordered SQL

**Portable (preferred on other builds):**

1. `register-contactactivity-tabs.sql`  
2. `fix-activity-user-contact.sql`  
3. Optional `hide-activity-user-contact.sql`

**Seed deploy.sh path:**

1. `sql/01-add-link-columns.sql`  
2. `sql/02-add-activity-tabs.sql` (hardcodes window IDs — portability risk)  
3. `sql/03-update-activity-type-windows.sql`

## Restart / cache

- Restart if installing the marker JAR via `deploy.sh`  
- Always Cache Reset / logout-in after AD SQL

## WebUI smoke

1. Open Booking Generator / Service Booking / Service Agreement (as installed) → **Activity** tab → New.  
2. Activity types available; user/contact behaviour matches `fix-activity-user-contact.sql` (BP + user BP, not forced login user).  
3. Role “Included Activities” filter if used on that build.

## Blockers / notes

- Numbered `sql/02`/`03` hardcode window IDs — **fail or wrong windows** on clients with different IDs. Use `register-contactactivity-tabs.sql`.  
- Needs Enquiry Activity (or equivalent) as clone template; `C_ContactActivity` present.  
- No Downloads pack yet.

## Packs

- Create `AbilityERP-*-SAW007_activity_tab_integration-*` when shipping; document portable SQL order in HOW-TO.
