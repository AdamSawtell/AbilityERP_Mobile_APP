# SAW003 notes

- Ticket **done** and agent-ready. Point agents at **`DEPLOY.md`** (and GitHub [#3](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/3)).
- Bundle: `com.aberp.rostering.staffinfo` — version **`1.1.0.2026071516`**.
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
| `1516` | Four filter ticks (inc. Familiar); Matched untick → credential Find+Select AND; scoped North |

**Pack rule:** JAR **`1516`** ≥ ~55 KB (≈60 KB). Prefer host build / JAR-only over stale packs.

## HCO Future Deployments variables

| Item | HCO value | Notes |
|------|-----------|--------|
| Host | **`13.210.248.141`** | WebUI `http://13.210.248.141/webui/` |
| SSH | `ubuntu@13.210.248.141` · `~/.ssh/HCObusiness.pem` | |
| Login | SuperUser / HCOflamingo · client **HCO** · role **Admin** | |
| Info Window UU | `2b4ab146-0809-47c6-96f3-8b841d60a6bf` | |
| JAR | `…_1.1.0.2026071516.jar` | |
| WebUI health | `http://127.0.0.1/webui/` | Not `:8080` on HCO |

### Scope vs HCO / staging

| Area | Status |
|------|--------|
| SQL `01`–`24`→`04` | Applied |
| JAR `1516` filters + Familiar | Staging + HCO |
| Leave Planning Media CNFE | Separate — SAW016 `zcommon` |

## Agent pitfalls

- Windows → Linux: LF-normalize `build.sh`/`deploy.sh`.
- HCO stop can leave Java running — kill equinox if WebUI 503.
- OpenSSH rejects world-readable PEMs — use `~/.ssh` with tight ACL.
