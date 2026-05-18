---
slug: pitfall-121-expect-mcp-not-closed-on-idle
title: "expect MCP 브라우저 종료 누락 (대기모드/작업완료 시)"
date: 2026-05-06
severity: medium
category: resource-leak
tags:
  - expect-mcp
  - playwright
  - resource-cleanup
  - idle-mode
  - repeated-correction
---

# pitfall-121 — expect MCP 브라우저 종료 누락

## 증상

작업 완료 또는 대기 모드 진입 시점에 `mcp__expect__close()` 호출 누락. Playwright 브라우저 인스턴스가 백그라운드에서 살아있는 상태로 유지됨. CEO가 **반복적으로 지적**한 패턴.

## 원인

1. **세션 종료 의례 망각**: 시각 검증 직후 보고만 하고 close() 호출 빠뜨림
2. **다음 검증을 위해 열어둔다는 잘못된 가정**: 다음 turn에서 어차피 close + open 새로 시작이 정석. 유지의 이득 없음
3. **CEO 명시 규칙 인식 부족**: 이전 세션 피드백 + 명시 지시("대기모드나 작업이 끝나면 expect 종료")를 매 turn 체크리스트에 포함 안 함

## 해결

### 즉시 행동
**작업 완료/대기 모드/CEO 보고 직전에 무조건 `mcp__expect__close()` 호출**.

```ts
// 모든 보고 응답 직전 의무 호출
await mcp__expect__close();
```

### 종료 트리거 키워드 (체크리스트)
- "대기 모드 진입"
- "보고드립니다"
- "작업 완료"
- "다음 dispatch까지"
- 마지막 expect 도구 호출 후 별도 검증 작업 없이 보고만 남았을 때

위 트리거 만나면 expect 세션 활성 여부 점검 → 활성이면 close.

## 재발 방지

### Pre-report 체크리스트 (보고 직전 의무)
- [ ] 마지막 expect MCP 도구 호출 이후 close() 호출했는가?
- [ ] 백그라운드 Bash run_in_background 상태 확인했는가?
- [ ] 작업 완료/대기 모드 선언 시 리소스 정리 의례 수행했는가?

### Hook 자동화 후보 (향후)
PostToolUse hook으로 `mcp__expect__open` 호출 후 `mcp__expect__close` 미호출 상태에서 텍스트 응답 종료 시 경고. 또는 Stop hook에서 expect 세션 활성 여부 점검 + 자동 close 강제.

## 참고

- 발생 세션: 2026-05-06 K-Mate Phase 5 베타 카운터 검증 후
- CEO 피드백: "야. 대기모드나 작업이 끝나면 expect 종료 하랬잖아. 왜 자꾸 안지키지?"
- 직전 turn에서 mcp__expect__playwright 시각 검증 후 close 누락 → 보고 진입
- 관련 PITFALL: pitfall-119 (회피 패턴), pitfall-120 (검증 누락)
