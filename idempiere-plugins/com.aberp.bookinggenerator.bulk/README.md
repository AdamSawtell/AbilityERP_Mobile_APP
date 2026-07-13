# com.aberp.bookinggenerator.bulk (SAW017)

Additive **Bulk Generate Bookings** process for Booking Generator.

- Does **not** modify the existing **Generate Bookings** button/process.
- At runtime, delegates each selected STANDARD BG row to AD process `Generate Bookings` (UU `6482f6b8-eaa3-4e7b-a8f6-4e263d44909b`).
- Requires Flamingo `com.aberp.servicebooking.generator` (and its OSGi deps) installed on the host for generation to succeed.

## Build / deploy

```bash
cd idempiere-plugins/com.aberp.bookinggenerator.bulk
chmod +x build.sh deploy.sh
./deploy.sh
```

## Parameters

| Para | Default | Notes |
|------|---------|--------|
| Date From / Date To | required | Applied to each BG for the run |
| Activity | optional | Block filter |
| Include Irregular Hrs | N | `STANDARD IRR*` |
| Include Short Term Respite | N | STR / Short Term Accommodation |
| Invoice Rule | Immediate | Forced onto new SB when Force=Y |
| Force Invoice Rule | Y | |
| Document Action | DR | Passed to Generate Bookings |

## Filters (always)

Active, Description `STANDARD%`, not Template, not POS, not Non Binding Offer doctype, not `*Do Not Use*` activity, support ceased before period excluded.
