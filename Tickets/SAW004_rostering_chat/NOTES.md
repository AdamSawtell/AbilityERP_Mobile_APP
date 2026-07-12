# SAW004 notes

- Includes the Requests-window clone work formerly labeled SAW006.
- Not the same as SAW003 (`com.aberp.rostering.staffinfo`).
- **Other-build install:** point the agent at `idempiere-plugins/com.aberp.rostering.chat/DEPLOY.md` and run `sudo ./deploy.sh` on the target host.
- Reference tenant used `Rostering Officer` = `1000012` and request type id `1000017`; whereclause/client lookups are name-based now, but Chat Assigned SQL still assumes role id `1000012`.
