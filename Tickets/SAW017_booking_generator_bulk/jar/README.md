# Generator stack for SAW017 (HCO Test)

## Install order (OSGi)

1. `com.aberp.rosteredshift.model_7.1.11.202509171959.jar`
2. `com.aberp.process.GenerateShifts_1.1.7.202508141623.jar`
3. `com.aberp.generic.utilities_7.1.4.202510091525.jar`
4. `com.aberp.servicebooking.generator_7.1.12.202602251048-no-opp-dep.jar` **(patched)**

## Why patched generator?

Upstream `7.1.12` `Require-Bundle` includes `com.aberp.serviceopportunity.model`, which is **not** in AbilityERP_CORE, AbERP-v2, Customer_HCO, or Customer_Sunnyhaven.

`GenerateBookings` source/bytecode does **not** import that package — it only sets `AbERP_Service_Opportunity_ID` via the Booking Generator model. The patched JAR removes that unused Require-Bundle so the stack can resolve without inventing a stub model.

Original unpatched jar kept as `com.aberp.servicebooking.generator_7.1.12.202602251048.jar` for reference.
