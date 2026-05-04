---
slug: pitfall-105-opencode-claude-via-antigravity-banned
title: OpenCode → Antigravity OAuth → Claude 모델 호출 차단
tags: [opencode, antigravity, claude, third-party-ban, anthropic-tos]
date: 2026-05-03
---

# 증상
OpenCode에서 `google/antigravity-claude-*` 모델 호출 시 즉시 차단:
```
Status: 403
Endpoint: cloudcode-pa.googleapis.com/v1internal:streamGenerateContent
Error: This service has been disabled in this account for violation of Terms of Service
```
- Sonnet 4.6 (non-thinking) 1회 정상 → 직후 thinking variant 호출 시 차단 발동
- 다른 계정으로 폴백해도 즉시 403 (모든 계정 동일 패턴)
- Gemini family는 계속 정상 동작 (계정 자체 ban 아님)

# 원인
Anthropic 2026-04-04 ToS: OAuth 토큰의 third-party 도구 사용 금지.
Antigravity의 Claude 모델 액세스도 Anthropic OAuth 인증을 거치므로, OpenCode 같은 third-party가 호출하면 Google/Anthropic이 차단.

shekohex/opencode-google-antigravity-auth README (2026-02-18):
> "There are reports of Google blocking accounts using this plugin"
→ Claude 호출 시 즉시 트리거 확인.

# 해결
- **Claude는 OpenCode/Antigravity 경유 사용 금지** — 즉시 차단
- 합법 경로 3개:
  1. copilot-api(`localhost:4141`) → `claude-sonnet-4-6` (검증, 12.4초)
  2. `claude -p` subprocess (Pro/Max 구독 직접)
  3. Anthropic API Key (`sk-ant-api03-...`)
- **Gemini는 OpenCode 경유 정상** — Antigravity OAuth 정당 사용

# 재발 방지
1. OpenCode에서 `google/antigravity-claude-*` 모델 호출 금지 (모델 라우팅 정책)
2. 대표님 환경 4계정의 Claude 권한 차단 확정 — 어필 제출 또는 포기
3. 모델 family별 합법 경로 매핑 표 유지:
   | Family | OpenCode/Antigravity | copilot-api | claude -p | API Key |
   |--------|:---:|:---:|:---:|:---:|
   | Gemini | ✅ | ✅(gemini-2.5-pro) | ❌ | ✅ |
   | Claude | ❌ **금지** | ✅ | ✅ | ✅ |
   | GPT | ❌ | ✅ | ❌ | ✅ |
