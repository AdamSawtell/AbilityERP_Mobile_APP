# SAW031 — Deploy

## Host notes (HCO Test dry-run used for fix)

| Item | Value |
|------|--------|
| WebUI | `https://3.25.213.143/webui/` (or client host) |
| SSH | host user + key for that build |
| Login | SuperUser / Admin (HCO: `HCOflamingo`) |
| DB | `idempiere` / `adempiere` / `flamingo` |
| iDempiere home | `/opt/idempiere-server` |

## Prerequisites

- SAW009 Support Day List change already applied (columns List = **14 Day Roster Period**).
- Bundle `com.aberp.servicebooking.generator` present (Flamingo / prior HCO release).

## Install order

### 1) Patch / replace generator JAR (required)

```bash
cd idempiere-plugins/com.aberp.servicebooking.supportdays/patch
chmod +x install-patched-generator.sh patch-eeee-beforesave.py
# Uses original generator jar under plugins/ (or bak in /tmp) and writes
# com.aberp.servicebooking.generator_7.1.12.2026072205-saw031.jar
# (EEEE neutralized + typed setters no-op + Export-Package model)
sudo bash install-patched-generator.sh
```

Or copy a pre-built patched jar from the Downloads pack `jar/` into `plugins/` + `customization-jar/`, update `bundles.info`, remove any older `com.aberp.servicebooking.generator_*.jar` from `plugins/`, then restart iDempiere.

**Do not leave two generator jars in `plugins/`.**

### 2) Optional overlay + cleanup SQL

```bash
cd idempiere-plugins/com.aberp.servicebooking.supportdays
chmod +x deploy-saw031.sh build.sh
sudo bash deploy-saw031.sh
```

Applies:

1. Build/install `com.aberp.servicebooking.supportdays_7.1.0.2026072205.jar`
2. `sql/06-cleanup-weekday-text.sql`
3. `sql/07-verify-saw031.sql`
4. iDempiere restart

### 3) Cache Reset / logout-in

## AbilityERP Admin access

No new Window / Process / Info / Form. Generator + existing Service Booking window only.

| Access | Name | Search key |
|--------|------|------------|
| Window | Service Booking | — |

(No new role grants required beyond existing Service Booking access.)

## Smoke

1. Open Service Booking with unvalidated lines that have Support Start/End Day set (e.g. pattern day `03 - Wednesday`).
2. Tick **Validated**, Save.
3. Expect: Support days unchanged; save succeeds; no `Invalid value - Thursday` (or other weekday); Ready to Claim may auto-tick per Ready to Claim Rule.
4. SQL: `sql/07-verify-saw031.sql` → leftover weekday counts = 0.

## Downloads packs (prod handoff)

| Tier | Path |
|------|------|
| Staging | `C:\Users\sawte\Downloads\AbilityERP-ClientUpdate-SAW031_support_day_validate_fix-20260722\` |
| Production | `C:\Users\sawte\Downloads\AbilityERP-ProdUpdate-SAW031_support_day_validate_fix-20260722\` |

Production pack (least files): both JARs + `01-APPLY.sql` + `99-ROLLBACK.sql` + `HOW-TO.txt`.

## Rollback

- Restore prior generator jar from backup (`*.bak-pre-saw031` or previous `bundles.info` entry).
- Remove `com.aberp.servicebooking.supportdays` from `bundles.info` / plugins if installed.
- Weekday cleanup SQL is data-fixing — restore from DB backup if needed.
