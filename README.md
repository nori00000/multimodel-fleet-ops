# Multi-Model Fleet Ops (멀티모델 플릿 옵스)

**한 사람이 지휘하는 AI 함대 운영 체계** — model routing × graceful degradation × failover/failback for solo AI operations.

여러 AI 구독(Claude, ChatGPT/Codex, 저가 모델 플랜)을 쓰는 1인 운영자의 공통 문제:
주초에 리필된 상위 모델 토큰을 며칠 만에 소진하고, 남은 기간을 하위 모델로 버티다, 전면 정지에 이르는 패턴.
이 레포는 그 문제를 **운영 체계(ops)** 로 푼 실전 기록이자 재사용 가능한 설계다.

## 핵심 구성

```
선제 배분 ─ 낮: 판단 모델 지휘 + 병렬 외부 레인 실행
           └ 밤: 야간 배치 (유휴 저가 쿼터 무인 소화)
안전망: 소진 사다리 5단 (graceful degradation + failback)
검증:   교차 가족 크리틱 (다른 벤더 모델이 검증) — fault-injection으로 실측 검증됨
```

| 문서 | 내용 |
|---|---|
| [소진 사다리](docs/exhaustion-ladder.md) | 5단 단계적 성능 저하 + 복귀 규칙 (핵심 메커니즘) |
| [라우팅](docs/routing.md) | 과제 유형 → 모델 레인 배정, 검증 2표면 하드 룰 |
| [Fault Injection](docs/fault-injection.md) | 검증 게이트를 가짜 결함으로 실측한 2라운드 실험 |
| [야간 배치](docs/night-batch.md) | 수면 시간에 유휴 쿼터로 일하는 무인 배치 (능력 경계 설계) |

## 스크립트

| 파일 | 역할 |
|---|---|
| [`scripts/night-batch-runner.sh`](scripts/night-batch-runner.sh) | 야간 배치 러너 — 파일 큐, 무도구 에이전트 실행, 웹자료 대행 수집, 원자 커밋 |
| [`scripts/quota-status.sh`](scripts/quota-status.sh) | 세션 시작 시 쿼터 상태 표시 훅 (캐시 기반 비차단) |
| [`scripts/quota-refresh.sh`](scripts/quota-refresh.sh) | 쿼터 수집기 (소스별 실패 기록, 원자 락) |
| [`agent/night-batch.md`](agent/night-batch.md) | opencode 무도구 에이전트 정의 ("available tools: none") |

> 의존성: 쿼터 스크립트는 각 구독의 사용량 조회 CLI에 의존한다(환경별 상이 — 코드 내 주석 참조).
> 스크립트는 macOS 기준(`timeout` 부재로 perl alarm 사용, `date -v` 문법).

## 설계 원칙 (요약)

1. **Silent/Loud 리트머스** — "미묘하게 틀리면 뭔가가 잡아주나?"로 과제를 분류하고, 의심(검증 비용)은 아무도 안 지켜보는 곳에만 쓴다.
2. **판단과 실행의 분리** — 최상위 모델은 판단만, 실행·기계 작업은 유형별 레인으로. 절약은 소진 후 대응이 아니라 리필 1일차부터.
3. **교차 가족 검증** — 작업물 크리틱은 반드시 다른 벤더 모델에게. 같은 가족은 같은 맹점을 공유한다 (자기선호 편향).
4. **능력 경계 > 문서 규율** — 무인 실행의 안전은 "하지 말라"는 규칙이 아니라 "할 수 없는" 도구 차단으로.
5. **모든 정책은 적대 크리틱을 통과한다** — 이 레포의 설계 자체가 교차 모델 크리틱(총 77건 지적)을 수렴한 산물이다.

## 근거

설계 결정의 배경이 된 검증 문헌 (전체 목록과 검증 방법은 [routing.md](docs/routing.md) 참조):
[Anthropic multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) ·
[Why Do Multi-Agent LLM Systems Fail? (MAST)](https://arxiv.org/abs/2503.13657) ·
[Replacing Judges with Juries (PoLL)](https://arxiv.org/abs/2404.18796) ·
[Capable language models can outgrow the benefits of collaboration](https://www.nature.com/articles/s42256-026-01268-y) ·
[Don't Build Multi-Agents (Cognition)](https://cognition.com/blog/dont-build-multi-agents)

## License

MIT
