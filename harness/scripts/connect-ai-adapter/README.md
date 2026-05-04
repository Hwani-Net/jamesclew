# Connect AI ↔ copilot-api ↔ Anthropic CLI Adapter

Antigravity의 Connect AI 확장(`connectailab.connect-ai-lab`)을 GitHub Copilot Pro 풀 + Anthropic Pro/Max OAuth 풀 양쪽에 동시 라우팅하는 Ollama API emulator.

## 아키텍처
```
[Windows 로그인]
    └─ Startup\connect_ai_adapter.vbs
         └─ python adapter_watchdog.py            ← NSSM 동등 watchdog
              └─ subprocess.Popen(adapter_v3.py)  ← 죽으면 backoff 후 재spawn

Antigravity Connect AI (다중 창 OK)
   ↓ ollamaUrl=http://127.0.0.1:4142, stream=true
adapter_v3.py (Ollama emulator, 4142)
   ├─ claude-* 모델  → claude -p subprocess  → Anthropic Pro/Max OAuth 풀
   └─ 그 외        → http://127.0.0.1:4141 → copilot-api → GitHub Copilot Pro 풀

[일일 03:00]
    └─ schtasks: cleanup_antigravity.ps1 (orphan 프로세스 정리)
```

## 핵심 기능
- `/api/tags` — `/chat/completions` 호환 모델만 노출 (codex 류 제외) + Opus 4.7/4.6 강제 추가 (claude-cli 전용)
- `/api/chat` stream:true — Ollama NDJSON 2-chunk 응답
- claude-* 모델 → `claude -p` subprocess (Anthropic 직접, multiplier 0)
- 미지원 모델 → `gpt-4.1` 자동 fallback (`X-Model-Fallback` 헤더)
- 화이트리스트 5분 TTL 캐시
- 환경변수 `CLAUDE_VIA_CLI=0` 으로 claude-cli 라우팅 비활성 가능

## 노출 모델 (11개)
| 모델 | 라우팅 | 풀 |
|------|--------|------|
| claude-opus-4.7 / 4.6 | claude -p subprocess | **Anthropic Pro/Max** (multiplier 0) |
| claude-sonnet-4.6 / 4.5 / 4 | claude -p subprocess | Anthropic Pro/Max |
| claude-haiku-4.5 | claude -p subprocess | Anthropic Pro/Max |
| gpt-5.4 / 5.2 / 5-mini | copilot-api | GitHub Copilot Pro |
| gemini-3.1-pro-preview | copilot-api | GitHub Copilot Pro |
| oswe-vscode-prime | copilot-api | GitHub Copilot Pro |

## 영구화 (3계층)
| 계층 | 도구 | 효과 |
|------|------|------|
| **Auto-start** | `Startup\connect_ai_adapter.vbs` (vbs) | 사용자 로그인 시 자동 가동 |
| **Watchdog** | `adapter_watchdog.py` (Python loop) | 어댑터 crash 시 backoff 3→60s로 재spawn (NSSM 동등) |
| **Cleanup** | `schtasks JamesClaw\AntigravityCleanup` (DAILY 03:00) | Antigravity orphan 프로세스 정리 |

설치 (사용자 권한, admin 불필요):
```powershell
copy startup_adapter.vbs "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\connect_ai_adapter.vbs"
copy startup_ollama.vbs  "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\ollama_tray.vbs"
schtasks /Create /TN 'JamesClaw\AntigravityCleanup' /TR 'powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\temp\bench\cleanup_antigravity.ps1' /SC DAILY /ST 03:00 /F
```

## Antigravity Connect AI 설정
`$APPDATA/Antigravity/User/settings.json`:
```jsonc
"connectAiLab.ollamaUrl": "http://127.0.0.1:4142",
"connectAiLab.defaultModel": "gpt-4.1"
```

## extension.js 패치 (3건)
**`patch_extension.ps1`** 실행 — Antigravity 확장 업데이트(v2.46.4+) 시 재실행 필요:
1. **PIN Gate Bypass** — `corporateUnlocked=false` → `true` (AI SOLOPRENEUR 0101 모달 제거)
2. **Interview Wizard Skip** — `showInterviewCard()` no-op (회사 setup 자동 차단)
3. **Multi-Window 4825 EADDRINUSE** — `server.on("error")`에서 silently skip (다중 창 동시 운영 OK, 수동 패치)

```powershell
powershell -ExecutionPolicy Bypass -File patch_extension.ps1
# 후 Ctrl+Shift+P → 'Reload Window'
```

## 검증
```bash
# 모델 목록 (11개)
curl http://127.0.0.1:4142/api/tags

# Stream 채팅 (claude-cli 라우팅 — Anthropic Pro/Max)
curl -N -X POST http://127.0.0.1:4142/api/chat \
  -H "Content-Type: application/json" \
  -d '{"model":"claude-opus-4.7","messages":[{"role":"user","content":"Hi"}],"stream":true}'

# Watchdog 자동 복구 검증
$pid=(Get-NetTCPConnection -LocalPort 4142 -State Listen).OwningProcess
Stop-Process -Id $pid -Force
Start-Sleep 6
netstat -ano | findstr ":4142.*LISTENING"  # 새 PID로 자동 복구
```

## 관련 PITFALL
- pitfall-105 opencode-claude-via-antigravity-banned (Antigravity OAuth → Claude 차단)
- pitfall-106 ollama-emulator-missing-stream (NDJSON 미구현 시 무한 대기)
- pitfall-107 connect-ai-multi-window-4825 (다중 창 4825 EADDRINUSE 충돌)

## 의존성
- Python 3.11+ (표준 라이브러리만)
- copilot-api 4141 가동
- claude CLI v2.1.126+ (Anthropic Pro/Max 인증)
- Connect AI 확장 v2.46.3+
