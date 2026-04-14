# Session Summary — 2026-04-05 하네스 v4 종합 엔지니어링

## 세션 개요
- 기간: 2026-04-05 전일 (매우 긴 세션)
- 커밋: 29개
- 컨텍스트: ~20% (1M 기준)
- 주요 작업: 하네스 엔지니어링 종합 강화 + 블로그 확장 + MCP 재구성

## 핵심 성과

### 1. 블로그 확장 (9→10편)
- 공기청정기 (생활용품 카테고리 첫 글)
- 마사지건 (뷰티/건강 카테고리 첫 글)
- 파이프라인 실전 테스트 → crossReview 텍스트 제한 버그 수정 (P-011)

### 2. AI 에이전트 실패 패턴 22개 매핑
- Tavily/Perplexity 3도구 조사 (4회 호출)
- SWE-CI 벤치마크: 75% 회귀율, 30회 후 준수 감쇠
- 업계 합의: Mitchell Hashimoto, Stripe 2-strike, LangChain 하네스
- 옵시디언 영구 저장: agent-failure-patterns-2026.md

### 3. 신규 훅 4개
- regression-guard.sh: 회귀 감지 + 에러 억제 감지 (#1, #10)
- change-tracker.sh: 변경 추적 + 스코프 크리프 감지 (#6, #7, #12)
- test-manipulation-guard.sh: 테스트 조작 감지 (#15)
- Notification: idle_prompt/permission_prompt 알림음

### 4. 품질루프 3→5패스 확장
- Pass 4: UX/접근성 (버튼·링크·네비·폼·a11y)
- Pass 5: 사용자 페인포인트 (사용자가 막히는 곳)
- 에러 억제/로컬 최적화/아키텍처 호환성 감지 규칙 추가

### 5. MCP 전면 재구성
- lazy-mcp 제거 → Perplexity/Tavily/desktop-control/NotebookLM 직접 등록
- NotebookLM: TypeScript → Python MCP로 교체 (쿠키 변환 버그 회피)
- korean-law: 온디맨드 전환 (89도구 33K토큰 절약)

### 6. 전역화
- PITFALLS.md → ~/.claude/ (모든 프로젝트 공유)
- docs/adr/ → ~/.claude/docs/adr/ (전역)
- deploy.sh에 PITFALLS/ADR 배포 추가

### 7. Bun→Node 전환 (크리티컬 버그 수정)
- user-prompt.ts, session-start.ts, curation.ts: Bun.stdin.text() → process.stdin
- settings.json: bun → node --experimental-strip-types (5곳)
- 원인: bun이 npx 캐시 경로에 있어 Claude Code가 못 찾음
- 영향: turn_counter, context_pct, 마일스톤 주입, 리마인더 모두 불발이었음

### 8. 슬래시 커맨드
- /pipeline-install: 11단계 파이프라인 프로젝트 설치
- /prd: 13섹션 PRD 생성 (페인포인트/벤치마킹/JTBD/리스크 포함)
- 플러그인 한글화 (marketplace 폴더 수정)

### 9. API 키 중앙화
- ~/.env 생성 (단일 소스)
- .bashrc에 자동 로드 등록
- lazy-mcp/servers.json, .claude.json에서 하드코딩 키 제거

### 10. BiteLog 프로젝트 준비
- 폴더명: Fishing → BiteLog
- package.json name: fish-log → bite-log
- CLAUDE.md: 11단계 + 5패스 품질루프 설치 완료

### 11. 기타
- Stop 훅 순서 수정 (telegram 마지막)
- pre-compact-snapshot.sh: hookSpecificOutput → systemMessage
- PITFALLS P-010 (MCP reconnect 미시도), P-011 (crossReview 잘림)
- 디자인 레퍼런스: godly.website, motionsites.ai, NotebookLM

## 21개 검증 항목 — 전부 PASS
훅 9개 + 규칙 5개 + MCP 4개 + 인프라 3개 = 21/21 ✅

## PITFALLS 신규
- P-010: MCP reconnect 미시도 (2회 재발)
- P-011: crossReview 텍스트 3000자 제한으로 잘림

## 다음 세션 작업
1. /council 하네스 통합 (자율 호출 가능하게)
2. BiteLog 개발 재개 (해당 폴더에서 새 세션)
3. 블로그 10→20편 확장
4. NotebookLM 디자인 리서치 노트북 활용
