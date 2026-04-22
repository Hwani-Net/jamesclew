# Hooks Reference — JamesClaw Harness

최종 갱신: 2026-04-18 | 소스: `D:/jamesclew/harness/hooks/` | 총 41개 파일

---

## 1. 개요

훅은 Claude Code가 도구를 실행하거나 세션 상태가 변할 때 자동으로 실행되는 사이드카 스크립트입니다. 이벤트 종류는 PreToolUse / PostToolUse / SubagentStop / UserPromptSubmit / PreCompact / PostCompact / Stop / StopFailure / SessionStart / InstructionsLoaded / ConfigChange / WorktreeCreate / WorktreeRemove 13종이며, 훅은 경고 메시지 주입(stdout JSON), 강제 차단(exit 2), 또는 상태 로깅(부작용 전용) 세 가지 방식으로 동작합니다.

---

## 2. 이벤트별 훅 그룹

| 이벤트 | 실행 시점 | 등록된 훅 (matcher 포함) |
|--------|----------|--------------------------|
| **PreToolUse** | 도구 실행 직전 | verify-memory-write, enforce-build-transition (Write\|Edit) / tavily-guardrail (tavily) / vision-routing-guard (expect screenshot) / chrome-read-page-guard (chrome MCP) / quality-gate pre-commit, pre-commit-conventional, irreversible-alert, bash-tool-blocker, verify-deploy (Bash) |
| **PostToolUse** | 도구 실행 직후 | verify-deploy, enforce-review, error-telegram, loop-detector (Bash) / post-edit-dispatcher, regression-autotest, enforce-cross-review, change-tracker, regression-guard, test-manipulation-guard (Write\|Edit) / read-once, sonnet-vision-delegate-guard (Read) / explore-router (Read\|Grep\|Glob\|Bash\|Edit\|Write) / log-filter, cost-tracker, watchdog-ralph (Bash) / wiki-raw-save (perplexity\|tavily) / quality-gate post-test (npm test) / loop-detector (WebFetch\|WebSearch) |
| **SubagentStop** | 서브에이전트 종료 | verify-subagent |
| **UserPromptSubmit** | 사용자 메시지 수신 | user-prompt (TS), user-prompt-declare-warn, capture-reset-times |
| **PreCompact** | compact 직전 | pre-compact-snapshot, audit-session --compact, self-evolve --apply, curation (TS), gbrain sync |
| **PostCompact** | compact 직후 | telegram-notify compact, session-start (TS), post-compact-resume |
| **Stop** | 에이전트 응답 완료 | stop-dispatcher, session-learning |
| **StopFailure** | 에이전트 실패 종료 | telegram-notify stop-failure |
| **SessionStart** | 세션 시작 | telegram-notify start + 규칙 주입, copilot-api-autostart, session-start (TS) |
| **InstructionsLoaded** | CLAUDE.md 로드 | MD5 해시 변경 감지 + systemMessage 주입 |
| **ConfigChange** | settings.json 변경 | config_changes.log 기록 |
| **WorktreeCreate** | worktree 생성 | worktree.log 기록 |
| **WorktreeRemove** | worktree 제거 | worktree.log 기록 |

---

## 3. 개별 Hook 상세 표

| 파일명 | 이벤트 | matcher | 역할 (1줄) | 차단 | 소스 경로 |
|--------|--------|---------|-----------|------|----------|
| bash-tool-blocker.sh | PreToolUse | Bash | 금지 패턴 Bash 명령 차단 | exit 2 | hooks/bash-tool-blocker.sh |
| capture-reset-times.sh | UserPromptSubmit | — | 5H/7D 리셋 시각 캡처·저장 | 없음 | hooks/capture-reset-times.sh |
| change-tracker.sh | PostToolUse | Write\|Edit | 세션 내 변경 파일 누적·스코프 크리프 경고 | 경고 주입 | hooks/change-tracker.sh |
| chrome-read-page-guard.sh | PreToolUse | chrome MCP | claude-in-chrome 호출 전 read_page 우선 순서 안내 | 경고 주입 | hooks/chrome-read-page-guard.sh |
| copilot-api-autostart.sh | SessionStart | — | copilot-api 서버(port 4141) 자동 기동 확인 | 없음 | hooks/copilot-api-autostart.sh |
| cost-tracker.sh | PostToolUse | perplexity\|tavily\|Bash | API 호출 비용 api_cost_log.jsonl 기록 | 없음 | hooks/cost-tracker.sh |
| curation.ts | PreCompact | auto\|manual | 세션 지식 큐레이션·gbrain 저장 (TypeScript) | 없음 | hooks/curation.ts |
| enforce-build-transition.sh | PreToolUse | Write\|Edit | 빌드 요청 시 PRD→plan 선행 여부 검사 | exit 2 | hooks/enforce-build-transition.sh |
| enforce-cross-review.sh | PostToolUse | Write\|Edit | 외부 모델 교차 검수 수행 촉구 | 경고 주입 | hooks/enforce-cross-review.sh |
| enforce-execution.sh | — | — | 선언-미실행 패턴 감지·차단 | 경고 주입 | hooks/enforce-execution.sh |
| enforce-review.sh | PostToolUse | Bash (deploy) | 배포 후 외부 모델 리뷰 강제 | 경고 주입 | hooks/enforce-review.sh |
| error-telegram.sh | PostToolUse | Bash | Bash 에러 발생 시 텔레그램 알림 | 없음 | hooks/error-telegram.sh |
| evidence-first.sh | — | — | 근거 없는 보고 감지·차단 | 경고 주입 | hooks/evidence-first.sh |
| explore-router.sh | PostToolUse | Read\|Grep\|Glob\|Bash\|Edit\|Write | 직접 탐색 5회 누적 시 서브에이전트 위임 권고 | 경고 주입 | hooks/explore-router.sh |
| irreversible-alert.sh | PreToolUse | Bash | 비가역 작업(rm, format 등) defer 결정 요청 | defer | hooks/irreversible-alert.sh |
| log-filter.sh | PostToolUse | Bash | 빌드·테스트 로그에서 error/warn만 필터 출력 | 없음 | hooks/log-filter.sh |
| loop-detector.sh | PostToolUse | Bash\|WebFetch\|WebSearch | 동일 패턴 반복 루프 감지·경고 | 경고 주입 | hooks/loop-detector.sh |
| post-compact-resume.sh | PostCompact | — | compact 후 작업 재개 컨텍스트 복원 | 없음 | hooks/post-compact-resume.sh |
| post-edit-dispatcher.sh | PostToolUse | Write\|Edit | 파일 수정 후 품질 파이프라인 디스패치 | 없음 | hooks/post-edit-dispatcher.sh |
| pre-commit-conventional.sh | PreToolUse | Bash | git commit 메시지 Conventional Commits 형식 검사 | exit 2 | hooks/pre-commit-conventional.sh |
| pre-compact-snapshot.sh | PreCompact | auto\|manual | compact 전 옵시디언 세션 스냅샷 저장. 실패 시 compact 차단 | exit 2 | hooks/pre-compact-snapshot.sh |
| quality-gate.sh | PreToolUse / PostToolUse | Bash | pre-commit 체크 및 post-test 결과 검증 | exit 2 | hooks/quality-gate.sh |
| read-once.sh | PostToolUse | Read | 5분 내 동일 파일 재읽기 감지·메모리 참조 권고 | 경고 주입 | hooks/read-once.sh |
| regression-autotest.sh | PostToolUse | Write\|Edit | 파일 수정 후 관련 테스트 자동 실행 | 없음 | hooks/regression-autotest.sh |
| regression-guard.sh | PostToolUse | Write\|Edit | 삭제량이 추가량 2배 초과 시 회귀 경고 | 경고 주입 | hooks/regression-guard.sh |
| session-learning.sh | Stop | — | 세션 종료 시 패턴·교훈 gbrain 저장 | 없음 | hooks/session-learning.sh |
| session-start.ts | SessionStart / PostCompact | — | 세션 초기화·컨텍스트 복원 (TypeScript) | 없음 | hooks/session-start.ts |
| sonnet-vision-delegate-guard.sh | PostToolUse | Read | 이미지 Read 시 Sonnet Vision 사용 감지·Opus 위임 권고 | 경고 주입 | hooks/sonnet-vision-delegate-guard.sh |
| stop-dispatcher.sh | Stop | — | 작업 완료 텔레그램 알림·Ghost Mode 규칙 주입 | 없음 | hooks/stop-dispatcher.sh |
| tavily-guardrail.sh | PreToolUse | tavily | search_depth=advanced / max_results 과도 사용 차단 | exit 2 | hooks/tavily-guardrail.sh |
| telegram-notify.sh | Stop / StopFailure / PostCompact / SessionStart | — | 이벤트별 텔레그램 알림 전송 | 없음 | hooks/telegram-notify.sh |
| test-manipulation-guard.sh | PostToolUse | Write\|Edit | 테스트만 수정하고 소스 미수정 패턴 감지 | 경고 주입 | hooks/test-manipulation-guard.sh |
| test-pre-commit-conventional.sh | — | — | pre-commit-conventional 단위 테스트용 스크립트 | 없음 | hooks/test-pre-commit-conventional.sh |
| user-prompt.ts | UserPromptSubmit | — | 피드백 패턴 감지·PITFALLS 기록 지시 주입 (TypeScript) | 경고 주입 | hooks/user-prompt.ts |
| user-prompt-declare-warn.sh | UserPromptSubmit | — | 선언-미실행 패턴 감지·경고 주입 | 경고 주입 | hooks/user-prompt-declare-warn.sh |
| verify-deploy.sh | PreToolUse / PostToolUse | Bash (deploy) | firebase deploy 전후 Step 5/7 증거 검증 | exit 2 | hooks/verify-deploy.sh |
| verify-memory-write.sh | PreToolUse | Write\|Edit | ~/.claude/ 직접 쓰기 차단 (harness/ 경유 강제) | exit 2 | hooks/verify-memory-write.sh |
| verify-subagent.sh | SubagentStop | — | 서브에이전트 결과물 품질·증거 검증 | 경고 주입 | hooks/verify-subagent.sh |
| vision-routing-guard.sh | PreToolUse | expect screenshot | Sonnet 세션에서 Vision 호출 시 Opus 위임 권고 | 경고 주입 | hooks/vision-routing-guard.sh |
| watchdog-ralph.sh | PostToolUse | Bash | Ralph Loop 상태 감시·stall 시 re-spawn | 없음 | hooks/watchdog-ralph.sh |
| wiki-raw-save.sh | PostToolUse | perplexity\|tavily | 검색 결과를 $OBSIDIAN_VAULT/06-raw/ 자동 저장 | 없음 | hooks/wiki-raw-save.sh |

---

## 4. 차단(exit 2) 훅 하이라이트

### verify-memory-write.sh
Write/Edit PreToolUse에서 대상 경로가 `~/.claude/` 직하위인지 검사합니다. 해당 경로 직접 쓰기가 감지되면 즉시 차단하고, `D:/jamesclew/harness/`에서 편집 후 `deploy.sh` 경유를 요구합니다. 하네스 소스와 배포 결과물의 동기화를 강제하는 가장 기초적인 안전망입니다.

### enforce-build-transition.sh
Write/Edit PreToolUse에서 신규 프로젝트 빌드 요청을 감지합니다. `<!-- ANNOTATE-APPROVED -->` 헤더가 없는 플랜 파일로 구현에 진입하려 하면 차단하며, `/prd → /pipeline-install → /plan → /annotate-plan` 순서를 강제합니다. 즉흥 코딩으로 인한 설계 부채를 사전에 막습니다.

### verify-deploy.sh
`firebase deploy` 명령의 PreToolUse와 PostToolUse 양쪽에서 실행됩니다. 배포 전에는 Step 5/7(테스트·빌드 증거) 존재 여부를 확인하고, 배포 후에는 라이브 URL HTTP 200 응답을 검증합니다. 증거 없이 배포가 시작되거나 검증 실패 시 exit 2로 차단합니다.

### pre-compact-snapshot.sh
PreCompact(auto|manual) 시점에 옵시디언 세션 스냅샷 저장을 시도합니다. 저장 실패 시 exit 2를 반환하여 compact 자체를 차단합니다. P-007(저장 없이 compact 금지)을 hook 수준에서 강제하는 핵심 안전장치입니다.

---

## 5. 숨은 기능 5가지

### A. PreCompact 자기진화 파이프라인
PreCompact는 단순 저장이 아닌 5단계 파이프라인을 순차 실행합니다. `pre-compact-snapshot`(옵시디언 저장) → `audit-session --compact`(감사 점검) → `self-evolve --apply`(규칙 자동 개선 적용) → `curation.ts`(세션 지식 큐레이션·gbrain 저장) → `gbrain sync`(리포 동기화). compact 한 번에 하네스가 스스로 진화하는 구조입니다.

### B. irreversible-alert.sh의 defer 메커니즘
`deny`(완전 차단)가 아닌 `permissionDecision: "defer"`를 반환합니다. 비가역 Bash 명령(rm, format 계열)을 감지하면 실행을 일시정지시키고 사용자 확인을 요청합니다. 자동화 흐름을 끊지 않으면서도 위험 작업에 게이트를 삽입하는 v2.1.89+ 기능입니다.

### C. GPT 메인 전환 지원 (copilot-api-autostart.sh)
SessionStart에서 copilot-api 서버(localhost:4141) 가동 상태를 자동 확인합니다. 5H 한계 도달 시 `ANTHROPIC_BASE_URL=http://localhost:4141 claude`로 새 세션을 열면 GPT-4.1이 Claude Code의 모든 도구를 사용하는 메인 모델로 전환됩니다. 서버 기동을 hook이 보장하므로 전환 직전 수동 시작이 불필요합니다.

### D. InstructionsLoaded MD5 변경 감지
세션마다 CLAUDE.md의 MD5를 계산해 `~/.harness-state/claude_md_hash`에 저장합니다. 이전 해시와 다르면 `systemMessage`로 "CLAUDE.md 변경됨, 내용 확인 요망" 경고를 에이전트에 주입합니다. 규칙 파일 갱신이 조용히 묻히는 사고를 방지합니다.

### E. 자동 스킬 생성 트리거 (user-prompt.ts + session-learning.sh)
`user-prompt.ts`가 피드백 패턴을 감지하면 PITFALLS 기록 지시를 자동 주입하고, `session-learning.sh`가 Stop 시점에 5회+ 도구 호출 복합 작업을 식별해 `harness/commands/`에 재사용 스킬로 저장합니다. 에이전트가 반복 작업을 슬래시 커맨드로 자동 결정화하는 구조입니다.
