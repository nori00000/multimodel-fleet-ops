# Multi-Model Fleet Ops

**A solo operator's system for commanding a fleet of AI models** — model routing × graceful degradation × failover/failback.

If you run multiple AI subscriptions (Claude, ChatGPT/Codex, budget model plans), you know the pattern:
top-model tokens refill on Monday, run dry by Thursday, and you limp through the rest of the week on
fallback models — or stop working entirely. This repo is a field-tested operating system for that problem.

## Core ideas

1. **The Exhaustion Ladder** — token exhaustion as a *designed state transition*, not an accident.
   Five rungs from "normal" through "conservation mode" and "succession" down to a self-organizing
   budget stack, with explicit failback rules (one rung at a time; first judgment after recovery is
   a spot-check of fallback-era output). See [docs/exhaustion-ladder.md](docs/exhaustion-ladder.md).
2. **Task-type routing** — the judgment model commands; execution, verification, and mechanical work
   go to type-matched lanes. Key insight: papers warn multi-agent systems cost ~15× tokens, but that
   assumes one vendor's budget — with multiple subscriptions, the only real bottleneck is your top
   model's quota. See [docs/routing.md](docs/routing.md).
3. **Cross-family critique** — work products are reviewed by a *different vendor's* model, always.
   Same-family models share blind spots (self-preference bias). We measured this with blind
   fault-injection: 2 rounds, 11 planted faults, 3 verifier models, 100% recall, zero false alarms —
   plus real propagated errors the gate caught that we hadn't planted. See [docs/fault-injection.md](docs/fault-injection.md).
4. **Night batch** — idle budget-model quota works while you sleep, behind a *capability boundary*
   (a no-tools agent: "available tools: none") rather than policy text. Web material is fetched
   deterministically by the runner and attached as data. See [docs/night-batch.md](docs/night-batch.md).

## What's here

- `docs/` — the four design documents above + [verified evidence list](docs/evidence.md)
- `scripts/` — working night-batch runner, quota-status session hook, quota collector (macOS)
- `agent/` — the no-tools opencode agent definition
- `examples/` — a sample night job + launchd template

Everything in this repo survived adversarial cross-model critique (77 findings converged across
two review rounds) — the system was built by the method it describes.

한국어 문서: [README.md](README.md)

## License

MIT
