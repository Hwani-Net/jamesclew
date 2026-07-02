---
slug: pitfall-272-expect-mcp-removed-verification-vs-navigation-misclassification
title: "expect MCP 완전 제거 — '검증 도구'를 '네비게이션 사다리'에 넣어 중복 오인 반복"
symptom: "대표님이 '왜 자꾸 expect 쓰냐 / 삭제 안 했냐'를 반복 질문. expect가 브라우저 우선순위 사다리(gstack·claude-in-chrome 옆)에 있어 중복 네비게이션 브라우저처럼 보였으나, 실제로는 블로그/QA 렌더-검증 엔진이었음."
tags: [expect, gstack, browser, tool-classification, verification, reins, P-256, deprecation]
date: 2026-07-01
severity: medium
related: [pitfall-269-cowork-desktop-mcp-separate-from-cli-codex-mcp-server]
---

## 증상

브라우저 도구 통합(gstack /browse 1순위 + Desktop 내장 Chrome 고정) 후에도 expect MCP가 계속 문서에 등장 → 대표님이 "expect 왜 자꾸 쓰냐, 삭제 안 했냐?" 반복 지적. 실제로 삭제된 적 없었고, 정책상 "2순위 강등 + 이관 후 제거 예정"으로 미적거리며 유지 중이었음("later means never").

## 원인 (분류 오류)

expect를 **네비게이션 도구 우선순위 사다리**(gstack·claude-in-chrome과 나란히)에 넣은 것이 근본. 두 도구는 **역할이 다름**:
- **네비게이션**(페이지 열고 클릭): Desktop=내장 Chrome / CLI=gstack /browse
- **검증**(headless 렌더 검사): expect MCP의 `screenshot·network_requests·console_logs·performance_metrics(LCP/CLS)·accessibility_audit` 7단계 = blog-review/pipeline/qa의 Reins 기계 게이트(P-256)

같은 사다리에 넣으니 "중복 브라우저"로 보였고, 매 브라우저 논의마다 이름이 흘러 "아직 쓰네"로 오인됨.

## 해결 (2026-07-01, 대표님 승인 옵션 B = 완전 제거)

1. **`claude mcp remove expect`** — CLI 등록 제거(`.claude.json`).
2. **렌더 검증 이관 → gstack js**: screenshot(`$B screenshot`) + 실패리소스(`performance.getEntriesByType('resource')`) + 깨진이미지(`naturalWidth>0`) + 에러페이지(`$B text`). blog-review Phase 1 "expect 7단계" → "gstack 렌더 검증 5단계" 재작성. gstack 실작동 사전 검증(goto 200·screenshot 10KB·js 반환).
3. **대체제 없어 폐지된 게이트 (승인분)**: `accessibility_audit`·`performance_metrics(LCP/CLS)`·`console error 레벨`. gstack·claude-in-chrome 모두 미제공. **재도입 필요 시 대표님 확인.**
4. 이관 파일 10개: CLAUDE.md·rules(architecture/quality)·commands(blog-review/blog-fix/pipeline-run/pipeline-install/qa/design-review/agent-team). 기계 검증: `mcp__expect__` 호출 0건.

## 재발 방지

- **도구를 우선순위 사다리에 넣기 전 "이게 같은 일을 하나?" 자문** — 네비게이션 vs 검증 vs 캡처는 별개 축. 다른 역할을 한 사다리에 섞으면 중복 오인 발생(pitfall-269 표면 분리와 같은 결).
- **"이관 후 제거 예정"은 미적거림 신호** — ponytail-debt "later means never". 제거하려면 이관을 즉시 하거나, 유지하려면 역할을 명확히 분리하거나 둘 중 하나. 어정쩡한 "2순위 강등"이 반복 혼란의 원인.
- **expect 재등록 금지** (CLAUDE.md 브라우저 섹션 가드). 필요 기능은 gstack js 우선, a11y/perf는 대표님 확인 후 별도 도구.
