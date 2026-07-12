# SAW004 — Rostering Chat

| | |
|--|--|
| **Status** | done |
| **Kind** | both |
| **GitHub** | [#4](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/4) |
| **Slug** | `SAW004_rostering_chat` |

## Goal

Rostering Chat WebUI and sync with the mobile/app surface.

## Source of truth

- iDempiere / WebUI rostering chat plugin and AD SQL (under `idempiere-plugins/` — update path if renamed)
- App chat sync / UX under `web/` (list concrete paths when touching this ticket again)

## Dependencies (app)

App chat inbox/sync must stay compatible with WebUI reply/close/status behaviour. Document exact routes/files when revisiting.

## Packs

- ERP changes via `AbilityERP-*-SAW004_rostering_chat-*` when shipping AD/plugin
- App deploys separately (Amplify / normal app release) when Kind includes app
