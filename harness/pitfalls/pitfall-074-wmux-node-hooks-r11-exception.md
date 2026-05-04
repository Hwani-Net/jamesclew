---
slug: pitfall-074-wmux-node-hooks-r11-exception
title: "wmux가 settings.json에 Node 기반 PostToolUse hook 10개 자동 주입 — R11 P0 예외"
date: 2026-04-28
tags: [pitfall, wmux, settings, hooks, r11, node]
tier: raw
---

# pitfall-074 — wmux Node Hooks: R11 P0 예외 명문화

## 증상
wmux v0.7.9 첫 기동 시 `~/.claude/settings.json` PostToolUse 섹션에 다음 hook이 자동 추가됨.

```
Bash / Read / Write / Edit / Grep / Glob / Agent / WebSearch / WebFetch / Skill
→ node "C:/Users/AIcreator/AppData/Local/wmux/resources/cli/wmux-hook.js" <ToolName> 2>/dev/null || true
```

`autonomous-evolution.md`의 R11 P0("JS/TS/Node 사용 금지")와 충돌 가능성 발생.

## 원인
- wmux는 Electron 앱이며 도구 호출 이벤트를 GUI 패널과 동기화하기 위해 PostToolUse hook을 사용
- hook 자체가 wmux 패키지 내부 Node 스크립트(`wmux-hook.js`)를 호출
- R11 P0는 **하네스 자체 hook 작성**에 대한 제약 — 외부 도구가 자기 동작용으로 추가한 hook은 적용 범위 밖으로 해석

## 해결 (대표님 결정 2026-04-28)
**A안(유지) + C안(PITFALL 기록) 채택.**

- wmux의 Node hook 10개 그대로 유지 (`2>/dev/null || true` fail-safe로 jamesclew hook과 충돌 없음)
- 본 문서로 예외를 명문화하여 향후 감사(`/audit`) 시 R11 위반 오탐 방지
- wmux 도입 자체가 멀티에이전트 평가 목적이므로 기능을 끄면 평가 의미 상실

## 재발 방지
1. **R11 P0 해석 명문화**: "외부 도구가 자기 패키지 내부 스크립트로 추가한 hook은 R11 적용 제외. 하네스 `harness/hooks/`에 직접 작성하는 hook만 R11 대상."
2. **wmux 업데이트 시 재검토 트리거**:
   - wmux 메이저 버전 업(0.7.x → 0.8.x 등) 시 본 pitfall 재확인
   - hook 동작이 fail-safe(`|| true`)에서 실패 차단으로 변경되면 즉시 제거 검토
3. **충돌 모니터링**: jamesclew hook과 wmux hook이 같은 PostToolUse 이벤트에서 실행됨. periodic-audit·verify-deploy 등이 wmux hook 부작용으로 느려지면 본 결정 재검토.

## 부수 발견 (해결 무관)
- `wmux-orchestrator plugin not found at .../resources/wmux-orchestrator` — wmux 0.7.9 패키징 흠
- `app-update.yml ENOENT` — 자동 업데이트 매니페스트 누락. 동작 영향 없음
- 9222 포트는 Chrome DevTools 표준이라 Whale/Chrome 등 Chromium 브라우저와 충돌 가능 (점유자 종료 후 wmux 기동 필요)

## 참조
- `~/.claude/rules/autonomous-evolution.md` R11 P0
- `~/.claude/settings.json` PostToolUse line 338-419
- 세션 2026-04-28: wmux v0.7.9 도입 + bash 환경 호환성 검증
