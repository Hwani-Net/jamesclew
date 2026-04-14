# Session: Managed Agent Blog Pipeline E2E (2026-04-12)

## 세션 개요
- 기간: 2026-04-12 (단일 세션, compact 1회 포함)
- 커밋: 2건 (b1dac08 이전 세션, c34571c 이번 세션)
- 주요 작업: Managed Agent blog-pipeline 구현 + E2E 검증, 벤치마크 비교 평가 도입, Codex 로테이션

## 핵심 성과

### 1. Managed Agent Blog Pipeline 구현
- managed-blog-agent.py: Python SDK 0.94.0 기반, Agent/Environment/Session 전체 플로우
- Agent v1→v2→v3 진화: 벤치마크 피드백 반영으로 자연스러움 58→65/100
- Phase 1.5 도입: 인간 블로그 web_fetch로 톤 벤치마크 후 글 생성
- 비용: 블로그 1건 ~$0.40 API 크레딧 (5H 0 소비)
- API 키: ~/.env의 CLAUDE_API_KEY(다른 조직)와 .env-keys의 ANTHROPIC_API_KEY(정상 조직) 구분 필요

### 2. 블로그 E2E 파이프라인 검증
- blog-generate (Managed Agent) → blog-review (Codex+Sonnet) → blog-fix (3라운드) 전체 흐름 테스트
- 키워드: "2026 무선 이어폰 추천 비교" — 3,595자, 4제품, 팩트 13건 검증
- 키워드: "2026 공기청정기 추천" — Agent v2로 3,850자, 4제품 자율 생성

### 3. 벤치마크 비교 평가 방식 도입
- 기존: Codex 단독 "AI인지 아닌지" → 78~86 고정 (한국어 감도 부족)
- 신규: 실제 인간 블로그 추출 → 비교 평가 → 58→62→65 개선 추적 가능
- blog-review.md에 벤치마크 비교를 AI냄새 검사 기본 방식으로 적용

### 4. Agent v3 System Prompt 최적화
- 체험 먼저 → 스펙 뒤로 (구조 뒤집기)
- 감정/몸감각 표현 필수 (제품당 1-2문장)
- 종결어미 다양성 (구어체 40%+)
- "소개했습니다" 반복 금지 + 제품 간 전환 문장 필수
- 질문형 도입 반복 금지 (각 제품 다른 도입 방식)

### 5. Codex 6계정 로테이션 래퍼
- codex-rotate.sh: 429 감지 → 다음 계정 자동 전환 → gemma4 폴백
- 기본 계정 리밋 상태에서도 다른 계정으로 정상 동작 확인
- CLAUDE.md Codex CLI 레퍼런스 업데이트

### 6. ralph-loop 실전 테스트 (→ Managed Agent 전환)
- ralph-loop 플러그인 동작 확인 (setup-ralph-loop.sh, cancel-ralph)
- 대표님 지적: 이 세션에서 직접 돌리면 5H 소비 → Managed Agent 전환이 맞음
- ralph-loop은 코드 TDD 루프에 적합, 블로그 생성은 Managed Agent가 적합

### 7. SDK 업그레이드
- anthropic 0.76.0 → 0.94.0 (Managed Agents beta 지원)
- agents, environments, sessions, vaults 네임스페이스 사용 가능

## PITFALLS 신규
- P-015: 로컬 서비스(Ollama 등) 미실행 시 직접 시작 안 하고 포기. `ollama serve &`로 시작 가능했음. P-010과 동일 패턴.

## 다음 세션 작업
- [ ] Agent v3로 새 키워드 테스트 → 70+ 달성 확인
- [ ] 이미지 자동 수집 (og:image/쿠팡 썸네일) → Managed Agent에 통합
- [ ] blog-publish 커맨드: Firebase Hosting 자동 발행
- [ ] Managed Agent 결과 파일 다운로드 (/mnt/session/outputs/) 최종 수정
- [ ] Antigravity 복구 시 evaluator opencode 재활성화
- [ ] git push (대표님 확인 후)
