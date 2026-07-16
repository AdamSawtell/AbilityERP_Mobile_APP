# SAW003 notes

- Ticket **done** and agent-ready. Point agents at **`DEPLOY.md`** (and GitHub [#3](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/3)).
- Bundle: `com.aberp.rostering.staffinfo` — version **`1.1.0.2026071517`**.
- Info Window UU: `2b4ab146-0809-47c6-96f3-8b841d60a6bf`
- Not SAW011 (Accept Shift) or SAW004 (Rostering Chat).
- **Later deploys:** if SQL already applied, use **JAR-only** section in `DEPLOY.md` (no need to re-run `01`–`24`).

## Why this work existed

1. Shift → Employee staff search was slow/heavy and hard to filter leave / overlap / needs.
2. Lean rewrite + Java EXISTS filters + Related Info + decluttered grid.
3. Filter UX (2026-07-15): positive-default ticks — Matched / Not Rostered / Not On Leave / Familiar; single row col 2; Familiar = Support Location history 12 months.
4. North expand scoped to Info window (no parent Shift white-gap after close).

## Late UX / JAR (keep in packs)

| JAR | Behaviour |
|-----|-----------|
| `1517` | Results single-select (Related Info); four filter ticks; Matched untick → credential Find+Select AND; scoped North |

**Pack rule:** JAR **`1517`** ≥ ~52 KB (release ≈52.6 KB). Prefer host build / git `release/` JAR over stale packs.

## HCO Future Deployments variables

| Item | HCO value | Notes |
|------|-----------|--------|
| Host (current Test) | **`3.25.86.128`** | WebUI `http://3.25.86.128/webui/` |
| Host (HCO20260714 dry-run) | **`54.253.165.194`** | JAR `1517` + SQL `25`/`26` 2026-07-16 |
| SSH | `ubuntu@<host>` · `~/.ssh/HCObusiness.pem` | Same key as prior HCO hosts |
| Login | SuperUser / HCOflamingo · client **HCO** · role **Admin** | |
| Info Window UU | `2b4ab146-0809-47c6-96f3-8b841d60a6bf` | |
| JAR | `release/…_1.1.0.2026071517.jar` (~52 KB) | JAR-only if SQL through `24` already applied |
| SQL | through **`26`** | `25` hide leave/future cols; `26` Partner Location suburb |
| WebUI health | `http://127.0.0.1/webui/` | Not `:8080` on HCO |

### Scope vs HCO / staging

| Area | Status |
|------|--------|
| SQL `01`–`24`→`04` | Applied |
| SQL `25` / `26` | Staging + `3.25.86.128` + `54.253.165.194` |
| JAR `1517` single-select + filters | Staging + HCO |
| Leave Planning Media CNFE | Separate — SAW016 `zcommon` |

## Agent pitfalls

- Windows → Linux: LF-normalize `build.sh`/`deploy.sh`.
- HCO stop can leave Java running — kill equinox if WebUI 503.
- OpenSSH rejects world-readable PEMs — use `~/.ssh` with tight ACL.
