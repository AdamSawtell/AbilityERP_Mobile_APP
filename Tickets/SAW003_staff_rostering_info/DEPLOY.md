# SAW003 — Deploy to another build

**Ticket:** `SAW003_staff_rostering_info` · **Kind:** idempiere · **JAR:** Yes · **Status:** in-progress

> Do not deploy as “done” until checklist is green. Coordinate if another agent owns this plugin.

## Agent one-liner

```bash
cd idempiere-plugins/com.aberp.rostering.staffinfo
chmod +x build.sh deploy.sh
./deploy.sh
# restarts idempiere and waits for WebUI HTTP 200; then Cache Reset / logout-in
```

## Package

`idempiere-plugins/com.aberp.rostering.staffinfo/`

Info Window UU (must exist): `2b4ab146-0809-47c6-96f3-8b841d60a6bf`

## Ordered SQL (deploy.sh order)

1. `01-indexes.sql`  
2. `02-rewrite-infowindow.sql`  
3. `03-rewrite-infocolumns.sql`  
4. `05-hotfix-browser-smoke.sql`  
5. `06-fix-shift-org.sql`  
6. `07-eligibility-criteria.sql`  
7. `08-enable-related-info.sql`  
8. `09-find-fill-ux.sql`  
9. `10-java-ux-org.sql`  
10. `11-drop-redundant-criteria.sql`  
11. `12-needs-match-criteria.sql`  
12. `14-fix-show-unmatched-selectclause.sql`  
13. `15-fix-onapprovedleave-criteria.sql`  
14. `16-fix-nonnegative-id-criteria.sql`  
15. `17-fix-hidden-multiselect-criteria.sql`  
16. `18-fix-result-grid-readonly.sql`  
17. `19-rename-staff-name.sql`  
18. `20-hide-clutter-columns.sql`  
19. `04-verify.sql`  

Not in normal deploy: `13-load-test-needs-match.sql`, `99-rollback.sql`.

## Restart / cache

- **Yes** `systemctl restart idempiere` (OSGi JAR)
- **Yes** Cache Reset / logout-in

## WebUI smoke

1. **Shift (Rostered) → Employee** → open Staff Info search.
2. Name wildcards; leave / overlap behaviour; Show Unmatched / needs-match if enabled.
3. Related Info (credentials / shifts) still opens.
4. Picking a contact fills BP / org as designed.

## Blockers / notes

- Checklist still open; **no** Downloads pack yet.
- Parallel-agent collision risk on this plugin path.

## Packs

- None yet — use `AbilityERP-*-SAW003_staff_rostering_info-*` when shipping.
