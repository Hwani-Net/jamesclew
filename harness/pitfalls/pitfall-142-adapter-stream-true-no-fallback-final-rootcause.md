---
slug: pitfall-142-adapter-stream-true-no-fallback-final-rootcause
title: 14시간+ 디버깅의 진짜 root cause — adapter `/v1/chat/completions` stream:true가 4141 dead 시 fallback 없이 hang (P17)
date: 2026-05-09
tags: [connect-ai, adapter, stream-true, sse, fallback, p17, root-cause-final]
severity: critical
debug_time: 14h+
patches_before_real_fix: 16
final_fix: P17
---

# 진짜 root cause — adapter stream:true 처리에서 4141 dead 시 fallback 없이 hang

## 14시간+ 디버깅의 진짜 진실
Connect AI Chat → CEO 분배 명령 → 매번 빈 응답.

P9~P16 + cleanup 등 16개 patch 모두 무관한 표면 fix였음. 진짜 root cause:

```
Connect AI extension → /v1/chat/completions stream:true 호출
adapter (4142)        → http_call(4141) passthrough 시도
copilot-api (4141)    → DEAD (Copilot 토큰 발급 fail)
adapter               → except 진입했으나 P15 fallback은 stream:false만 처리
                        → stream:true → 응답 없이 hang (timeout 120s)
Connect AI            → 빈 응답 → "원본 응답: " 표시
```

## 검증 (결정적 측정)
| 호출 | 결과 |
|------|------|
| 직접 `claude.cmd` shell=False + bytes input | ✅ 35초, 정상 JSON |
| 직접 4142 stream:false POST | ✅ 42초, 200 + JSON |
| 직접 4142 **stream:true** POST | ❌ **120s timeout** (hang) |
| Connect AI 실제 호출 | ❌ 빈 응답 (= stream:true 사용) |

## 해결 (P17)
adapter `/v1/chat/completions` 진입 시점에 stream:true + claude-* 모델 검사 → 즉시 P15 fallback 호출 + SSE single-chunk로 응답:

```python
try_stream_fallback = (
    self.path == "/v1/chat/completions"
    and isinstance(inbody, dict)
    and bool(inbody.get("stream"))
    and CLAUDE_VIA_CLI
    and isinstance(inbody.get("model", ""), str)
    and inbody["model"].startswith("claude-")
)
if try_stream_fallback:
    content, tok = call_claude_cli(model, msgs, timeout=180)
    # SSE chunk format
    self.send_response(200)
    self.send_header("Content-Type", "text/event-stream")
    self.end_headers()
    chunk = {
        "id": "chatcmpl-cli-stream",
        "object": "chat.completion.chunk",
        ...
    }
    self.wfile.write(f"data: {json.dumps(chunk, ensure_ascii=False)}\n\n".encode("utf-8"))
    self.wfile.write(b"data: [DONE]\n\n")
    return
```

`call_claude_cli` 자체도 P16 (shell=False + bytes input + claude.cmd 직접 경로) 적용된 상태.

## 검증된 결과 (대표님 확인)
> "야. 이제야 작업 시작이 되는것 같아"

화면 증거:
- ✅ CEO · 작업 분배 (분배 시작)
- ✅ RESEARCHER · Read로 sessions/researcher/blog-blocker-top1-2026-05-09-f...
- ✅ 🔍 Researcher 데이터 가져오는 중...

## 진짜 교훈 (디버깅 회고)
1. **3시간 차단 룰** 필수 — 외부 코드 디버깅 3시간+ 안 풀리면 자체 우회 시스템 또는 완전히 다른 진단 차원 시도
2. **stream:true vs stream:false 분기 검증** 필수 — Connect AI/OpenAI 호환 client는 대부분 stream:true 기본
3. **adapter 모든 endpoint 모든 모드(stream/non-stream) fault tolerance 필수**
4. **shell=True + Windows + 한국어** 조합은 항상 의심 (P16 — watchdog spawn 환경에서 stdin pipe 차이)
5. **외부 모델 조언 우선** — 14개 patch 시도하기 전 Codex/GPT-4.1 진단 위임이 더 빨랐을 수 있음

## 누적 patch 16개 + P17 (최종)
1. adapter cwd hardcode (C:\Windows\System32 회피)
2. P9 surrogate sanitize
3. P10 axios.post monkey-patch
4. adapter inbody sanitize
5. P11 PowerShell UTF-8 wrap
6. P12 adapter `/api/tags` fault tolerance
7. ps1 UTF-8 BOM 추가
8. extension prompt mojibake cleanup
9. P13 engine recovery 비활성화
10. P14 1234 → 4142 redirect (12건)
11. P15 adapter `/v1/*` non-stream fault tolerance
12. memory.md / decisions.md 30KB truncate
13. chat history full reset
14. agent_models 통일 (claude-opus)
15. 5/8 daily log 1.4MB + 284 mojibake reset
16. **P16 — call_claude_cli shell=False + bytes input + claude.cmd 직접**
17. **P17 — adapter stream:true + claude-* 즉시 P15 fallback + SSE 응답** ← FINAL FIX

## 영구 보존
- production: `C:/temp/bench/connect_ai_adapter_v3.py` (P16 + P17)
- dev source: `D:/jamesclew/harness/scripts/connect-ai-adapter/adapter_v3.py` (sync 완료)
- watchdog 자동 respawn 시 P16 + P17 적용 코드 사용

## 관련 PITFALL
- pitfall-136 adapter-cwd-system32-surrogate-corruption
- pitfall-137 powershell-stderr-cp949-corruption
- pitfall-138 adapter-copilot-api-cascade-failure
- pitfall-139 ps1-no-bom-cp949-mojibake-injection
- pitfall-140 connect-ai-extension-fallback-cascade
- pitfall-141 connect-ai-extension-14h-debug-summary
- **pitfall-142 (this) — 진짜 root cause 발견**

## 인용 (대표님)
> "야. 진행하고, 확인 안하냐?"

→ 즉시 검증 + stream:true vs false 분리 측정 → P17 fix 도출. 14시간 헤매고 마지막 1시간에 진짜 답.
