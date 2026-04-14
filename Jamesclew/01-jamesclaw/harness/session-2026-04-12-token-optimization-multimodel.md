# Session: 토큰 최적화 + 멀티모델 오케스트레이션 (2026-04-12)

## 세션 개요
- 기간: 2026-04-10 ~ 2026-04-12 (3일, 복수 compact 포함)
- 커밋: ~25건
- 주요 작업: 토큰 절감 전략 전면 재설계, 멀티모델 구조, Copilot/GPT 통합, ralph-loop 도입

## 핵심 성과

### 1. Subagent-First → Multi-Model Orchestration
- advisorModel 폐기 (존재하지 않는 settings.json 키였음)
- Subagent-First Architecture 도입 → Advisor Loop 추가
- Multi-Model Orchestration: Opus + Sonnet + Codex + GPT-4.1 + Gemma4
- 작업→모델 라우팅 테이블

### 2. 5H Limit 전략 근본 수정
- 5H 리밋이 모든 모델 공통 (Opus만이 아님) — 핵심 발견
- 7D는 Opus/Sonnet 별도 풀
- 외부 모델만이 5H + 7D 양쪽 0 소비
- 위임 우선순위: 외부(5H 0) > Sonnet(5H 느림) > Opus(5H 빠름)
- 80%+ 비상 모드: Opus 2문장 제한 + Sonnet 위임

### 3. GitHub Copilot Pro ($10) + copilot-api 프록시
- copilot-api 설치 (npm @jeffreycao/copilot-api)
- GPT-4.1/4o/5-mini 무제한 (0x multiplier)
- Anthropic API 호환 확인 (/v1/messages 동작)
- GPT-4.1 Claude Code 메인 모델 테스트 성공
- 제약 발견: Opus/Sonnet /model 전환 시 에러, Haiku만 서브에이전트 가능
- GPT-4.1 오케스트레이터 부적합 판정 (Opus 60-65%, 같은 에러 4회 반복)
- 최종 포지션: Codex CLI 상위 대안 (벌크/반복 전용)

### 4. 품질 보장 체계
- 이중 검토 필수: Sonnet/Haiku 결과 → 외부 모델 교차 검토
- Opus 어드바이저 상시: 최종 판단/품질 승인은 항상 Opus
- 우선순위 공식: 긴급도+수익+대기+ROI-리스크 (0~9점)

### 5. 문서-구현 갭 감사 + 수정
- 14항목 교차 검증 → 6개 RED FLAG 수정
- curation.ts 소스 부재 → 복사
- change-tracker 문서 불일치 (15→50) → 수정
- cost-tracker bc→python (Windows 호환)
- Design Doc Sync hook 추가
- step7 외부 모델 시그니처 검증 추가
- verify-deploy.sh expect MCP 통합

### 6. 다른 프로젝트 호환성
- D:/jamesclew 하드코딩 경로 제거 (pipeline-run, qa, evaluator, design_rubric)
- 프로젝트 메모리 → 글로벌 CLAUDE.md 승격 (Identity, Quality Standards, 12→45 원칙)
- Prerequisites 섹션 추가 (환경변수, CLI, MCP 목록)
- enforce-build-transition.sh 프로젝트별 state 파일 격리 (해시)
- 외부 모델 전멸 시 graceful degradation 규칙

### 7. Identity + Language 강화
- "천재형 참모" + 2수 앞 예측 사고방식
- 합니다체 격식 존댓말 명시, 해요체/반말 금지
- 유머 톤 추가 ("유능한 참모의 위트")
- 확신 부족 시 외부 모델 자율 검증

### 8. 토큰 절약 52가지 팁 적용
- .claudeignore 생성
- thinking.budget_tokens: 10000
- read-once.sh hook (중복 읽기 경고)
- log-filter.sh hook (50줄+ 로그 필터)
- ccusage 설치
- 병렬 실행/재읽기 금지/에러만 확인 규칙

### 9. ralph-loop 도입
- 플러그인 활성화 + Windows 패치
- 매뉴얼 작성 (docs/ralph-loop-manual.md)
- 팩트체크: 캐슬AI 영상 vs 공식 문서 교차 검증
- 활용 구조: ralph-loop(생성) → pipeline-run(검증) → 외부 모델(검수)

### 10. Managed Agents 검증
- Agent/Environment/Session 생성 성공
- API 크레딧 별도 필요 (Max 플랜과 독립)
- $0.08/h + 토큰 = 비동기 자동화에 적합
- 블로그 벌크 생성/크롤링 등 장시간 작업 분리 가능

### 11. expect MCP 연결 + NLM 연동
- expect MCP 세션 재시작으로 해결 (P-013)
- NotebookLM MCP 등록 + CLI 방식 확인
- NLM에 Claude Code Official Docs + Harness Blueprint 노트북 ID 명시
- ultraplan CLI 자동완성에서 발견 (NLM에 없었음)

### 12. Antigravity 차단 대응
- Google ToS 자동차단 (전 계정)
- evaluator.sh: opencode → gemma4_local → copilot_gpt 교체
- 5단계 로테이션: codex → copilot → openrouter_free → gemma4 → codex_backoff

### 13. Evidence-First hook 오탐 수정
- 5KB → 15KB 윈도우 확대
- git commit 해시, 배포 완료 등 인라인 증거 패턴 추가

## PITFALLS 신규
- P-013: expect MCP 세션 내 hot-reload 불가 (CLI 대안으로 해결)
- P-014: Claude Code 기능을 추측으로 판단 (ultraplan 사례)

## 다음 세션 작업
- [ ] Managed Agent로 blog-pipeline 이전 구현
- [ ] ralph-loop 실전 테스트 (블로그 1건 생성)
- [ ] MoneyAgent 세션 반말 패턴 — 새 세션에서 합니다체 준수 확인
- [ ] explore-router 5/12/25 임계값 실전 효과 검증
- [ ] Antigravity 복구 시 evaluator opencode 재활성화
