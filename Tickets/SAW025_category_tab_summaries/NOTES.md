# SAW025 — Notes

- Live counts come from the dashboard view (no refresh required to see current population).
- Employee/Client/Incident/Doc Change (90d) needs a snapshot with `PopulationCount` from ≤90 days ago; until then change shows 0.
- Rostering change is live vs average of completed pay periods ending in the last 90 days.
- Seed on install writes today’s population onto the latest snapshots so Refresh has a starting baseline.

## Smoke (dev `3.27.207.215` 2026-07-17)

- Employee: Active Employees **210**, Change (90d) **0** at top of tab — pass
- View KPIs: Clients 383 / Incidents 83 / Period shifts 1866 (Δ −91 vs 90d avg) / Documents 9062
- JAR `com.aberp.compliance_7.1.0.202607170530` deployed
