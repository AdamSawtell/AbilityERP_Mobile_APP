# Activity Viewer Links — external summary

## Windows / processes / objects affected

| Object | Type | Notes |
|--------|------|--------|
| Activity Viewer | Window | New **Activity Links** field group |
| Client | Window | Opened from Client button |
| Employee | Window | Opened from Employee button |
| Support Location | Window | Opened from Support Location button |
| Open Client | Process (button) | Zooms Client window only |
| Open Employee | Process (button) | Zooms Employee window only |
| Open Support Location | Process (button) | Zooms Support Location window only |

## What’s done

Activity Viewer now has quick links to open the related Client, Employee, and Support Location records in their proper AbilityERP windows. Links only appear when that relationship exists on the Activity.

## What changed (behaviour)

- New **Activity Links** group on Activity Viewer
- **Client** / **Employee** / **Support Location** buttons open those windows — not the generic Business Partner or User screens
- Buttons stay hidden when there is nothing linked

## Impact / who is affected

Staff using Activity Viewer (including from Activity Audit Review → Open Activity). AbilityERP Admin can use the links after install and Cache Reset / re-login.

## How to test

1. Open an Activity in **Activity Viewer** that has a Client
2. Under **Activity Links**, click **Client** — confirm the Client window opens
3. Repeat for **Employee** and **Support Location** when those links exist
4. Confirm a record with no Support Location does not show that button

## Access

| Access | Name | Search key |
|--------|------|------------|
| Window | Activity Viewer | — |
| Window | Client | — |
| Window | Employee | — |
| Window | Support Location | — |
| Process | Open Client | `AbERP_ActivityViewer_OpenClient` |
| Process | Open Employee | `AbERP_ActivityViewer_OpenEmployee` |
| Process | Open Support Location | `AbERP_ActivityViewer_OpenSupportLocation` |
