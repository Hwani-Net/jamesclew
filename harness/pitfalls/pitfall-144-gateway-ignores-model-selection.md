---
slug: pitfall-144-gateway-ignores-model-selection
title: "gateway가 모델 선택 무시하고 항상 Claude 사용"
symptom: "Connect AI UI에서 exaone3.5:32b 선택해도 실제로는 Claude가 응답"
date: 2026-05-11
tags: [claude-gateway, connect-ai, model-routing, design]
---

## 증상
`ollamaUrl`을 gateway 포트(8082)로 설정하면 모든 에이전트 요청이 gateway로 라우팅됨.
gateway가 payload의 `model` 필드를 무시하고 무조건 `claude --print` 호출.
UI에서 exaone3.5:32b를 선택한 CEO 에이전트도 실제로는 Claude Max가 응답.

## 원인
최초 gateway 설계 시 "claude 모델만 처리" 분기 없이 모든 요청을 Claude로 보냄.
`model` 파라미터 체크 누락.

## 해결
gateway에 스마트 라우팅 추가:
- `CLAUDE_MODEL_NAMES = {'claude', 'claude-max', 'claude-gateway'}`
- model이 위 집합에 포함되면 → `claude --print` (Claude Max)
- 그 외 → `http://127.0.0.1:11434` 실제 Ollama로 투명 프록시

## 재발 방지
gateway/proxy 설계 시 반드시 "선택된 모델이 실제로 동작하는가?" 검증.
ollamaUrl 단일 포인트로 모든 요청을 받는 구조에서는 모델 기반 라우팅 필수.
**Why:** 사용자가 UI에서 모델을 선택할 수 있으면, gateway는 그 선택을 존중해야 함.
