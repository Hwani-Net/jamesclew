---
slug: pitfall-172-handoff-failure-gbrain-revival
title: "세션 인수인계 실패 — 이전 세션의 gbrain 폐기 결정을 다음 세션이 부활"
symptom: "이전 세션에서 gbrain 폐기 결정 실행 → 새 세션이 CLAUDE.md 보고 다시 gbrain 부활"
tags: [handoff, session-continuity, gbrain, sticky-decisions, infrastructure]
date: 2026-05-19
severity: critical
---

## 증상

대표님이 이전 세션에서 명확히 **gbrain 완전 폐기** 결정 + 실행 (claude mcp remove gbrain). 새 세션에서 이것이 유지되는지 확인하려는 의도로 새 세션 시작.

그러나 새 세션(이 PITFALL을 기록한 세션)이:
1. CLAUDE.md를 1차 소스로 읽음 (line 31: `gbrain query "질문"` 우선 검색)
2. gbrain CLI가 npm global에 살아있음 (MCP 제거만 됐고 CLI는 잔존)
3. OpenAI 키 받아 gbrain DB 클린 재구축 (698 pages / 1104 chunks)
4. PITFALL P-171 (gbrain config secret leak) 작성하여 gbrain 살리는 절차 영구화
5. apply-openai-key.sh 헬퍼 스크립트 commit
6. git 4개 커밋으로 gbrain 시스템 영구화

**즉 폐기 결정을 정반대로 뒤집고, 그 부활 절차를 영구 기록까지 함.**

## 원인 (인수인계 메커니즘 부재)

### 1차 원인 — CLAUDE.md 미갱신
- 이전 세션이 `claude mcp remove gbrain` 실행했으나
- CLAUDE.md의 gbrain 참조 (line 31, 32, 42, 43, 62, 65, 77, 79, 104, 247) 그대로 유지
- 다음 세션이 CLAUDE.md를 1차 소스로 사용 → gbrain 사용 절차 그대로 따름

### 2차 원인 — MEMORY.md / PITFALL 미갱신
- `reference_gbrain.md`가 "DEPRECATED" 마크 없이 그대로 등재
- 폐기 결정에 대응하는 PITFALL 미작성

### 3차 원인 — agentmemory MCP 자동 캡처 작동 안 함
- agentmemory MCP는 등록됐으나 (autonomous-os-v1.md Phase 1 완료)
- 실제 메모리 0건 (`memory_recall` 결과 빈 배열)
- iii-engine worker 인터랙티브 요구로 standalone shim 모드 → 자동 캡처 미작동

### 4차 원인 — git log에 결정 흔적 부재
- gbrain 관련 마지막 커밋은 모두 **유지·강화** (`3259fc8 fix(gbrain): YAML wikilink`, `68e755c fix(harness): unblock gbrain import`)
- "gbrain 폐기" 커밋 없음 → git 추적으로도 결정 발견 불가

### 5차 원인 — transcript도 도움 안 됨
- 직전 세션(fc33767c, 5월 19일 11:21)의 마지막 사용자 메시지 3개 모두 gbrain과 무관
- transcript는 5.8MB 대용량 → 새 세션이 자동으로 읽지 않음

## 해결 (이 세션)

### 즉시 — gbrain 완전 폐기 재실행 + 영구 저장
1. `claude mcp remove gbrain` (이미 제거 상태 확인)
2. `npm uninstall -g gbrain` + bin 파일 직접 제거
3. PGLite DB → `D:/_archive/gbrain-retired-20260519-135159/`로 아카이브
4. **CLAUDE.md 최상단에 `🔒 STICKY DECISIONS` 섹션 신설**:
   - 폐기 도구 목록 (gbrain, copilot-api, /deep-plan, Antigravity)
   - 인수인계 메커니즘 자체 명시
5. CLAUDE.md 본문의 gbrain 참조 모두 옵시디언/agentmemory로 대체
6. `MEMORY.md` reference_gbrain.md 폐기 마킹
7. `reference_gbrain.md`에 DEPRECATED frontmatter + 대체 매핑
8. 본 PITFALL P-172 작성 → 인수인계 사고 자체 영구 기록

### 부수 — 잘못 부활시킨 흔적은 보존
- P-171 (gbrain config secret leak): **유지** — 보안 교훈은 gbrain 폐기와 별개로 가치 있음 (모든 `*config set <secret>` 명령에 stdout 차단 원칙)
- `apply-openai-key.sh`: **유지** — 향후 다른 도구의 OpenAI 키 적용에 재사용 가능

## 재발 방지

### 1. STICKY DECISIONS 섹션 (CLAUDE.md 최상단)
- 모든 폐기 결정은 이 섹션에 명시
- 새 세션 시작 시 CLAUDE.md 자동 로드 → 이 섹션이 가장 먼저 보임
- 결정 뒤집기 전 반드시 대표님 확인

### 2. 결정 영구화 체크리스트 (모든 폐기 작업 시)
- [ ] `claude mcp remove <tool>` (MCP 등록 해제)
- [ ] `npm uninstall -g <tool>` (CLI 제거)
- [ ] 데이터 디렉토리 아카이브 (`D:/_archive/<tool>-retired-<date>/`)
- [ ] CLAUDE.md `STICKY DECISIONS` 섹션에 추가
- [ ] CLAUDE.md 본문의 도구 참조 모두 정리 (grep으로 누락 검증)
- [ ] MEMORY.md reference 폐기 마킹
- [ ] PITFALL 작성 (폐기 근거 + 대체 매핑)
- [ ] git commit "revert/retire" prefix로 추적 가능하게

### 3. CLAUDE.md 일관성 검증 (정기)
- `audit-session.sh`에 신규 check 추가 후보:
  - `check_sticky_decisions_consistency` — STICKY DECISIONS 섹션 도구가 본문에서 여전히 사용되는지
  - `check_deprecated_tool_revival` — 폐기 도구 명령(gbrain query 등)이 세션 transcript에 나타나는지

### 4. 인수인계 1차 소스 확립
- **CLAUDE.md = 1차 source of truth** (휘발성 위의 영구 레이어)
- agentmemory / git log / transcript = 보조 (참고용)
- 결정 변경 시 CLAUDE.md 갱신이 가장 먼저

## 검증 데이터 (2026-05-19)

### 이번 세션 사고 흔적
- gbrain MCP `claude mcp remove gbrain` 실행 시 "No MCP server found" → **이전 세션 폐기 흔적 발견**
- gbrain CLI는 npm global에 잔존 → `bash -c "gbrain --version"` 0.10.2 작동
- PGLite DB 1332 pages, 임베딩 0개 → **5주간 임베딩 없이도 운영 가능 입증**
- agentmemory MCP `memory_recall("gbrain")` → 빈 배열 (자동 캡처 미작동)

### git commit log (잘못 부활시킨 흔적)
- `a909e52 docs(harness): sync v2.1.143~v2.1.144` (gbrain 무관, 별건)
- `b43367b chore(harness): add pitfall-130/131` (gbrain 무관, 별건)
- `90e2447 fix(security): pitfall-171 — gbrain config set secret leak + safe helper` (gbrain 부활 절차 기록)
- `d34897c chore(harness): add pitfall-132` (gbrain 무관, 별건)

위 4개 커밋 중 90e2447만 gbrain 부활과 직접 연관. 보안 교훈은 유지 가치 있어 revert 안 함.

## 관련

- [[pitfall-019-gbrain-pglite-db-missing-chunk]] — PGLite 손상 반복 (폐기 근거 1)
- [[pitfall-040-gbrain-pglite-wasm-aborted-windows]] — Windows 호환성 문제
- [[pitfall-071-gbrain-mcp-stale-pglite-lock]] — MCP lock 이슈
- [[pitfall-147-gbrain-windows-path-aborted]] — 경로 처리 버그
- [[pitfall-171-gbrain-config-set-secret-leak]] — 이번 세션 부수 사고 (gbrain config가 secret 평문 노출)
