# Max Messenger Bot Integration for Claude Code

Research + design doc. Author: research pass 2026-04-20. Do NOT implement from this alone — read the open questions section first.

---

## TL;DR

- Max Bot API is real, public, and stable. Docs at `https://dev.max.ru/docs-api`, base URL `https://platform-api.max.ru`. Bot tokens issued through an in-app "Chat-bots" panel, passed as `Authorization: <token>` header. No closed-beta blocker.
- Shape is very close to Telegram Bot API: text/photo/video/document/voice/audio, inline keyboards, edits, long-polling `GET /updates` for dev, webhooks for prod, 30 rps quota. So the Claude-Code plugin design can be a near-clone of the Telegram plugin.
- Real gaps vs Telegram: no reactions on messages, no stickers/polls/video-notes, no native "reply threading" semantics in the same way, edit/delete restricted to a 24-hour window, long-polling "for dev only" (but works fine and is what we should use locally).
- Official TS library `@maxhub/max-bot-api` exists (grammy-style API, `bot.on('message_created')`, `bot.command()`), MIT. Works as a drop-in for the grammy layer in the existing Telegram plugin.
- Two publishing constraints to know up front: (1) Max now requires a verified RU legal entity to publish a bot publicly - for personal/internal use a private unpublished bot is fine; (2) webhooks require port 443, CA-signed TLS, HTTPS-only - irrelevant if we use long-polling, which we should for a single-owner assistant.
- Recommended architecture: do NOT build a unified multi-transport plugin (option b). Ship a standalone `max` plugin that mirrors the Telegram plugin's structure (option a), and put the convergence later at the deskd bus layer (option c), which is already built for exactly this.
- MVP for one-week scope: fork the Telegram plugin directory, swap grammy -> `@maxhub/max-bot-api`, strip the `react` tool, keep `reply`/`edit_message`/`download_attachment`, reuse the same access.json pairing model. Skip permission inline buttons in v1 (Max has callbacks but the UX needs a separate pass).

---

## 1. Max API snapshot

All claims marked with confidence: `O` = official docs, `B` = blog/third-party article, `C` = community/GitHub.

### 1.1 Transport and auth

| Item | Value | Confidence |
|------|-------|------------|
| Base URL | `https://platform-api.max.ru` | O - dev.max.ru/docs-api |
| Auth | Bearer token in `Authorization:` header. Query-param auth deprecated. | O |
| Token issuance | In Max app -> Chat-bots -> Integration -> "Get token" | O |
| Long-polling | `GET /updates` - "recommended for dev/test only" | O |
| Webhook | `POST /subscriptions` with HTTPS URL, port 443, CA-signed cert. Auto-unsubscribes after 8h of silence. | O + B (vc.ru) |
| Rate limit | 30 rps per bot (global), documented as a hard cap | O |
| File upload | `POST /uploads` separate endpoint (get URL -> PUT file -> reference by token). Max file size not documented on API page; vc.ru comparison claims 4 GB with resumable upload. | O + B |

### 1.2 Supported message content

| Content | Inbound | Outbound | Notes |
|---------|---------|----------|-------|
| Text | yes | yes | 4000 char cap (vs Telegram 4096) |
| Photo | yes | yes | via upload endpoint |
| Video | yes | yes | |
| Audio | yes | yes | |
| Voice | yes | yes | |
| Document (any file) | yes | yes | up to ~4 GB per vc.ru |
| Inline keyboard / callback buttons | yes | yes | up to 210 buttons, 30 rows, 7/row |
| Edit own message | yes | yes | 24-hour window only |
| Delete own message | yes | yes | 24-hour window only |
| Reactions | NO | NO | Not in current API |
| Stickers | no | no | Not supported |
| Polls | no | no | Not supported |
| Video notes (circles) | no | no | Not supported |
| Reply threading (native) | partial | partial | Messages carry `link` to replied message but there's no Telegram-grade thread semantics |

Confidence: O for types, B (vc.ru article) for the caps.

### 1.3 Update types

Known from docs snippets: `message_created`, `bot_started`, `message_callback`. Full enumeration was not captured during this pass - see Open Questions.

### 1.4 Official SDKs

| Language | Repo | Confidence |
|----------|------|------------|
| TypeScript/JS | `max-messenger/max-bot-api-client-ts` - npm `@maxhub/max-bot-api`, grammy-style (`bot.on('message_created')`, `bot.command()`), MIT | O + C |
| Go | `max-messenger/max-bot-api-client-go` | O + C |
| Python | `max-messenger/max-botapi-python` | O + C |

### 1.5 Publishing / policy constraints

- 2025-2026 policy change: publishing bots or mini-apps publicly in the Max directory now requires a verified Russian legal entity. Source: Habr article "MAX изменил правила" (confidence: B). Implication for us: a private, unpublished bot tied to our account still works for personal assistant use - same as Telegram. We just cannot list it publicly in Max's catalog.

### 1.6 What Max does NOT have vs Telegram

- No message reactions API -> `react` tool cannot be ported.
- Edit window is 24h -> our `edit_message` tool needs a guard and better error reporting for stale edits.
- Long-polling officially "for dev only" -> for single-user operator use this is fine and matches how the Telegram plugin polls locally. No public IP / TLS needed.
- No BotFather analog with "privacy mode" toggle - group behaviour rules live on our side, not server-side.
- Production deployments expect webhook with public HTTPS. We will not use this in v1.

---

## 2. Feature parity matrix (Telegram vs Max)

| Capability | Telegram (current plugin) | Max (proposed plugin) | Port strategy |
|------------|---------------------------|-----------------------|---------------|
| Inbound text | yes | yes | Direct port |
| Inbound photo (auto-download to inbox) | yes | yes | Direct port, different SDK call |
| Inbound document/voice/audio/video | yes (meta + download_attachment) | yes | Direct port |
| Inbound sticker / video_note | yes | no | Drop handlers |
| Outbound reply (text + chunking) | yes, 4096 cap | yes, 4000 cap | Lower the `textChunkLimit` default |
| Outbound files as photo vs document | yes (by ext) | yes | Port, adjust upload flow (two-step upload) |
| Edit own message | yes, anytime | yes, within 24h | Keep tool, surface 24h error |
| React to message | yes (fixed whitelist) | NO | Drop `react` tool |
| Native reply threading (`reply_parameters`) | yes | partial | Pass the reply id if SDK supports it; fall back silently if not |
| Inline keyboard (permission buttons) | yes | yes (more buttons allowed) | Port `perm:allow/deny/more` callback_query flow to Max's `message_callback` |
| Typing indicator | yes | unknown - see open q's | Optional for v1 |
| `chat_action` pre-reply | yes | unknown | Optional for v1 |
| Pairing via 6-char code | yes (in-plugin flow) | yes (same mechanism - nothing Max-specific needed) | Direct port |
| Allowlist / group policy | yes | yes, same concept | Direct port; groups in Max use different ID shape - see open q's |

---

## 3. Architectural options

Three options considered for supporting Max (and later Mattermost) alongside Telegram.

### 3.1 Option A - Clone per transport (three sibling plugins)

```
~/.claude/plugins/cache/claude-plugins-official/
  telegram/0.0.6/        [existing]
  max/0.0.1/             [new, near-identical layout]
  mattermost/0.0.1/      [later]
```

Each plugin is a self-contained Bun/TS MCP server, its own `~/.claude/channels/<name>/` state dir, its own access.json, its own pairing code generator. Claude Code loads them via `--channels plugin:max@...` etc.

Pros:
- Lowest cognitive load. Each plugin is a direct, small fork. Low blast radius per change.
- No new abstractions. The Telegram plugin is battle-tested; we inherit all its safety (PID file, orphan watchdog, assertSendable, permission reply intercept).
- Plugins can be updated / released independently.
- Matches Claude Code's existing plugin convention (telegram, slack, discord are already separate).
- Cheapest path to a working Max bot.

Cons:
- Code duplication: pairing logic, chunking, file send, gate() - roughly 300 lines duplicated per transport.
- Three separate allowlists to manage, three `/access` skills to remember.
- A user change in one (e.g. new chunking policy) has to be manually synced to the others.

### 3.2 Option B - One plugin, pluggable transport adapters

```
~/.claude/plugins/cache/claude-plugins-official/
  channels/0.1.0/
    server.ts               [MCP layer + shared pairing, chunking, access]
    transports/
      telegram.ts           [grammy adapter]
      max.ts                [@maxhub/max-bot-api adapter]
      mattermost.ts
```

Pros:
- Single allowlist UX. One `/channels:access` skill covers everything.
- Shared bug fixes.

Cons:
- We need to design a transport interface that accommodates Telegram-only features (reactions, stickers) and Max-only features (210-button keyboards). Every capability becomes an optional feature flag.
- We break the existing Telegram plugin's public contract (tool names change or we keep a shim). The Telegram plugin ships as a blessed Anthropic plugin; forking it to multi-plexed form means we own the whole thing forever.
- MCP tool names collide or have to be namespaced (`telegram.reply`, `max.reply`). Claude Code's rules for multiple same-name tools across one server are awkward.
- This is a premature abstraction: we have exactly two transports on the horizon, one of which (Mattermost) has a very different model.

### 3.3 Option C - Separate processes, shared bus (deskd-style)

```
          +------------+
          |  Claude    |
          +-----+------+
                | MCP (stdio)
        +-------+--------+
        |  bus-bridge    |
        +-------+--------+
                | Unix socket (deskd bus)
   +------------+------------+
   |            |            |
+--+--+      +--+--+      +--+--+
| tg  |      | max |      | mm  |
+-----+      +-----+      +-----+
```

Each transport runs as an independent process that only knows how to speak its protocol and publish/subscribe on a shared bus. A bridge process speaks MCP to Claude Code and routes messages to/from transports over the bus. deskd already has:

- `src/app/bus.rs` - Unix socket newline-JSON bus
- `src/app/adapters/telegram.rs` - working telegram adapter that routes to/from the bus
- `src/app/unified_inbox.rs` - per-agent inbox pattern
- `src/app/a2a.rs` - agent discovery via `/.well-known/agent-card.json`
- `src/app/worker.rs` - worker loop pattern

Pros:
- Clean separation. Each transport is small and independently ownable.
- Mattermost and Max just become new adapters under `src/app/adapters/`.
- The bus already exists in Kostya's deskd - we do not build this.
- Matches the nassau/deskd direction the owner is already pursuing.
- Transport crashes isolated; bridge process stays up.

Cons:
- Two moving parts to set up (Claude Code MCP + deskd). For single-laptop personal use this is heavier than option A.
- deskd's telegram adapter is NOT the same thing as the blessed Anthropic Telegram plugin. It does not implement pairing codes, permission relay, assertSendable, typing indicators, etc. Adopting deskd means rebuilding those behaviours inside deskd adapters.
- Cross-repo coordination: deskd is kgatilin's repo (per instructions we do not modify it). We would need to contribute upstream or wait for the A2A surface to stabilise.
- Changes the day-to-day install UX: users now need both Claude Code and deskd running.

### 3.4 Recommendation

**Short term (this week and the next month): Option A.** Fork the Telegram plugin directory, produce a `max/0.0.1/` sibling. This lets us ship a working Max bot within days, and duplicated code is small and predictable.

**Medium term (when Mattermost also gets built): re-evaluate towards Option C**, but only once deskd's A2A surface has stabilised and the Telegram plugin's safety behaviours have been ported to the deskd telegram adapter. Treat that as a nassau-level integration milestone, not a plugin milestone.

**Do not pick Option B.** The abstraction does not earn its cost with only two transports, and it forces us to maintain a fork of the official Telegram plugin forever.

---

## 4. Minimal viable path (ship in a week)

Scope: single-user DM bot, long-polling, the owner's personal Max account.

### 4.1 Files to create

All paths relative to `~/.claude/plugins/cache/claude-plugins-official/max/0.0.1/`:

```
package.json              [deps: @modelcontextprotocol/sdk, @maxhub/max-bot-api]
server.ts                 [MCP stdio server - forked from telegram server.ts]
README.md                 [Quick-setup adapted from telegram's README]
ACCESS.md                 [Same doc adapted: no reactions section, pairing unchanged]
skills/
  configure/SKILL.md      [/max:configure <token>]
  access/SKILL.md         [/max:access pair|allow|policy|group]
```

State dir: `~/.claude/channels/max/` containing `.env`, `access.json`, `inbox/`, `approved/`, `bot.pid`. Exact mirror of the Telegram layout.

### 4.2 Tools exposed to Claude (v1)

| Tool | Ported from Telegram | Notes |
|------|----------------------|-------|
| `reply` | yes | Keep chunking, `reply_to`, `files`, `format`. Lower default `textChunkLimit` to 4000. Max's sendMessage signature differs - adapter layer wraps. |
| `edit_message` | yes | Return a clear error when the 24h window has passed. |
| `download_attachment` | yes | Different download flow (upload tokens, not file_id - see adapter docs). |
| `react` | NO | Max does not support reactions. Drop the tool entirely, also remove `ackReaction` field from access.json. |

### 4.3 What to skip for v1

- Permission inline buttons (`perm:allow/deny/more` via `callback_query`). Max has callback buttons (`message_callback`), but the keyboard layout and callback payload format are different enough that this deserves a second pass. For v1, permission relay falls back to the "yes xxxxx" text-reply intercept, which already exists in the Telegram plugin and is transport-agnostic.
- Groups / supergroups. Access policy keeps the `groups` schema field but we do not test group pairing in v1. DM-only.
- Typing indicator and ack-reaction. Nice-to-haves; skip until stable.
- Webhook mode. Long-polling only in v1.
- Multi-instance (`MAX_STATE_DIR` equivalent). Single instance.
- Stickers, video_notes - Max has none.

### 4.4 What to reuse verbatim from Telegram plugin

- `gate()` pairing / allowlist / policy logic
- `assertSendable()` state-dir exfiltration guard
- `assertAllowedChat()` outbound gate
- PID-file + orphan watchdog
- `chunk()` splitter
- Permission-reply regex intercept (`PERMISSION_REPLY_RE`)
- approved/ directory polling for pairing confirmation
- `.env` loader with 0o600 chmod

### 4.5 Pairing UX (identical to Telegram)

1. Owner DMs the Max bot for the first time.
2. Bot replies with a 6-char hex code.
3. Owner runs `/max:access pair <code>` in Claude Code.
4. Plugin adds the sender id to `allowFrom`.
5. Next DM flows into the session as a `<channel source="max" chat_id="..." user="..." ...>` block.

### 4.6 Rough effort

| Task | Estimate |
|------|----------|
| Fork directory, update package.json, swap grammy -> @maxhub/max-bot-api | 0.5 day |
| Adapt inbound handlers (text, photo, document, voice) | 1 day |
| Adapt outbound reply (incl. two-step upload flow) | 1 day |
| Strip reactions, adapt edit_message 24h guard | 0.5 day |
| Access skills + state dir + env loader | 0.5 day |
| End-to-end test with real token: DM, photo, edit, access pair | 1 day |
| README + ACCESS docs | 0.5 day |
| **Total** | ~5 days for one engineer |

---

## 5. Open questions

Things this research pass could NOT determine from public sources. Owner (or a closer look at the SDK source) needs to answer before implementation starts.

1. **Typing / chat_action equivalent.** Does Max's API expose a "bot is typing..." indicator? The Telegram plugin leans on this for UX. Not seen in the docs pages sampled. Check `@maxhub/max-bot-api` source.
2. **Complete list of `update_types`.** Docs cover `message_created`, `bot_started`, `message_callback`. Need the full set to decide which we subscribe to. Likely also `message_edited`, `message_removed`, `bot_added_to_chat`, `user_added`, etc.
3. **Group chat ID format and pairing.** Max group IDs differ from Telegram's `-100` prefix supergroups. Confirm format, confirm whether bots need to be "added" to a group before polling delivers group updates. Confirm privacy-mode analog (does Max filter non-mention group messages server-side like Telegram does?).
4. **File upload max size and flow.** vc.ru says 4 GB with resumable upload, but the official `POST /uploads` page does not confirm a ceiling. Is it a two-step (get URL, PUT file, reference by token) or one-step multipart? The SDK abstracts this but we need to know how to set `MAX_ATTACHMENT_BYTES`.
5. **Inbound photo/document download URL lifetime.** Telegram's `getFile` returns a URL valid for ~1h. Max's equivalent? Affects whether we must download eagerly (Telegram plugin does for photos).
6. **24-hour edit window - what does the API return after 24h?** Specific error code so `edit_message` can surface a clean message to the assistant.
7. **Long-polling stability for a personal bot.** Docs discourage production use. For an always-on single-user assistant that polls from a laptop, is this actually enforced or is it just a recommendation? If enforced (e.g. rate limits bite harder) we may need to move to webhook sooner than expected, which means public HTTPS - a real infra change.
8. **Publishing requirements.** Does an unpublished / private bot (never listed in Max catalog) still work for arbitrary DM pairing, or does the recent "verified RU legal entity" rule block this too? This is the single biggest go/no-go risk; owner should try to register a test bot and DM it before we commit to the work.
9. **Callback button payload size.** Telegram caps callback_data at 64 bytes. Max's limit was not captured. Affects how we pack `perm:allow:<id>` data.
10. **Permission-relay MCP capability.** Claude Code's `claude/channel/permission` experimental capability needs `callback_query`-equivalent inline keyboards. Confirm Max has this and that the SDK surfaces it cleanly. Not blocking v1 (we fall back to text "yes xxxxx") but blocks v2.

### Decision the owner needs to make

- Confirm the plugin should live under `claude-plugins-official/max/` as a fork, not under our own plugin namespace. (If we ship it ourselves under a different marketplace, the install UX and release path change.)
- Confirm v1 scope: DM-only, long-polling, no permission buttons. If any of those three need to change, the estimate doubles.
- Confirm we stay with Option A, and defer Option C to a later nassau/deskd milestone.

---

## Sources

- [MAX Bot API - docs root](https://dev.max.ru/docs-api)
- [MAX - setup / prepare guide](https://dev.max.ru/docs/chatbots/bots-coding/prepare)
- [MAX - GET /updates (long polling)](https://dev.max.ru/docs-api/methods/GET/updates)
- [MAX - POST /subscriptions (webhook requirements)](https://dev.max.ru/docs-api/methods/POST/subscriptions)
- [MAX JS/TS library docs](https://dev.max.ru/docs/chatbots/bots-coding/library/js)
- [Official TS SDK repo - @maxhub/max-bot-api](https://github.com/max-messenger/max-bot-api-client-ts)
- [Official Go SDK repo](https://github.com/max-messenger/max-bot-api-client-go)
- [Official Python SDK repo](https://github.com/max-messenger/max-botapi-python)
- [vc.ru - Max vs Telegram Bot API feature-by-feature comparison](https://vc.ru/telegram/2799410-sravnenie-max-bot-api-i-telegram-bot-api)
- [Habr - MAX изменил правила (verified legal entity requirement)](https://habr.com/ru/articles/951326/)
- [Habr - Max.ru Bot API: пишем бота обратной связи](https://habr.com/ru/articles/1016164/)
- [deskd - bus adapter pattern (reference only, do not modify)](https://github.com/kgatilin/deskd)
