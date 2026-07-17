# SAW020 — External ticket update (copy/paste)

**Status:** Ready for next HCO Production deployment (HCO Test dry run complete 2026-07-14)  
**Area:** iDempiere — HCO release package HCO20260714  
**Internal ID:** SAW020_hco20260714_release

## Windows / processes / objects affected

| Type | Name | Change |
|------|------|--------|
| **PackIns** | HCO credentials / employee / client / support location | Installed (SAW018) |
| **Info Window** | Notification SR Invoice Send Info | Paid search criteria (SAW001) |
| **Info Window** | Employee (User) / Agency Staff Rostering Info | Staff search UX + JAR (SAW003) |
| **Windows** | Booking Generator / Service Booking / Service Agreement | Activity tab types (SAW007) |
| **Window** | Service Booking → Line | Support Start/End Day numbers (SAW009) |
| **Info Window** | Timesheet Approval | Grid columns + Break Start/End (SAW010) |
| **Window** | HCO Forms and Approvals | Status / Request Submitted / Create template filter (SAW013) |
| **Window** | Skip Dates | Copy Dates From process (SAW015) |
| **Window** | Support Location | Email/Phone grid columns (SAW014) |
| **Process** | Bulk Generate Bookings | New bulk generator (SAW017) |
| **Window** | Vehicle | Activity tab for vehicle communication and follow-up (SAW026) |

**Admin access:** Admin and AbilityERP Admin can use the new/changed Info Windows, processes, and menus introduced by this release.

---

## What’s been done

The HCO20260714 package is being installed on HCO Test as a full production rehearsal. Each completed development ticket is applied in a fixed order, verified, and documented so the same steps can be reused for HCO Production.

## What changed

See the per-ticket external summaries linked from the internal registry. This release combines packins, Info Window improvements, activity tabs, support-day fields, timesheet approval grid, HCO Forms request-create safeguards, Skip Dates copy, Support Location contact columns, Bulk Generate Bookings, and Vehicle Activity.

## Impact

- HCO operations / rostering / booking / timesheet / forms staff using WebUI Admin  
- Production cutover uses the same ordered runbook after this dry run passes

## How to test

1. Log in as Admin on the HCO Test WebUI for this release host.  
2. Smoke each area listed in the objects table (Paid filter, Staff search, Activity tabs, Support Days, Timesheet Approval, HCO Forms Create Request, Skip Dates Copy, Support Location grid contact, Bulk Generate Bookings, Vehicle Activity).  
3. Confirm menus/processes are visible to Admin.

SAW026 was installed and tested on the HCO Test release host on 17 July 2026.
Admin created an Email activity against Vehicle `S637CMD`, the database
confirmed the correct Vehicle link, and the temporary record was removed.

## Notes / caveats

- Dry-run host for this release: see internal deployment report.  
- Do not change existing dictionary UUIDs on HCO.
