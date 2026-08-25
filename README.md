# Multi-Model Fleet Ops (멀티모델 플릿 옵스)

**여러 AI 구독을 한 사람이 운영하기 위한 실전 플레이북** — model routing × graceful degradation × failover/failback.

여러 AI 구독(Claude, ChatGPT/Codex, 저가 모델 플랜)을 쓰는 1인 운영자의 공통 문제:
상위 모델 쿼터가 리필 초반에 소진되고, 남은 기간을 하위 모델로 이어가는 패턴.
이 레포는 그 문제를 다루는 **개인 운영 플레이북과 실험적 macOS 스크립트**를 공개한 것이다.

## 상태와 한계 (먼저 읽을 것)

- **실험적 개인 프로토타입**이다. macOS 전용(`date -v`, perl alarm), opencode CLI와 각 구독의 인증 설정이 선행돼야 한다.
- 소진 사다리의 하강·복귀는 **상당 부분 수동 운영 규율**이다 — 쿼터 훅은 권고를 표시할 뿐 상태 머신을 강제하지 않는다.
- 야간 배치 산출물은 **사람 검수 전까지 미검토(untrusted) 상태**다. 무도구 에이전트는 도구 매개 부작용을 차단하지만 **출력 내용의 무결성까지 보장하지 않는다**.
- OS 샌드박스·비용 서킷브레이커·자동 승격 게이트는 아직 없다 (각 문서의 백로그 참조).
- fault-injection 결과(11/11)는 **검증 지시가 명시된 소규모 내부 실험의 관측치**이지, 프로덕션 검출률 추정이 아니다.

## 핵심 구성

```
선제 배분 ─ 낮: 판단 모델 + 병렬 외부 레인
           └ 밤: 야간 배치 (유휴 저가 쿼터 소화)
안전망: 소진 사다리 5단 (사전 정의된 폴백 스택 + 복귀 규칙)
검증:   교차 가족 크리틱 + fault-injection 실측
```

| 문서 | 내용 |
|---|---|
| [소진 사다리](docs/exhaustion-ladder.md) | 5단 단계적 성능 저하 + 복귀 규칙 (핵심 메커니즘) |
| [라우팅](docs/routing.md) | 과제 유형 → 모델 레인 배정, 검증 2표면 구분 |
| [Fault Injection](docs/fault-injection.md) | 검증 게이트를 가짜 결함으로 실측한 2라운드 실험 |
| [야간 배치](docs/night-batch.md) | 수면 시간에 유휴 쿼터로 일하는 무인 배치 |
| [근거 문헌](docs/evidence.md) | 링크 실재 확인을 거친 참고 문헌 목록 |

## 스크립트 (설치 방법 포함)

| 파일 | 역할 |
|---|---|
| [`scripts/night-batch-runner.sh`](scripts/night-batch-runner.sh) | 야간 배치 러너 — 파일 큐, 무도구 에이전트 실행, 웹자료 대행 수집(https 전용), 같은 파일시스템 원자 rename 승격 |
| [`scripts/quota-status.sh`](scripts/quota-status.sh) | 세션 시작 시 쿼터 상태 표시 (캐시 기반 비차단) |
| [`scripts/quota-refresh.sh`](scripts/quota-refresh.sh) | 쿼터 수집기 — **각 구독의 사용량 조회 CLI에 의존** (개인 환경용 예시로 볼 것) |
| [`agent/night-batch.md`](agent/night-batch.md) | opencode 무도구 에이전트 정의 |

야간 배치 설치 (macOS):
```bash
cp scripts/night-batch-runner.sh ~/bin/
cp agent/night-batch.md ~/.config/opencode/agent/    # opencode가 에이전트를 찾는 경로
# examples/com.example.night-batch.plist의 YOUR_HOME을 수정해 ~/Library/LaunchAgents/에 복사 후 launchctl load
# 스모크 테스트: examples/night-job-example.md를 ~/night-batch/queue/에 넣고 NIGHT_BATCH_FORCE=1 ~/bin/night-batch-runner.sh
```

## 설계 원칙 (요약)

1. **Silent/Loud 리트머스** — "미묘하게 틀리면 뭔가가 잡아주나?"로 과제를 분류하고, 의심(검증 비용)은 아무도 안 지켜보는 곳에만 쓴다.
2. **판단과 실행의 분리** — 판단 밀도가 높은 일만 최상위 모델에, 실행·기계 작업은 유형별 레인으로. 절약은 소진 후 대응이 아니라 리필 1일차부터.
3. **교차 가족 검증 (운영 휴리스틱)** — 오라클 없는 작업물 리뷰는 다른 벤더 모델을 선호한다. 자기선호 편향 연구에서 동기를 얻은 운영상 헤지이며, 만능 법칙은 아니다 ([routing.md](docs/routing.md)의 2표면 구분 참조).
4. **능력 경계 > 문서 규율** — 무인 실행의 안전은 "하지 말라"는 규칙이 아니라 도구 차단으로. 단 이는 부작용 차단이지 출력 무결성 보장이 아니다.
5. **문서와 코드는 교차 모델 크리틱을 거친다** — 이 레포의 현재 판은 두 차례의 교차 모델 리뷰 라운드 후 개정된 것이며, 미해결 통제는 각 문서의 백로그에 명시돼 있다.

## License

MIT — 영문 소개: [README.en.md](README.en.md)
