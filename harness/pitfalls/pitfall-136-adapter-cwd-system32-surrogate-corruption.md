---
slug: pitfall-136-adapter-cwd-system32-surrogate-corruption
title: connect-ai-adapter Popen cwd가 SYSTEM 환경에서 C:\Windows\System32로 결정되어 claude CLI surrogate 검증 실패
date: 2026-05-08
tags: [connect-ai, adapter, claude-cli, cwd, surrogate, hooks, system-environment, debugging]
severity: critical
debug_time: 7시간
wrong_hypotheses: 5
---

# adapter Popen cwd가 SYSTEM 환경에서 C:\Windows\System32로 결정되어 claude CLI 합성 400 에러 발생

## 증상
- Connect AI Chat에서 CEO 모델을 `claude-opus-4.7`로 변경하고 작업 분배 요청
- 매번 동일한 에러: `API Error: 400 The request body is not valid JSON: invalid high surrogate in string: line 1 column 909 (char 908)`
- char 908~911 위치가 매번 거의 같음 → 동일 패턴 반복
- claude-sonnet-4.6에서는 정상 작동
- claude CLI 직접 호출(`echo "test" | claude -p --model claude-opus-4-7`) 정상 응답
- 같은 prompt를 동일 subprocess 방식으로 git bash에서 직접 호출 → SUCCESS

## 잘못 추적한 가설 5개 (7시간 시간 낭비)
| # | 가설 | 결과 |
|---|------|------|
| 1 | Connect AI extension source(v2.89.77 ts)에서 응답 sanitize | source 자체가 사용 안 됨 (마켓플레이스 v2.89.58 별도) |
| 2 | 마켓플레이스 extension.js에 _dsan(body) wrap (P9) | 객체 리터럴 페이로드 미커버 |
| 3 | axios_default.post monkey-patch (P10) | 모든 axios.post cover했으나 효과 없음 |
| 4 | adapter_v3.py inbody sanitize (Python re-serialize) | 효과 없음 |
| 5 | Windows stdin pipe 64KB truncation | 192KB prompt 직접 호출 OK, 가설 무효 |

**정답 (6번째)**: adapter_v3.py의 subprocess.Popen이 cwd를 명시하지 않아 SYSTEM 환경의 USERPROFILE(`C:\Windows\System32`)을 inherit. claude CLI가 거기서 SessionStart hooks 실행 → hooks가 path resolution 시 SYSTEM 환경에서 비정상 결과 (한글/utf-16 변환 깨짐) → claude CLI v2.1.132+의 client-side surrogate 검증이 invalid 감지 → 합성 400 에러 (`model:"<synthetic>"`, `duration_api_ms:0`).

## 결정적 증거
- DIAG 추가 후 stdout dump의 `init` 라인: `"cwd":"C:\\Windows\\System32"` (SYSTEM watchdog spawn 환경)
- 같은 prompt로 git bash 직접 실행: `"cwd":"D:\\AI 비즈니스\\conneteailab"` → SUCCESS
- adapter watchdog는 사용자 startup vbs로 launch → 사용자 환경이지만 USERPROFILE 환경변수가 SYSTEM값으로 set됨 (vbs 내부 또는 Windows scheduler 영향)
- `model:"<synthetic>"` + `duration_api_ms:0` = **claude CLI client-side에서 invalid surrogate 감지하여 Anthropic API 호출 자체 안 함**

## 해결
`D:/jamesclew/harness/scripts/connect-ai-adapter/adapter_v3.py` 의 두 subprocess 호출(`call_claude_cli`, `call_claude_cli_stream`)에 `cwd=` 명시:

```python
_safe_cwd = "D:/conneteailab" if os.path.isdir("D:/conneteailab") else (os.environ.get("USERPROFILE") or "C:/Users/AIcreator")
proc = subprocess.Popen(..., cwd=_safe_cwd, ...)
```

production 동기:
```bash
cp D:/jamesclew/harness/scripts/connect-ai-adapter/adapter_v3.py /c/temp/bench/connect_ai_adapter_v3.py
# watchdog가 PID kill 시 자동 재spawn
```

watchdog 환경에서 D:/conneteailab junction이 안 보일 수 있으므로 USERPROFILE fallback 필수. fallback 시 `C:\Users\AIcreator` 사용 → SYSTEM의 `C:\Windows\System32` 회피.

## 재발 방지 체크리스트
1. **모든 subprocess.Popen / subprocess.run 호출에 `cwd=` 명시** (특히 startup/watchdog로 launch되는 daemon)
2. **claude CLI는 cwd 의존성 강함** — SessionStart hooks 발동 + system context에 cwd 기반 path 포함. 안전한 user home 또는 명시적 workspace 디렉토리만 사용
3. **추측 4번 후 측정 강제** — 동일 가설 변형 반복 금지. DIAG dump 추가 우선 (CLAUDE.md Ghost Mode + Search-Before-Solve)
4. **`model:"<synthetic>"` + `duration_api_ms:0` 패턴은 client-side 거부 신호** — 절대 Anthropic API에 도달 안 함. 페이로드 sanitize는 무의미

## 진단 도구 (영구 보존 권장)
adapter_v3.py 의 DIAG-STREAM 블록 (call_claude_cli_stream 내부):
- prompt 길이/dump (`diag_stream_prompt_*.txt`)
- stdout 전체 라인 dump (`diag_stream_stdout_*.log`)
- stderr 전체 dump (`diag_stream_stderr_*.log`)
- exit code + last_text 길이 stderr 로깅

이 dump는 향후 동일 패턴 발생 시 init 라인의 cwd만 보면 즉시 식별 가능.

## 인용 (대표님 원문)
> "B로 진행해"

5번 헛된 추측 후 측정 1번으로 정답 도달. 진단 7시간 소요. 대표님 시간 손실 인정.

## 관련 PITFALL
- pitfall-105 opencode-claude-via-antigravity-banned (Antigravity OAuth Claude 차단)
- pitfall-131 korean-ui-english-menu-mismatch (Connect AI LLM이 환경 모름)
- pitfall-133 connect-ai-agent-self-coding-limitation (Connect AI 자기 코드 모름)

## 관련 파일
- `D:/jamesclew/harness/scripts/connect-ai-adapter/adapter_v3.py` (line 109~150)
- `C:/temp/bench/connect_ai_adapter_v3.py` (production)
- `C:/temp/bench/diag_stream_*.{txt,log}` (DIAG 진단 자료)
