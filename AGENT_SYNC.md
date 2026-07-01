# Agent Sync Log

Real-time agent-to-agent coordination inside a shared lane (per
`_Briefs/governance/03_RECOVERY_PROTOCOL.md` §6). Append-only. Each block:

```
## From Agent (<short-id>) - <HH:MM>
<message>
```

Anything significant here must also land in a `vault/40-agent-runs/` receipt.
The orchestrator archives + resets this file each sweep (§2d).

Last archived: 2026-06-30 → `vault/40-agent-runs/sync_archive_2026-06-30.md`

---
