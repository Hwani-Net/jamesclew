---
type: pitfall
id: P-025
title: "copilot-api 400 에러 — tools 배열 128개 한계 초과 (korean-law 상시 로드)"
tags: [pitfall, jamesclew]
---

# P-025: copilot-api 400 에러 — tools 배열 128개 한계 초과 (korean-law 상시 로드)

- **발견**: 2026-04-16
- **증상**: copilot-api 경유 요청 시 반복적 400 에러. `Invalid 'tools': array too long. Expected maximum length 128, but got 137`
- **원인**: GitHub Copilot API의 **하드코딩 제한 = 128 tools/request** (Microsoft 공식, 우회 불가). `korean-law` MCP(89 tools)가 상시 등록되어 있어 혼자서 한계의 70% 차지. CLAUDE.md `rules/architecture.md`에는 "온디맨드 — 상시 로드 금지" 규칙이 명시돼 있었으나 실제로는 user config에 상시 등록된 상태
- **해결**: `claude mcp remove korean-law -s user`로 즉시 제거. 137 → 48(89 감소) = 128 이하 안전 구간. 필요 시 `claude mcp add korean-law -s user -- cmd /c npx -y korean-law-mcp`로 온디맨드 추가 후 작업 완료 시 remove
- **재발 방지**:
  1. `/audit`에 "tools 개수 체크" 항목 추가 — MCP 총 도구 수 집계하여 120+ 시 경고
  2. MCP 등록 시 도구 수 표기 의무화 (perplexity: 4, tavily: 5, korean-law: 89 등)
  3. copilot-api 프록시에 tools trim 기능 요청 또는 자체 래퍼 구현
  4. **Copilot 경유 시 상시 로드 MCP 총합 ≤ 80** (built-in ~40 + MCP ~40 = 80) 기준 준수
- **참조**: [vscode-copilot-release#11653](https://github.com/microsoft/vscode-copilot-release/issues/11653), [zed#42393](https://github.com/zed-industries/zed/issues/42393)
