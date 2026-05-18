---
slug: pitfall-125-p20-only-covers-v1-not-api-chat
title: "P20 redirect가 /v1/chat/completions만 처리 — /api/chat 우회"
date: 2026-05-10
tags: [pitfall, adapter, routing, claude-cli]
---

# 증상
사용자 명시 결정 "Sonnet/Opus 완전 차단" 후에도 claude-sonnet-4.6 polling이 claude-cli로 계속 라우팅. ANTHROPIC_CLI_EXCLUSIVE=[] + P20 확장 적용했지만 효과 없음.

# 원인
- P20 redirect는 `do_POST self.path == "/v1/chat/completions"` 분기에만 구현됨
- Connect AI extension (Antigravity.exe NodeService PID 32592)은 **`/api/chat`** (Ollama 형식)으로 polling
- /api/chat 분기는 use_cli 라우팅(`CLAUDE_VIA_CLI && model.startswith("claude-")`) → claude-cli direct
- ANTHROPIC_CLI_EXCLUSIVE는 /api/tags 노출 + resolve_model 통과 게이트일 뿐, 라우팅 결정자가 아님

# 해결
**/api/chat 분기에도 claude-* redirect 추가**:
- do_POST의 `if use_cli and stream_requested:` 직전에 claude-* 체크 + model swap + ollama-forward 라우팅
- 또는 `CLAUDE_VIA_CLI=0` 환경변수로 모든 claude-cli 라우팅 비활성

# 재발 방지
- 어댑터 P-패치 적용 시 `/v1/chat/completions` + `/api/chat` + `/api/generate` 3개 경로 모두 검토
- "Sonnet/Opus 완전 차단" 같은 정책 결정 시 **모든 진입 경로** 매핑 후 일괄 적용

# 자체 검증
- 본 사례 (2026-05-10 11:20) — 사용자 명시 결정 후 polling 지속 발견
