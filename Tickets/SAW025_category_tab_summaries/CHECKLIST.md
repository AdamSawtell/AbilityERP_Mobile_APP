# SAW025 — Checklist

- [x] Ticket scaffold + GitHub issue
- [x] SQL `35-category-population-summary.sql`
- [x] Engine `PopulationCount` on refresh
- [x] Install on `3.27.207.215`
- [x] SQL `36-fix-population-client-90d.sql` — support-receiver clients + live 90d change
- [x] Re-smoke view KPIs (127 clients; non-zero 90d changes)
- [x] SQL `37-category-kpi-expansion.sql` — shared + category KPIs via DB functions
- [x] Browser-smoke all five category tabs (no SQL modal; fields populated)
- [x] SQL `38-roster-current-next-period.sql` — roster KPIs = current + next period only
- [x] SQL `39-category-progressive-explainers.sql` — grouped lead/category layouts + persistent calculation explanations
- [x] Browser-smoke lead page + all five category form views (groups + explainers; no SQL modal)
- [x] Ticket retarget: one function = category KPIs & layout; SQL 40 ownership → SAW024 (2026-07-19)
- [x] SQL `41-support-location-category.sql` — sixth category Support Location (population, shared KPIs, attribute KPIs, Findings nest, explainers)
- [x] Engine writes `L` category snapshot on Refresh; JAR `7.1.0.202607191730`
- [x] Browser-smoke Support Location (Active=35, Vacant=7, SDA=13, Wheelchair=8, Bushfire=17, Meets=34; Status G; no SQL modal)
- [ ] Client update packs (staging + thin prod) when ready for client install
