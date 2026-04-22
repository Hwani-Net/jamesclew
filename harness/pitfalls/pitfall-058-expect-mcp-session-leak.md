---
title: expect MCP 브라우저 세션이 close 누락으로 지속되어 CPU/메모리 누수
tags: [expect, mcp, playwright, process-leak, hook]
date: 2026-04-19
---

## 증상

`mcp__expect__open`으로 Playwright Chromium 브라우저를 열고 스크린샷·스냅샷·네트워크 검사 등 작업을 마친 후, Claude가 `mcp__expect__close`를 호출하지 않아 Chromium 프로세스가 세션 내내 살아 있음. CPU·메모리·전력을 지속적으로 소비. 대표님이 "expect 사용 끝나면 종료하라고 했는데 왜 자꾸 띄워놓아? 전력소모가 상당하다"고 지적.

## 원인

- `mcp__expect__close` 호출을 Claude 자율에 맡김
- 강제 종료 메커니즘(hook) 없이 규칙만 존재
- PostToolUse 세션 추적도 없어 Stop 시점에 브라우저 활성 여부 파악 불가

## 해결

1. **PostToolUse 매처 추가** (`settings.json`):
   - `mcp__expect__.*` 패턴으로 `expect-session-tracker.sh` 실행
   - `open` → `$HOME/.harness-state/expect_session_active`에 timestamp 기록
   - `close` → 파일 삭제
   - 기타 expect 도구 → timestamp 갱신

2. **Stop hook 추가** (`expect-auto-close-on-stop.sh`):
   - 세션 파일 존재 확인 → Playwright Chromium `taskkill //F` 강제 종료
   - Claude 다음 응답에 경고 additionalContext 주입
   - 세션 파일 삭제

## 재발방지

- expect 도구 호출 후 같은 응답 내에 `mcp__expect__close` 필수. 다음 응답으로 미루지 않는다.
- Stop hook이 백업으로 항상 강제 종료하므로, 빠뜨려도 프로세스 누수는 방지됨.
- 장시간 Playwright 세션이 필요한 경우 논리적 segment마다 `close → reopen` 패턴 권장.
- 유사한 장기 MCP 세션 도구(claude-in-chrome 등)에도 동일 패턴 적용 검토.
