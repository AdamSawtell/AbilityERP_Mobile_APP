# SAW003 notes

- Ticket **done** and agent-ready. Point agents at **`DEPLOY.md`** (and GitHub [#3](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/3)).
- Bundle: `com.aberp.rostering.staffinfo` — version **`1.1.0.2026071510`**.
- Info Window UU: `2b4ab146-0809-47c6-96f3-8b841d60a6bf`
- Not SAW011 (Accept Shift) or SAW004 (Rostering Chat).
- **Later deploys:** if SQL already applied, use **JAR-only** section in `DEPLOY.md` (no need to re-run `01`–`24`).

## Why this work existed

1. **Original problem:** Shift → Employee staff search was slow/heavy and hard to filter leave / overlap / credential needs.
2. **Rewrite (SAW003):** Lean User+BP query, Java EXISTS filters, Related Info, clearer UX.
3. **HCO follow-ups:** ZK **non-negative only** — fixed in SQL `21`–`23` + Java sanitize.
4. **Perf:** `24-perf-staff-info.sql` + JAR credential prefetch.
5. **Unmatched credential filter:** Show Unmatched ignores Related Needs; optional AND via zul Listbox.
6. **UX (`1510`):** Find + Selected summary; **two columns**; North expand scoped to Info Window only (closes without white gap on Shift window).

## Late UX (keep in packs)

| Script / Java | Behaviour |
|---------------|-----------|
| `18`–`24` | Result readonly, Staff Name, hide clutter, non-negative, perf |
| Java `1237` | Two-column Find + Select (AND); Selected summary / Clear; expand North on Show Unmatched |

## Packs

- `Downloads\AbilityERP-ClientUpdate-SAW003_staff_rostering_info-20260712\`
- `Downloads\AbilityERP-ProdUpdate-SAW003_staff_rostering_info-20260712\`

**Pack rule:** JAR **`1237`** ≥ ~40 KB (≈57 KB). Prefer host build / JAR-only deploy over stale packs.

## HCO Future Deployments variables

| Item | HCO value (2026-07-14) | Notes |
|------|------------------------|--------|
| Host | **`13.210.248.141`** | WebUI `http://13.210.248.141/webui/` — old IP `32.236.127.117` retired |
| SSH | `ubuntu@13.210.248.141` · `~/.ssh/HCObusiness.pem` (or `d:\HCObusiness.pem` with user-only ACL) | |
| Login | SuperUser / HCOflamingo · client **HCO - Disability and Community Services** · role **Admin** | |
| Info Window UU | `2b4ab146-0809-47c6-96f3-8b841d60a6bf` | Local `AD_InfoWindow_ID` = **1000034** |
| JAR | `…_1.1.0.2026071237.jar` | Two-column credential UX |
| WebUI health | `http://127.0.0.1/webui/` | Not `:8080` on HCO |
| Org `*` shifts | large share of data | Do **not** bulk-move; smoke `ad_org_id > 0` |

### Scope vs HCO

| Area | Status |
|------|--------|
| SQL `01`–`24`→`04` | Applied |
| Unmatched AND + Find + two-column UX | **`1237`** on HCO + staging |
| Leave Planning Media CNFE | Separate — SAW016 `zcommon` |

## Agent pitfalls

- Windows → Linux: LF-normalize `build.sh`/`deploy.sh`. Never `sed`/`tr` that eats trailing `r`.
- HCO idempiere stop can leave Java running (“already running”) — kill equinox launcher if WebUI stays 503.
- OpenSSH rejects PEMs that are world-readable; use `~/.ssh` copy or tighten ACL on `d:\*.pem`.
