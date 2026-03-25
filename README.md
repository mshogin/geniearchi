# GenieArchi

AI agent ecosystem for architecture quality, cost optimization, and safety control.

## Tools

| Tool | Role | Repo |
|------|------|------|
| **archlint** | Code architecture quality gate | [mshogin/archlint](https://github.com/mshogin/archlint) |
| **promptlint** | Prompt complexity scoring, model routing | [mikeshogin/promptlint](https://github.com/mikeshogin/promptlint) |
| **costlint** | Token cost analysis, cache metrics, A/B tests | [mikeshogin/costlint](https://github.com/mikeshogin/costlint) |
| **seclint** | Content safety, age ratings | [mikeshogin/seclint](https://github.com/mikeshogin/seclint) |
| **sitegen** | Static site generation | [mikeshogin/sitegen](https://github.com/mikeshogin/sitegen) |

## Pipeline

```
prompt -> seclint (safe?) -> promptlint (route) -> agent -> archlint (quality) -> costlint (cost)
```

## Key Numbers

- 58% cost savings through intelligent model routing
- <10ms per analysis (no LLM, pure metrics)
- 0 API surface (static sites, CLI tools)
- All Go + Rust, single binary (archlint-rs)

## Orchestration

Works with [myhome](https://github.com/kgatilin/myhome) for agent lifecycle management.

## For AI Agents

See [FOR_AGENTS.md](FOR_AGENTS.md) in each repository.

## Website

- [archlint.ru](https://archlint.ru) - product site
- [ECOSYSTEM.md](ECOSYSTEM.md) - detailed integration map
