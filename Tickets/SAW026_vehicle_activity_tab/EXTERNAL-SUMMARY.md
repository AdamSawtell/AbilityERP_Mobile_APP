# SAW026 — Vehicle Activity tab

**Status:** Complete and tested  
**Area:** iDempiere — Vehicle  
**Internal ID:** `SAW026_vehicle_activity_tab`

## Windows / processes / objects affected

| Type | Name | Change |
|---|---|---|
| Window | Vehicle | Activity tab added |
| Tab | Activity (`C_ContactActivity`) | New tab linked to the selected Vehicle |
| List | Contact Activity Type | Email, Meeting, Phone call, Case Note, and Task enabled for Vehicle |
| Table / column | Contact Activity vehicle link | Added or updated as required |
| Process | None | — |
| Menu | None | Uses the existing Vehicle menu |

## What’s been done

The Vehicle window now includes the standard AbilityERP Activity tab. Users can record Email, Meeting, Phone call, Case Note, and Task activities against an individual vehicle.

## Impact

Vehicle-related communication and follow-up can be recorded directly from the Vehicle window using the same Activity structure already used elsewhere in AbilityERP.

## How to test

1. Log in as AbilityERP Admin or Admin.
2. Open **Vehicle** and select an existing vehicle.
3. Open the **Activity** tab and create a record.
4. Confirm Activity Type offers Email, Meeting, Phone call, Case Note, and Task.
5. Save and confirm the activity remains attached to the selected Vehicle.

## Test result

Installed and tested on HCO Test001. Admin opened Vehicle `S637CMD`, confirmed all five Activity Types, saved an Email activity, and the database confirmed that it was linked to the correct Vehicle. The smoke-test record was removed after verification.

## Access

Install SQL grants AbilityERP Admin, and Admin where required, access to the parent Vehicle window.

| Access | Name | Search key |
|---|---|---|
| Window | Vehicle | — |
