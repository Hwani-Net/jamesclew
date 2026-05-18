---
slug: pitfall-145-perplexity-replaced-use-tavily
title: "Connect AI 에이전트에 Perplexity 참조 금지"
symptom: "에이전트 goal.md/tools에 Perplexity 검색 도구를 반복 기재"
date: 2026-05-11
tags: [connect-ai, perplexity, tavily, search-tools]
---

## 증상
Connect AI 에이전트(Writer, Researcher 등) 설정 파일에
`Perplexity/Tavily로 리서치` 형식으로 Perplexity를 계속 포함시킴.

## 원인
JamesClaw 하네스(CLAUDE.md)에는 Perplexity가 여전히 등록되어 있어서
학습 데이터처럼 자동으로 포함됨.
Connect AI 에이전트 컨텍스트에서는 이미 대체 완료됨.

## 해결
Connect AI 에이전트 파일에서 Perplexity 참조 제거.
대체 도구: **Tavily + naver_search** (Researcher tools.md 1순위 기준)

## 재발 방지
**Why:** Connect AI 에이전트 설정(goal.md, tools.md, prompt.md)에는
Perplexity를 절대 쓰지 않는다. Tavily/naver_search가 대체재.
**How to apply:** Connect AI 관련 파일 작성 시 "Perplexity" 단어 등장하면
즉시 Tavily로 교체.
