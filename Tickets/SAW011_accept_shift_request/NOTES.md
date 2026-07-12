# SAW011 notes

- Button lives on Response Log (`AbERP_AcceptShiftRequest`), not on the Employee tab itself; effect is assigning `AbERP_Rostered_ShiftStaff`.
- Published status currently uses `R_Status_ID = 1000040` in Java — confirm/port by UU/name on other builds before thin prod pack.
- Process access must include AbilityERP Admin / Rostering Officer (see plugin README + `docs/DEV-REQUIREMENTS.md`).
- Registered retroactively; was previously untracked under SAW### (not SAW001).
