# Generator prerequisite JARs

| File | Role |
|------|------|
| `com.aberp.servicebooking.generator_7.1.12.202602251048.jar` | Contains `GenerateBookings` — **required** for bulk to create SBs |

## Also required (from generator MANIFEST `Require-Bundle`)

These were **not** present on HCO Test at discovery time. Install before/with the generator:

- `com.aberp.process.GenerateShifts`
- `com.aberp.rosteredshift.model`
- `com.aberp.serviceopportunity.model`
- package `com.aberp.generic.utilities.time` (Import-Package)

Until those resolve, do **not** expect the generator bundle to start. The SAW017 bulk plugin can still be installed additively; runs will report that Generate Bookings is unavailable.
