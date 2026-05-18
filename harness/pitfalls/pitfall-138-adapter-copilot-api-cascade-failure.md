---
slug: pitfall-138-adapter-copilot-api-cascade-failure
title: connect-ai-adapter가 copilot-api(4141) fail 시 claude-cli 모델까지 0으로 반환하여 Connect AI가 LM Studio 1234 fallback 시도
date: 2026-05-09
tags: [connect-ai, adapter, copilot-api, fault-tolerance, oauth, cascade-failure]
severity: high
---

# adapter copilot-api 의존성 — 4141 fail 시 claude-cli 모델까지 노출 안 됨

## 증상
- Connect AI에서 CEO `claude-opus-4.7` 호출 시 에러:
  ```
  ⚠️ CEO 호출 실패: connect ECONNREFUSED 127.0.0.1:1234
  💡 LLM 서버에 연결 못함 — Ollama/LM Studio가 켜져 있는지 확인.
  ```
- claude-opus-4.7는 claude CLI 라우팅이라 copilot-api와 **무관**해야 하는데 1234(LM Studio)로 fallback

## 원인 (cascade failure)
1. `copilot-api` (4141) 다운 — GitHub Copilot 토큰 발급 실패 (`Failed to get Copilot token`, OAuth 갱신 후에도 재발)
2. adapter `do_GET("/api/tags")` line 510에서 `http_call("GET", "/v1/models")` 호출 → 4141 ECONNREFUSED → 예외
3. line 568 except 블록에서 502 반환 → **ANTHROPIC_CLI_EXCLUSIVE / CODEX_CLI_EXCLUSIVE / OPENAI_DIRECT_MODELS 강제 추가 코드(line 528~566) 도달 못함**
4. Connect AI extension이 0 models 받고 LM Studio 1234 자동 fallback 시도
5. LM Studio도 안 켜져 있으니 ECONNREFUSED 1234

**핵심**: claude CLI 라우팅 모델은 copilot-api 무관인데도 adapter 구조상 같이 죽음.

## 해결 (P12)
adapter `do_GET("/api/tags")` 내부에서 copilot-api fetch만 격리된 try/except로 감싸서 fail해도 빈 upstream 데이터로 진행:
```python
try:
    status, body, _ = http_call("GET", "/v1/models")
    upstream = json.loads(body)
except Exception as _e_upstream:
    sys.stderr.write(f"copilot-api(/v1/models) fetch fail — claude-cli only mode: {_e_upstream}\n")
    upstream = {"data": []}
wl = get_whitelist()
# 이후 ANTHROPIC_CLI_EXCLUSIVE / CODEX_CLI_EXCLUSIVE / OPENAI_DIRECT_MODELS 강제 추가 코드는 정상 실행
```

## 검증
P12 적용 후 `curl http://127.0.0.1:4142/api/tags`:
```
4 models:
  claude-opus-4.7  ← claude CLI 라우팅 (Anthropic Pro/Max)
  claude-opus-4.6  ← claude CLI 라우팅
  gpt-5.3-codex    ← codex CLI
  gpt-5.5          ← OpenAI direct
```
copilot-api 다운 상태에서도 claude/codex/openai-direct 라우팅은 정상.

## 재발 방지
1. **모든 외부 의존성 fetch는 격리된 try/except로** — cascade failure 차단
2. **각 라우팅 경로(claude-cli, codex-cli, openai-direct, copilot-api)는 독립 fault domain** — 한쪽 fail이 다른 쪽 막으면 안 됨
3. **GitHub Copilot Pro 구독 만료 알림 추가** 검토 — 본 케이스에서 OAuth는 정상 통과(Hwani-Net)했으나 token 발급은 fail. 구독 상태 확인 필요

## 관련 파일
- `D:/jamesclew/harness/scripts/connect-ai-adapter/adapter_v3.py` (line 506~570 do_GET)
- `C:/temp/bench/connect_ai_adapter_v3.py` (production, watchdog 자동 재spawn)
- `D:/jamesclew/harness/scripts/connect-ai-adapter/repatch-extension.ps1` (P12 후속 등록 권장)

## 인용 (대표님 원문)
> "claude code를 호출해야 opus가 되는거 아니야? copilot이랑 관계 없는거 아냐?"

대표님 통찰 정확. claude-opus-4.7 = claude CLI 라우팅. copilot-api는 별개 라우팅(GPT-* 모델). adapter의 모델 목록 fetch가 copilot-api 한 곳에만 의존하던 구조 결함이 진짜 원인.

## 관련 PITFALL
- pitfall-136 adapter-cwd-system32-surrogate-corruption (adapter Popen cwd)
- pitfall-137 powershell-stderr-cp949-corruption (P11 PowerShell wrap)
