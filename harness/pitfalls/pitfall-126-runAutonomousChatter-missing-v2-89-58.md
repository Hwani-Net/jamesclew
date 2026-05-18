---
title: Connect AI extension v2.89.58 — runAutonomousChatter 메서드 누락
date: 2026-05-07
slug: pitfall-126-runAutonomousChatter-missing-v2-89-58
tags: [connect-ai, extension, antigravity, autonomous-cycle, dispatch]
---

# 증상

- "24시간 자동 운영 ON" 토글(`workdayBtn`, 사무실 상단 헤더)을 켜도 5분 chatter가 어댑터까지 도달하지 못해 자율 사이클이 결과를 못 만듦
- 입력창 직접 입력은 정상 작동
- autoCycleEnabled = true, defaultModel = claude-sonnet-4.6 모두 정상이어도 chatter silent fail
- v2.46.3에서는 정상 작동하던 기능. v2.89.58 자동 업데이트 후 발생

⚠️ **버튼 식별 정정 (2026-05-07)**: 입력창 옆 ⚡ 버튼은 자율 사이클 트리거가 아니라 **첨부 파일을 지식에 저장**하는 버튼. 진짜 자율 사이클 토글은 사무실 상단의 "24시간 자동 운영 ON/OFF" 버튼(`workdayBtn`). 디버깅 초기에 이 두 버튼을 혼동하여 ⚡ 클릭 후 어댑터 로그를 확인하다가 실제로는 5분 chatter autofire 결과를 보고 있었음.

# 원인

extension.js (1.7MB minified) 분석 결과:

1. `case "runChatter"` 핸들러(L31534)가 `provider.runAutonomousChatter(model).catch(() => {})` 호출
2. **`SidebarChatProvider` 클래스에 `runAutonomousChatter` 메서드 prototype 정의 자체가 없음**
3. `undefined.catch()` → TypeError → `.catch(() => {})`가 에러를 조용히 삼킴
4. `provider.startAutoCycle(15, 0)` (L25103, L31594) 도 동일하게 미구현 — 옵셔널 체이닝 `?.`으로 무음 skip

원인: v2.89.58 minify/build 과정에서 자율 사이클 관련 메서드들이 dead code elimination으로 제거되었거나, 의도치 않게 누락된 것으로 추정.

# 해결

**PATCH v6.7** (L31534~31538): `runChatter` 핸들러를 `runCorporatePromptExternal`(officePrompt 경로의 검증된 메서드)로 우회.

```js
// 변경 전
case "runChatter": {
  const model = provider.getDefaultModel();
  provider.runAutonomousChatter(model).catch(() => {});  // undefined
  break;
}

// 변경 후
case "runChatter": {
  /* PATCH v6.7: runAutonomousChatter 미구현 (v2.89.58 누락) */
  const model = provider.getDefaultModel();
  provider.runCorporatePromptExternal(
    "[자율 사이클] 현재 미션 보고 후 한 스텝만 진행하세요. 간결히.",
    model,
  ).catch(() => {});
  break;
}
```

효과:
- ✅ ⚡ 클릭 시 CEO sonnet-4.6 호출이 어댑터까지 도달
- ✅ webview의 `startChatterAutofire`(5분 간격)가 같은 경로를 트리거 → 5분마다 자율 사이클
- ⚠️ 단, `_handleCorporatePrompt` 내 plan 파싱은 별도 이슈 — CEO 응답이 plan(JSON 형식?)을 만들지 않으면 "모든 에이전트의 LLM 호출이 실패" fallback 메시지 출력
- ⚠️ `startAutoCycle(15, 0)` 자체는 패치 안 됨 — 백그라운드 15분 타이머 없음. office panel을 열어두면 webview chatter autofire가 대체

# 재발 방지

1. **repatch-extension.ps1에 P7 추가**: 다음 Antigravity 업데이트로 메서드가 다시 누락되면 자동 패치
2. **agent_models.json은 어댑터에 실제 존재하는 모델만 사용**: opus-4.7, gpt-5.5, gpt-5.3-codex 같은 미존재/미지원 모델 매핑 시 silent fail
3. **defaultModel도 검증된 모델로 고정**: claude-sonnet-4.6 권장
4. plan-based 다중 에이전트 dispatch는 별도 추적 필요 — `_handleCorporatePrompt` 분석으로 plan 파싱 형식 확인

# 검증

```
[16:00:01] POST /api/chat 200
           model=claude-sonnet-4.6, route=claude-cli
           28315ms, 5 chunks, 220 chars 응답
```

PATCH v6.7 적용 후 ⚡ 클릭 → 어댑터 도달 확인.

# 후속 수정 (2026-05-07 16:55~17:01)

PATCH v6.7 적용 후 ⚡ → Researcher 호출 시 60초 timeout(`LLM 스트림 60초간 응답 없음`) 발생.

원인:
- claude-cli 라우트는 매 호출마다 새 Claude Code 인스턴스 cold start → 첫 호출 113초까지 hang
- `_consumeLLMStream` IDLE_TIMEOUT_MS = 6e4(60초)에서 abort

추가 패치:
- **PATCH v6.8** (L31535): plan JSON 형식 명시 prompt로 변경. CEO가 `{"brief":"...","tasks":[{"agent":"researcher","task":"..."}]}` 응답 유도 → 첫 researcher.md 생성 확인 (07-51 세션)
- **PATCH v6.9** (L39602): IDLE_TIMEOUT_MS 6e4 → 1.8e5 (60초 → 180초)
- **agent_models.json**: researcher: claude-sonnet-4.6 → gpt-4.1 (chat-completions 5초 응답으로 cold start 회피)

재발 방지 강화: repatch 스크립트에 P7(runChatter v6.8), P8(timeout v6.9) 추가됨.

# 관련

- pitfall-123: copilot-api supported_endpoints 메타데이터 누락
- pitfall-124: extension spawn Python stdout cp949
- pitfall-125: _runShortcutTool captureStream stdout only
