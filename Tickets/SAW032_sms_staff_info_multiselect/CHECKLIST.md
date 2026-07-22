# SAW032 — Production checklist

**Host:** `13.239.162.141` · WebUI `https://abilityerp.hco.net.au/webui/`  
**Bundle:** `1.1.0.2026072218` · SQL `28` only

## Pre-flight

- [ ] Confirm git `main` has `release/com.aberp.rostering.staffinfo_1.1.0.2026072218.jar` (~77 KB)
- [ ] Confirm Find & Fill UU exists on prod: `2b4ab146-0809-47c6-96f3-8b841d60a6bf`
- [ ] Confirm current prod JAR is `1517` (or note actual version before swap)
- [ ] Maintenance window / restart approved
- [ ] DB backup / snapshot available (standard HCO practice)

## Install

- [ ] scp SQL `28` + JAR `2218` to `/tmp/`
- [ ] Apply SQL `28` with `ON_ERROR_STOP=1` (idempotent if re-run)
- [ ] Install JAR to `plugins/` + `customization-jar/`; update `bundles.info`
- [ ] Restart iDempiere; WebUI reachable
- [ ] Cache Reset or logout/in as Admin

## Verify

- [ ] `grep staffinfo …/bundles.info` → `1.1.0.2026072218`
- [ ] Both Info Window UUs present; column counts match
- [ ] Find & Fill from Shift Employee → **single-select**
- [ ] SMS Info Window (menu or process) → **multi-select**
- [ ] Operator: SMS process pointed at SMS UU (if process exists)

## Sign-off

| | |
|--|--|
| Deployed by | |
| Date (UTC+9:30) | |
| Verdict | PASS / FAIL |
| Notes | |
