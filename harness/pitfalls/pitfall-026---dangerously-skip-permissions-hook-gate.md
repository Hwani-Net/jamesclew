---
type: pitfall
id: P-026
title: "--dangerously-skip-permissions 설정에도 승인 요청이 뜨는 이유 (하네스 hook gate 독립 작동)"
tags: [pitfall, jamesclew]
---

# P-026: --dangerously-skip-permissions 설정에도 승인 요청이 뜨는 이유 (하네스 hook gate 독립 작동)

- **발견**: 2026-04-16
- **증상**: settings.json에 `"defaultMode": "bypassPermissions"` 설정했음에도 일부 작업에서 대표님 승인 창 발생
- **원인**: `bypassPermissions` 모드는 Anthropic 기본 권한 체계만 우회. 하네스 hook이 반환하는 `permissionDecision: "deny"/"ask"/"defer"` 및 `exit 2`는 **독립 작동**. v2.1.110 changelog 명시: "permissions.deny rules override PreToolUse hook's permissionDecision 'ask'" — deny는 bypass조차 override
- **실제 gate 지점**:
  1. `settings.json` line 30 `"permissions.deny"` 리스트
  2. `settings.json` line 50 PreToolUse Write|Edit hook (보호 파일 deny)
  3. `bash-tool-blocker.sh` line 45 `permissionDecision: deny` 반환
  4. `enforce-build-transition.sh`, `pre-commit-conventional.sh`, `tavily-guardrail.sh`, `verify-memory-write.sh` 각자 gate
- **해결 (부분)**: 보안 gate(`.env`/credentials/키 파일)는 유지 필수. 완화 대상은 대표님이 실제로 자주 막히는 hook을 특정해야 타겟 수정 가능. 맹목적 완화 = 보안 퇴행
- **재발 방지**:
  1. `--dangerously-skip-permissions` = "Anthropic 내장 권한만 끈다". 하네스 hook은 별도라고 문서화
  2. 승인 요청 발생 시 `hook-denied.log`에 어떤 hook이 원인인지 기록 (신규 기능)
  3. CLAUDE.md Prerequisites 섹션에 "bypassPermissions도 하네스 hook은 독립 작동"을 명시
- **참조**: v2.1.110 changelog (permission.deny override), `~/.claude/cache/changelog.md` line 54
