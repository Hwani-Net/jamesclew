---
slug: pitfall-141-connect-ai-extension-14h-debug-summary
title: Connect AI v2.89.58 분배 호출 응답 "OK" 6 token — 14시간+ 디버깅 후 upstream 의존 결론
date: 2026-05-09
tags: [connect-ai, debugging-summary, stream-parsing, upstream-issue, b-mode]
severity: critical
debug_time: 14h+
hypotheses_wrong: 14
fixes_applied: 14
final_verdict: upstream-dependency
---

# Connect AI v2.89.58 분배 호출 — 14시간 디버깅 후 upstream 의존 결론 (B 모드)

## 증상
- Connect AI Chat에서 CEO 분배 명령 시 매번:
  ```
  ⚠️ CEO가 작업 분배 계획(JSON)을 생성하지 못했어요.
  원본 응답:
  ```
- 또는 `API Error: 400 invalid high surrogate at column 909`
- 또는 `ECONNREFUSED 127.0.0.1:1234`
- 또는 빈 응답

## 14시간+ 디버깅 결과 — 모든 인프라 정상 검증
| 영역 | 검증 |
|------|------|
| adapter 4142 | ✅ 정상 (P9~P15 + cwd + sanitize 모두 적용) |
| claude CLI v2.1.137 | ✅ 정상 (직접 18KB prompt → 1357 token JSON 응답) |
| Anthropic API | ✅ 정상 (`is_error: false`) |
| repatch-extension.ps1 | ✅ 정상 (1시간 자동 patch + BOM 보존) |
| memory + decisions + chat | ✅ clean slate (모두 mojibake 0) |
| agent_models | ✅ 모두 claude-opus 통일 |

## 진짜 원인 — Connect AI extension의 응답 파싱 (upstream)
직접 시뮬레이션:
```python
result = subprocess.run(
    'claude -p --model claude-opus-4-7 --output-format text',
    input=prompt,  # 11KB
    shell=True, encoding='utf-8',
    cwd="D:/conneteailab"
)
# duration 38.9s, 정상 1357 token JSON 응답
```

같은 코드 + 같은 prompt로 adapter 호출 시:
```
adapter log: POST /v1/chat/completions 200 OK
응답 내용:    "OK" 6 tokens
Connect AI:  "원본 응답: " (빈 표시)
```

**adapter는 정상 forward**. Connect AI extension이 stream 응답 파싱 어디선가 drop. minified bundle 통제 외 코드.

## 14개 patch 누적 (모두 적용 + 자동 보존)
1. adapter cwd hardcode (`C:\Windows\System32` 회피)
2. P9 surrogate sanitize
3. P10 axios.post monkey-patch
4. adapter inbody sanitize
5. P11 PowerShell UTF-8 wrap
6. P12 adapter `/api/tags` fault tolerance
7. ps1 UTF-8 BOM 추가
8. extension prompt mojibake cleanup
9. P13 engine recovery 비활성화
10. P14 `127.0.0.1:1234` → `4142` redirect (12건)
11. P15 adapter `/v1/*` fault tolerance + claude-cli fallback
12. memory.md / decisions.md 30KB truncate
13. chat history full reset (chat[]=1, display[]=0)
14. agent_models 통일 (CEO opus + 9 gpt-mini → 모두 claude-opus)

## B 모드 결정 — 새 버전 대기
- Connect AI v2.89.58 minified bundle은 우리 통제 외
- v2.90+ 새 버전 자동 update 시 ps1이 자동 patch 적용
- 모든 인프라 patch는 자동 재적용 (1시간 cron)
- 그동안 Connect AI 사용 중단 (분배 fail 무시)

## 재발 방지 (장기)
1. **외부 minified extension 의존 금지** — 통제 영역 외 코드는 14시간+ 디버깅으로도 root cause 못 잡음
2. **자체 분배 시스템 구축** 검토 — claude CLI + Bash/Python 직접 호출 wrapper
3. **새 버전 update 시 즉시 영향 평가** — 자동 patch 대상이지만 새 fallback 경로 가능성 항상 의심

## 인용 (대표님 통찰)
> "야 혹시 이 프리셋에서 내가 ceo만 opus로 바꾼게 잘못된거 아니야?"

→ agent_models 매핑 cascade 발견. 그러나 통일 후에도 fail = extension 측 문제 확정.

> "야. 아얘 중요 키 등의 중요한 정보들만 두고 이 폴더 자체를 초기화 후 하나하나 다시 진행해보는것은 어때?"

→ Clean slate 진행. 그래도 fail = 인프라 무관, extension upstream 결정.

## 관련 PITFALL
- pitfall-136 adapter-cwd-system32-surrogate-corruption
- pitfall-137 powershell-stderr-cp949-corruption
- pitfall-138 adapter-copilot-api-cascade-failure
- pitfall-139 ps1-no-bom-cp949-mojibake-injection
- pitfall-140 connect-ai-extension-fallback-cascade
