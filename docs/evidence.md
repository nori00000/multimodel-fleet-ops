# 참고 문헌 — 링크 실재 확인 완료

이 목록의 모든 출처는 6개 이기종 AI 레인의 병렬 조사 후, 스크립트(HTTP 상태+제목 대조)로 **링크 실재를 확인**한 것이다.
링크 실재 확인은 "출처가 존재함"의 확인이지 "요약이 본문을 정확히 반영함"의 보증이 아니다 — 인용 요약의 수치는 각자 원문 대조를 권한다.
수집 방법과 환각률 실측은 [fault-injection.md](fault-injection.md) 참조.

## 병렬화가 언제 돕고 언제 해치나

- [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) — Anthropic 2025. 오케스트레이터-워커가 단일 에이전트 대비 +90.2%(내부 평가), 단 토큰 ~15배·breadth-first 전용.
- [When to use multi-agent systems (and when not to)](https://claude.com/blog/building-multi-agent-systems-when-and-how-to-use-them) — Anthropic 2026. 도움 3조건 외엔 조정 비용이 이득 초과.
- [Don't Build Multi-Agents](https://cognition.com/blog/dont-build-multi-agents) — Cognition 2025. 컨텍스트 공유 없는 병렬 서브에이전트 반대 정론.
- [How and when to build multi-agent systems](https://www.langchain.com/blog/how-and-when-to-build-multi-agent-systems) — LangChain 2025. 병렬 읽기=fan-out OK, 결합 쓰기=단일 스레드.
- [Towards a Science of Scaling Agent Systems](https://arxiv.org/abs/2512.08296) — 2025. 260구성 통제 실험: 논문의 trace 수준 오류 증폭 지표로 독립 병렬 17.2 vs 중앙집중 4.4 (아키텍처·난이도 조건부).
- [Capable language models can outgrow the benefits of collaboration](https://www.nature.com/articles/s42256-026-01268-y) — Nature MI 2026 (위 arXiv의 게재본). 실험 도메인 내에서 단일 에이전트 베이스라인 ~45% 이상이면 멀티에이전트 이득 0~음수 — 저자들도 보편 법칙이 아닌 실용적 선택 규칙으로 제시.
- [Do More Agents Help?](https://arxiv.org/abs/2606.05670) — 2026. 프로토콜 정렬 평가에서 고정 MAS 6개 중 5개가 단일 에이전트에 열세.

## 이기종 앙상블 — 찬반

- [Mixture-of-Agents](https://arxiv.org/abs/2406.04692) — ICLR 2025. 이기종 계층 앙상블 AlpacaEval 2.0 65.1% > GPT-4o 57.5%.
- [Rethinking Mixture-of-Agents (Self-MoA)](https://arxiv.org/abs/2502.00674) — 2025. 반증: 최강 단일 모델 자기샘플링이 혼합을 +6.6% 상회.
- [ReConcile](https://arxiv.org/abs/2309.13007) — ACL 2024. 이기종 원탁 합의 최대 +11.4%, '다른 모델' 다양성이 핵심.
- [Stop Overvaluing Multi-Agent Debate](https://arxiv.org/abs/2502.08788) — 2025. MAD는 기본선을 못 이기지만 모델 이기종성은 MAD를 개선.
- [DeePEn](https://proceedings.neurips.cc/paper_files/paper/2024/file/d8a6eb79f8ccaacbe7198a5caf3a0323-Paper-Conference.pdf) — NeurIPS 2024. 분포 수준 이기종 융합.
- 서베이: [LLM Ensemble](https://arxiv.org/abs/2502.18036) · [Multi-Agent Collaboration Mechanisms](https://arxiv.org/abs/2501.06322)

## 토론·크리틱의 실효

- [Multiagent Debate](https://arxiv.org/abs/2305.14325) — ICML 2024. 토론이 수학·사실성 개선, 단 오답 합의 가능(합의≠검증).
- [Should we be going MAD?](https://proceedings.mlr.press/v235/smit24a.html) — ICML 2024. 토론이 self-consistency를 신뢰성 있게 못 이김.
- [More Agents Is All You Need](https://arxiv.org/abs/2402.05120) — 2024. 샘플링+투표 — 모든 협업 구조의 등비용 기본선.
- [Encouraging Divergent Thinking](https://aclanthology.org/2024.emnlp-main.992/) — EMNLP 2024. 토론자/심판 역할 분리 근거.
- [LLMs Cannot Self-Correct Reasoning Yet](https://arxiv.org/abs/2310.01798) — 2023. 외부 근거 없는 자기교정은 실패·퇴행.

## 심판(judge) 신뢰성

- [Judging LLM-as-a-Judge (MT-Bench)](https://arxiv.org/abs/2306.05685) — NeurIPS 2023. 강한 심판 인간 합의 >80%, 위치·장황·자기선호 편향 문서화.
- [Replacing Judges with Juries (PoLL)](https://arxiv.org/abs/2404.18796) — 2024. 시험된 평가 설정들에서 이기종 소형 심판 패널이 단일 대형 심판을 상회, 7배 이상 저렴.
- [Judging the Judges](https://aclanthology.org/2025.ijcnlp-long.18/) — IJCNLP-AACL 2025. 15심판 15만+ 평가: 위치 편향 실재.
- [Self-Preference Bias](https://arxiv.org/abs/2410.21819) — 2024. 심판의 자기 출력 선호 — 교차 벤더 검증의 정량 근거.
- [ChatEval](https://arxiv.org/abs/2308.07201) — 2023. 다중 에이전트 심판단.

## 실패 모드·운영

- [Why Do Multi-Agent LLM Systems Fail? (MAST)](https://arxiv.org/abs/2503.13657) — NeurIPS 2025. 1,600+ 트레이스 분석에서 분류된 실패의 41.8%가 사양/설계 범주 — 오케스트레이션 설계 개선의 여지가 크다는 시사.
- [Conductor: Deterministic orchestration](https://opensource.microsoft.com/blog/2026/05/14/conductor-deterministic-orchestration-for-multi-agent-ai-workflows/) — Microsoft 2026. LLM을 런타임 오케스트레이터로 쓰지 말 것.
- [Magentic-One](https://arxiv.org/abs/2411.04468) — MS Research 2024. 중앙 오케스트레이터+전문 워커.
- [A practical guide to building agents](https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf) — OpenAI 2025. manager vs decentralized 패턴.
