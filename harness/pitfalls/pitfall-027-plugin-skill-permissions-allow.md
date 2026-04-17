---
type: pitfall
id: P-027
title: "Plugin skill 사용 승인 다이얼로그 — permissions.allow 누락"
tags: [pitfall, jamesclew]
---

# P-027: Plugin skill 사용 승인 다이얼로그 — permissions.allow 누락

- **발견**: 2026-04-17
- **증상**: `/ralph-loop:ralph-loop` 스킬 실행 시 "Use skill ralph-loop:ralph-loop?" 승인 창 발생. bypassPermissions 모드인데도 뜸
- **원인**: Claude Code는 플러그인 스킬 사용 시 `permissions.allow`에 **`Plugin:<name>:*`** 패턴이 없으면 승인 요구. `skipDangerousModePermissionPrompt: true`는 `--dangerously-skip-permissions` 초기 진입 프롬프트에만 작용
- **해결**: settings.json `permissions.allow`에 `"Plugin:ralph-loop:*"`, `"Plugin:awesome-statusline:*"`, `"Skill(*)"` 추가. 기존에는 `"Plugin:telegram:*"`만 있어 다른 플러그인은 전부 승인 요구 상태였음
- **재발 방지**:
  1. 새 플러그인 설치 시 자동으로 `permissions.allow`에 등록하는 hook 추가 검토
  2. `enabledPlugins` 목록과 `permissions.allow`의 `Plugin:*` 패턴 일치 확인을 `/audit`에 추가
  3. CLAUDE.md에 "새 플러그인 설치 시 allow 목록 동기화 필수" 규칙 명시
- **참조**: [GitHub Issue #36497](https://github.com/anthropics/claude-code/issues/36497) (.claude/skills/ prompt regression), settings.json line 13-29
