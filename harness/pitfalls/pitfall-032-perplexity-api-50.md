---
type: pitfall
id: P-032
title: "Perplexity API 최소 충전 $50 — 검색용으로 과도한 비용"
tags: [pitfall, jamesclew]
---

# P-032: Perplexity API 최소 충전 $50 — 검색용으로 과도한 비용

- **발견**: 2026-04-17
- **증상**: API 크레딧 탑업 모달에서 $5 입력 시 "최소 $50 이상" 에러
- **원인**: Perplexity API 플랜 정책이 최소 충전 $50
- **해결**: Perplexity MCP 제거. 무료 대체: Tavily(6키 로테이션) + DuckDuckGo MCP + Wikipedia MCP + NotebookLM
- **재발 방지**: 검색 API는 "최소 충전 금액" 사전 확인. 무료 MCP 스택 기본
