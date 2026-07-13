# SAW018 — HCO Release Packins (external summary)

Copy/paste for the customer / external ticket.

## Done

Installed the HCO release 2Pack packins (credentials, employee, client, support location) plus the missing-credentials staff SQL view onto **HCO Test** (`32.236.127.117`), same environment as SAW010. Artifacts and a redeploy how-to are saved for the next environment.

## Changed

| Object / artifact | Change |
|-------------------|--------|
| DB view `hco_cred_missing_staff_v` | Created (staff missing a given credential) |
| 2Pack `hco_credentials` | Dictionary for credentials missing-staff view / Primary Department |
| 2Pack `hco_client_employee` | Employee-side HCO AD updates |
| 2Pack `hco_client` | Client-side HCO AD updates |
| 2Pack `hco_supportlocation` | Support Location dictionary refresh (existing window UU kept) |

## Impact

HCO Test now has the March 2026 release packin set applied. Support Location identity (UUID) was not changed. Planners/admins using Credentials / Support Location / related HCO fields get the packed dictionary updates after Cache Reset.

## How to test

1. Log in as **Admin** (or AbilityERP Admin if available).  
2. **Cache Reset** (or log out/in).  
3. Open **Support Location** — window loads; existing records still open.  
4. Open **Credentials** / related credential screens — Primary Department / missing-staff metadata present where expected.  
5. Optional SQL: `SELECT COUNT(*) FROM hco_cred_missing_staff_v;` returns without error.

## AbilityERP Admin access

No new standalone menu window introduced by this ticket. Existing windows remain available to Admin on HCO Test.

## Windows / processes / objects affected

| Type | Name / identity | Notes |
|------|-----------------|-------|
| Window | Support Location (`6ef3c558-3ec8-4f0c-be40-89f35d8acebf`) | Packin refresh; UU unchanged |
| Table / view | `hco_cred_missing_staff_v` (`598a7584-4c57-4c31-8ea5-3b393d3d1e68`) | AD + DB view |
| Element | Primary Department `hco_primarydept` (`daca9cb3-…`) | From credentials pack |
| Processes (in packs) | Submit Master Location, Recur Lines, Document Validation | Bundled in client/employee packs |
