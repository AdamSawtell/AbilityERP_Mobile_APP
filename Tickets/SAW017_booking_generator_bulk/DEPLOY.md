# SAW017 — Deploy to another build (agent)

**Ticket / slug:** `SAW017_booking_generator_bulk`  
**Kind:** idempiere · **JAR:** Expected yes · **Status:** Design / discovery — **not install-ready yet**

Point agents here (not chat history). Repo home: `Tickets/SAW017_booking_generator_bulk/`.

## Current state

No plugin SQL or JAR in repo yet. Complete **Phase 0 host discovery** in [`NOTES.md`](NOTES.md) before implementing. Do not invent Generate Bookings logic from scratch if the existing single-record process JAR can be invoked.

## Required host access (when implementing)

- SSH to iDempiere host  
- `psql` on DB `idempiere` (schema `adempiere`)  
- WebUI Admin login  
- OSGi console for JAR install  
- Never hardcode `AD_*_ID`; never overwrite existing client `*_UU`

## Prerequisites (expected — confirm on target)

| Object | Resolve by |
|--------|------------|
| Window **Booking Generator** | Name or UU `de336034-bd4e-4445-b018-9c762c98d847` (seed hint only) |
| Table **AbERP_BookingGenerator** | `tablename` |
| Existing **Generate Bookings** process | Name / classname from discovery |
| Service Booking = `C_Order` with `AbERP_BookingGenerator_ID` | Column name |

## Agent one-liner

```text
TBD — after plugin path + ordered SQL exist under idempiere-plugins/com.aberp.bookinggenerator.bulk/
```

## AbilityERP Admin access

Any new process / Info Window / button **must** grant **AbilityERP Admin** and operational **Admin** by role **name** (see `docs/DEV-REQUIREMENTS.md`).

## Smoke (target when delivered)

1. Cache Reset / logout-in.  
2. Run bulk/block generate for one Activity block with run-level dates.  
3. Confirm only Standards created; POS/Quotes/templates skipped.  
4. Confirm Invoice Rule Immediate (or configured rule) on new SBs.  
5. Confirm Irregular / STR excluded unless opted in.  
6. Confirm per-BG date override still works for one mid-month case.  
7. Confirm exit-date skip for a known exited client.

## Packs

TBD after staging green.
