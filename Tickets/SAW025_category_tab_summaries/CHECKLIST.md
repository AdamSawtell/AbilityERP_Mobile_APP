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
- [x] SQL `40-findings-parent-only-navigation.sql` — Findings subtabs hidden until their category is selected
- [x] Browser-smoke lead hierarchy + parent Findings grid/Open & Fix access
- [ ] Client update packs (staging + thin prod) when ready for client install
