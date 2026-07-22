# SAW032 — External ticket update (copy/paste)

**Status:** Ready for HCO Production install  
**Area:** iDempiere — Staff Rostering Info (SMS multi-select)  
**Internal ID:** SAW032_sms_staff_info_multiselect  
**GitHub:** [#32](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/32)

## Windows / processes / objects affected

| Type | Name | Change |
|------|------|--------|
| **Info Window** | Employee (User) / Agency Staff Rostering Info | Unchanged UU — remains **single-select** for Shift Find & Fill |
| **Info Window** | Employee (User) / Agency Staff Rostering Info (SMS) | **New** — multi-select clone for SMS |
| **Menu** | …Rostering Info (SMS) | Optional menu to open the SMS Info Window |
| **OSGi plugin** | `com.aberp.rostering.staffinfo` `1.1.0.2026072218` | Serves both Info Windows; restart required |
| **Process** | SMS process (client) | Operator points search / Info Window at the **SMS** UU |

## What’s been done

A second Staff Rostering Info Window was added for SMS / bulk contact picking. It uses the same filters and columns as Find & Fill, but allows selecting multiple staff. Shift Find & Fill stays on the original Info Window and remains single-select so Related Info continues to key off one person.

## Impact

- Rostering / SMS officers who need multi-select contacts  
- Find & Fill on Shift (Rostered) → Employee is **not** switched to multi-select  
- Production JAR upgrade from `1517` → `2218` also carries the current Find & Fill Java fixes already verified on HCO Test

## How to test

1. Shift → Employee → staff search: one row selectable; Related Info matches that contact.  
2. Open **…Rostering Info (SMS)** (or the SMS process after UU assignment): result rows show multi-select checkboxes.  
3. Confirm both Info Windows appear under Application Dictionary / Info Window with the UUs below.

## UUs (do not rename)

| Purpose | UU |
|---------|-----|
| Find & Fill (single) | `2b4ab146-0809-47c6-96f3-8b841d60a6bf` |
| SMS (multi) | `7c9e2a41-5b68-4d3f-a1e0-9f4c6b8d2e11` |

## Install package

- SQL: `28-clone-sms-multiselect-info.sql`  
- JAR: `com.aberp.rostering.staffinfo_1.1.0.2026072218.jar`  
- Runbook: `Tickets/SAW032_sms_staff_info_multiselect/DEPLOY.md`
