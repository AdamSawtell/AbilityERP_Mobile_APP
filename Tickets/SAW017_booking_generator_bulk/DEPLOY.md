# SAW017 — Deploy to another build (agent)

**Ticket / slug:** `SAW017_booking_generator_bulk`  
**Kind:** idempiere · **JAR:** Yes (AbERP bulk) · **Status:** Bulk plugin scaffolded — generation needs Flamingo generator stack

## Safe / additive rules

1. Install **only** `com.aberp.bookinggenerator.bulk` to add the new process/button/menu.  
2. Do **not** change the existing **Generate Bookings** column/process.  
3. Prefer the **patched** generator JAR (`*-no-opp-dep.jar`) — removes unused `serviceopportunity.model` Require-Bundle. Do not install the unpatched generator unless that model JAR is present.

## Ordered SQL (after JAR on host)

From `idempiere-plugins/com.aberp.bookinggenerator.bulk/sql/`:

1. `00-preflight.sql`
2. `01-install-bulk-generate.sql`
3. `02-fix-docaction-list.sql` — **required** if DocAction was installed against core `_Document Action` (135). Must use `BookingGen_DocList` so default `DR` / Drafted works.
4. `04-verify.sql`

Then Cache Reset.

## Bulk plugin (this repo)

| | |
|--|--|
| Path | `idempiere-plugins/com.aberp.bookinggenerator.bulk/` |
| Class | `com.aberp.bookinggenerator.bulk.BulkGenerateBookings` |
| Version | `7.1.0.202607132235` |
| Process UU | `17a01701-b017-4017-8017-000000000001` |

```bash
cd idempiere-plugins/com.aberp.bookinggenerator.bulk
chmod +x build.sh deploy.sh
./deploy.sh
# Cache Reset / logout-in
```

Grants **Admin** + **AbilityERP Admin** by role name.

## Flamingo generator (runtime dependency)

| | |
|--|--|
| Pack copy | `Tickets/SAW017_booking_generator_bulk/jar/com.aberp.servicebooking.generator_7.1.12.202602251048-no-opp-dep.jar` |
| Process UU | `6482f6b8-eaa3-4e7b-a8f6-4e263d44909b` |
| Class | `com.aberp.servicebooking.generator.process.GenerateBookings` |

See `jar/README.md` for sibling JARs.

## Smoke (HCO Test E2E 2026-07-13 — PASS)

Full evidence: [`hco/E2E-SMOKE-20260713.md`](hco/E2E-SMOKE-20260713.md)

1. Menu or Booking Generator toolbar **Bulk Generate Bookings** visible for Admin.  
2. Existing **Generate Bookings** unchanged — BG `2001124` → SB **`53324`**, InvoiceRule `I`, DocStatus `DR` (Sep 1–7).  
3. Bulk: Short Term Accommodation + Include STR=Y + Sep 1–7 → `created/ok=3, failed=0`; SBs **`53325`**, **`53326`** InvoiceRule `I`.  
4. DocAction para list must be `BookingGen_DocList` (not `_Document Action`).  
5. After smoke: confirm DateFrom/DateTo/Activity/IncludeSTR defaults are production-safe (empty / N) — do not leave temporary smoke defaults.
