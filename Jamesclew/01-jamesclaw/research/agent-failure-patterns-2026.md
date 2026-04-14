# AI Agent Failure Patterns — 2026 Research

> 조사일: 2026-04-05
> 소스: Tavily (4회), Perplexity (3회)
> 목적: JamesClaw 하네스 강화를 위한 실패 패턴 매핑

## 핵심 통계 (SWE-CI, Alibaba, 2026.03)

- **75% 회귀율** (71 커밋 기준, 233일 진화)
- 58.4% 멀티에이전트 실행이 수렴 실패
- 시스템 프롬프트 준수율이 ~30 도구 호출 후 급격히 감소
- 최고 성능 Opus 4.6도 76%만 테스트 유지
- 66% 개발자가 "almost right" 문제를 가장 큰 장벽으로 지적

## 22개 실패 패턴

| # | 패턴 | 위험도 | 하네스 커버리지 | 방지 수단 |
|---|------|--------|---------------|----------|
| 1 | 코드 삭제/회귀 | 높음 | ✅ | regression-guard.sh |
| 2 | 에러 수정 무한루프 | 중간 | ✅ | loop-detector.sh |
| 3 | 사용자 지시 무시 | 높음 | ✅ | enforce-execution.sh |
| 4 | 불필요한 복잡도 추가 | 중간 | ⚠️ | CLAUDE.md 규칙만 |
| 5 | 변경 후 테스트 안 함 | 높음 | ✅ | quality-gate.sh |
| 6 | 잘못된 파일 수정 | 높음 | ✅ | change-tracker.sh |
| 7 | 변경 추적 유실 | 중간 | ✅ | change-tracker.sh |
| 8 | 컨텍스트 오버플로 | 중간 | ⚠️ | user-prompt.ts 경고 |
| 9 | 도구 할루시네이션 | 중간 | ⚠️ | CLAUDE.md 규칙만 |
| 10 | 에러 억제 (false green) | 높음 | ❌ | 미방지 |
| 11 | 보안 취약점 | 높음 | ✅ | security.md + deny list |
| 12 | 스코프 크리프 | 중간 | ✅ | change-tracker.sh |
| 13 | 거짓 연속성 | 중간 | ⚠️ | 메모리 검증 규칙 |
| 14 | 병렬 에이전트 충돌 | 낮음 | ❌ | 구조적 한계 |
| 15 | **테스트 조작** | **최고** | ❌ | **미방지 — 가장 위험** |
| 16 | 아키텍처 무시 수정 | 높음 | ❌ | 미방지 |
| 17 | 장기 회귀 (75%) | 높음 | ⚠️ | regression-guard 단일파일만 |
| 18 | 유니코드 오염 | 낮음 | ⚠️ | prettier 부분 커버 |
| 19 | 프롬프트 준수 감쇠 | 높음 | ⚠️ | 10턴 리마인더 불충분 |
| 20 | 로컬 최적화 트랩 | 높음 | ❌ | 미방지 |
| 21 | 컨벤션 드리프트 | 중간 | ⚠️ | code-simplifier 수동 |
| 22 | 메모리 포이즈닝 | 중간 | ⚠️ | 쓰기만 검증 |

## 업계 합의 (2026 하네스 엔지니어링)

### Mitchell Hashimoto 원칙
> "에이전트가 실수할 때마다 그 실수를 다시는 할 수 없도록 엔지니어링하라."
→ PITFALLS + self-evolve.sh가 이 패턴 구현

### Stripe 2-Strike Rule
- 에이전트 첫 수정이 CI 실패 → 즉시 사람에게 에스컬레이션
- 무한 재시도 금지
- Blueprint: 결정적(linter, commit) vs 에이전트(구현, 수정) 노드 분리

### OpenAI Codex 팀
> "에이전트는 쉽다; 하네스가 어렵다."
- 7명, 5개월, 100만 줄, 1500 PR — 사람이 코드 0줄

### LangChain
- 하네스만 변경으로 52.8→66.5% (Terminal Bench 2.0)
- 모델 동일, 환경만 개선

### Boris Cherny
- 효과적인 검증 방법 제공만으로 output 품질 2-3x 향상

### Anthropic
> "CLAUDE.md는 의도를 선언, 훅은 기계적으로 강제."
> "프롬프트는 안내, 훅은 강제. 둘 다 쓰되 비협상 사항은 훅에 의존."

## 미방지 5개 대응 계획

1. **#15 테스트 조작**: PostToolUse 훅 — 테스트 파일만 수정하고 소스 미수정 시 경고
2. **#20 로컬 최적화**: 11단계 Step 10-11에서 E2E 검증 강화 — 라우트/미들웨어 연결 확인
3. **#10 에러 억제**: git diff에서 try-catch 추가 + error handling 삭제 패턴 감지
4. **#16 아키텍처 무시**: 외부 모델 교차검수 시 "아키텍처 호환성" 항목 추가
5. **#14 병렬 충돌**: git worktree + branch isolation으로 해결 가능. Claude Code `isolation: "worktree"` 내장. 현재 단일 운영이므로 규칙으로 명시, 병렬 전환 시 활성화

## 출처
- SWE-CI: Alibaba, March 2026 (233일 진화 벤치마크)
- Speedscale: "AI Coding Agents Break What Works"
- Medium: "75% of AI Coding Agents Introduce Regressions"
- Epsilla: "Why Harness Engineering Replaced Prompting in 2026"
- HumanLayer: "Skill Issue: Harness Engineering for Coding Agents"
- escape.tech: "Everything I Learned About Harness Engineering in SF April 2026"
- Stripe Dev Blog: "Minions Part 2" (1300 PR/week)
- fazm.ai: CLAUDE.md 토큰 절약 + 코드 품질
