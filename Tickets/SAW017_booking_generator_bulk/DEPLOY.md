# SAW017 — Deploy to another build (agent)

**Ticket / slug:** `SAW017_booking_generator_bulk`  
**Kind:** idempiere · **JAR:** Yes (AbERP bulk) · **Status:** Bulk plugin scaffolded — generation needs Flamingo generator stack

## Safe / additive rules

1. Install **only** `com.aberp.bookinggenerator.bulk` to add the new process/button/menu.  
2. Do **not** change the existing **Generate Bookings** column/process.  
3. Do **not** install `com.aberp.servicebooking.generator` until its Require-Bundle deps are also present (`GenerateShifts`, `rosteredshift.model`, `serviceopportunity.model`, `generic.utilities.time`). Installing a non-resolving Flamingo jar can leave OSGi noise.

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
| Pack copy | `Tickets/SAW017_booking_generator_bulk/jar/com.aberp.servicebooking.generator_7.1.12.202602251048.jar` |
| Process UU | `6482f6b8-eaa3-4e7b-a8f6-4e263d44909b` |
| Class | `com.aberp.servicebooking.generator.process.GenerateBookings` |

See `jar/README.md` for sibling JARs still needed on HCO Test.

## Smoke

1. Menu or Booking Generator toolbar **Bulk Generate Bookings** visible for Admin.  
2. Existing **Generate Bookings** button unchanged.  
3. With generator stack installed: run one Activity (e.g. Day Program) for a short period → Standards SBs only; Invoice Rule Immediate.  
4. Without generator: process returns a clear error (does not crash the server).
