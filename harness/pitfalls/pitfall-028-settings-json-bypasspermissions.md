---
type: pitfall
id: P-028
title: "settings.json 편집 시 bypassPermissions에도 승인창 — 자기 권한 상향 방지 보안 디자인"
tags: [pitfall, jamesclew]
---

# P-028: settings.json 편집 시 bypassPermissions에도 승인창 — 자기 권한 상향 방지 보안 디자인

- **발견**: 2026-04-17
- **증상**: Edit 도구로 `~/.claude/settings.json` 수정 시 "Do you want to make this edit to settings.json?" 승인 창. "Yes / Yes allow for this session / No" 3선택지. bypassPermissions + `Edit(*)` allow가 있어도 차단
- **원인**: Claude Code 공식 보안 설계. 자기 권한 파일을 자기가 수정해 권한 상향하는 공격(self-privilege-escalation) 방지. 일반 Edit allow rule로 우회 불가. 세션 단위 "allow for this session" 옵션만 존재, 영구 옵션 없음 (Anthropic 의도)
- **해결 (영구 불가, 완화만)**:
  1. **`update-config` skill** 사용 — Claude Code 공식 설정 변경 스킬. Edit 도구보다 마찰 적음
  2. 대표님이 IDE에서 **직접 편집** — 하네스 수정 없이 개별 튜닝
  3. 매 세션 첫 settings 편집 시 "옵션 2" 클릭 = 세션 내 허용 유지
- **재발 방지**:
  1. Claude가 settings.json 자동 편집 최소화 — 구조적 변경은 `update-config` skill로 유도
  2. harness/settings.json (source) 편집 후 재배포 — 런타임 settings 직접 수정 대신 소스 편집 권장
  3. CLAUDE.md에 "settings.json 편집은 update-config skill 우선" 명시
- **참조**: [GitHub Issue #41259](https://github.com/anthropics/claude-code/issues/41259), changelog line: "allow Claude to edit its own settings for this session"
