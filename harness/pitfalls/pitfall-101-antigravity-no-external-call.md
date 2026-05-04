---
slug: pitfall-101-antigravity-no-external-call
title: Antigravity IDE는 외부 CLI/HTTP 호출 진입점 없음
tags: [antigravity, validation, gui-only, premature-conclusion]
date: 2026-05-03
---

# 증상
Antigravity Pro quota 처치(캐시 삭제 + OAuth 재인증) 후 5h 리셋 vs multi-day 락 여부 검증을 외부에서 시도.

# 원인
Antigravity는 VS Code fork IDE — 단일 `.exe` 실행파일만 노출.
- CLI 진입점 없음 (Antigravity.exe는 GUI launcher)
- 자체 OAuth + 내장 Chromium 브라우저 (토큰 외부 추출 불가)
- Connect AI 확장의 4825 브리지는 Ollama/LM Studio 프록시 전용 (Antigravity Gemini 호출 경로 아님)
- gemini CLI는 별도 OAuth 풀 (ToS 차단 시 GUI와 무관)

# 해결
처치 후 quota 검증은 다음 중 하나로만 가능:
1. **대표님 GUI 직접 호출** (가장 빠름)
2. **desktop-control MCP** 키보드 자동화로 채팅 입력 + 응답 캡처 (토큰 비싸지만 가능)
3. Antigravity 로그 파일(`AppData\Roaming\Antigravity\logs\*\auth.log`)에서 quota 응답 패턴 추적

# 재발 방지
처치 보고 시 "검증은 GUI에서 가능"을 사전 명시. 외부 검증 가능한 것처럼 떠넘기는 declare-no-execute 패턴 회피.
