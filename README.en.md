# Multi-Model Fleet Ops

**A practical playbook for routing work across multiple AI subscriptions** — model routing × graceful degradation × failover/failback, for solo operators.

If you run several AI subscriptions (Claude, ChatGPT/Codex, budget model plans), you may know the pattern:
a premium-model quota refills, gets exhausted early in the cycle, and the remaining work continues on
lower-capability fallback models. This repo documents a personal operating playbook and experimental
macOS scripts for that problem.

## Status and limitations (read first)

- **Experimental personal prototype.** macOS-only scripts; requires local opencode CLI and provider
  authentication. The quota collector depends on per-subscription usage CLIs (treat it as an example).
- The exhaustion ladder's descent/failback is **largely a manual operating policy** — the quota hook
  displays recommendations; it does not enforce a state machine.
- Night-batch outputs are **untrusted until human review**. The no-tools agent blocks tool-mediated
  side effects but does **not** protect output integrity against injected content.
- No OS sandbox, cost circuit breaker, or automated promotion gate yet (see per-doc backlogs).
- The fault-injection result (11/11 detection) is an observation from **two small, verification-explicit
  internal trials** — not a production recall estimate.

## Core ideas

1. **The Exhaustion Ladder** — token exhaustion as a *designed state transition*, not an accident.
   Five rungs from normal operation through conservation mode and succession down to a predefined
   budget-model fallback stack, with explicit failback rules (one rung at a time; the first judgment
   after recovery is a spot-check of outputs produced during fallback operation).
   See [docs/exhaustion-ladder.md](docs/exhaustion-ladder.md) (Korean).
2. **Task-type routing** — a higher-capability model handles planning and routing; execution,
   verification, and mechanical work go to type-matched lanes. With separate subscription quotas,
   the immediate constraint tends to shift from aggregate tokens toward the scarce judgment-model
   quota — though latency, review capacity, and integration costs still apply.
   See [docs/routing.md](docs/routing.md).
3. **Cross-family review (an operational heuristic)** — for oracle-free review of work products we
   prefer a different vendor's model, motivated by self-preference-bias research. Our fault-injection
   exercise tested *fact verification with an oracle* (where family didn't matter), not this
   hypothesis itself. See [docs/fault-injection.md](docs/fault-injection.md).
4. **Night batch** — idle budget-model quota works while you sleep, behind a capability boundary
   (a tools-disabled agent) rather than policy text. Web material is fetched by the non-LLM runner
   (https-only) and attached as data. See [docs/night-batch.md](docs/night-batch.md).

## What's here

- `docs/` — design documents + [reference list](docs/evidence.md) (link-existence checked)
- `scripts/` — night-batch runner, quota-status session hook, quota collector (macOS)
- `agent/` — the tools-disabled opencode agent definition (install to `~/.config/opencode/agent/`)
- `examples/` — a sample night job + launchd template; see README.md for install steps

The current draft was revised after two cross-model adversarial review rounds; unresolved controls
are listed in the backlogs.

한국어 문서: [README.md](README.md)

## License

MIT
