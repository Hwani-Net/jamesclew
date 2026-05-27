# PITFALL-195: OpenClaw `claude-cli` agent harness 등록 실패 — anthropic 모델 swap 후

## 증상

OpenClaw에서 nyongjong(main agent) 모델을 `anthropic/claude-opus-4-7`로 swap 후 Discord 사용자 메시지에 다음 에러로 응답 실패:

```
⚠️ Requested agent harness "claude-cli" is not registered.
```

또는 silent fail (Discord 채팅창에 아무것도 표시 안 됨).

게이트웨이 로그:
```
[diagnostic] message dispatch completed: ... source=replyResolver outcome=error
error="MissingAgentHarnessError: Requested agent harness \"claude-cli\" is not registered."
```

## 핵심 단서 — 두 경로가 다르게 동작

- **`agent/cli-backend`** (heartbeat 호출): ✅ claude-cli 정상 동작
- **`replyResolver`** (user message 호출): ❌ MissingAgentHarnessError

같은 게이트웨이, 같은 runtime이지만 두 경로의 runtime registry lookup이 다른 결과 반환.

## 환경

- OpenClaw v2026.5.18 + v2026.5.22 둘 다 동일 에러 (4 버전 차이 fix 안 함)
- nyongjong agent의 model: `anthropic/claude-opus-4-7`
- runtime: `claude-cli`
- WSL2 Ubuntu, Discord 4-bot setup
- 2026-05-24 ORCHESTRATION.md 42KB → 14.5KB 트림 후 system prompt 변경된 시점에 발생 시작

## 시도한 fix (모두 실패)

1. **게이트웨이 재시작 2회** → 25분 후 같은 에러 재발 (Issue #72434 패턴과 일치)
2. **OpenClaw v2026.5.18 → v2026.5.22 npm update** → 같은 에러 재발
3. **GitHub Issue #84604의 confirmed fix** (`~/.openclaw/agents/main/agent/auth-state.json`에 `lastGood.claude-cli: anthropic:claude-cli` 매핑 추가) → 같은 에러 재발
4. **`anthropic:claude-cli` profile** 이미 `auth-profiles.json`에 존재했음 (sk-ant-oat01-...) → 그래도 fail

## 우회 (즉시 운영 복구)

**`openclaw.json` primary model을 GPT-5.5로 복귀:**

```diff
"model": {
-  "primary": "anthropic/claude-opus-4-7"
+  "primary": "openai/gpt-5.5"
}
```

이유:
- GPT-5.5는 `codex` runtime 사용 → claude-cli harness 호출 안 함 → 에러 발생 0
- 어제(2026-05-24)까지 정상 작동 입증됨
- Trade-off: Opus 1M context 손실. 단 200KB transcript 패치 + ORCHESTRATION.md 트림으로 context 유지는 어느 정도 보강됨.

## 재발 방지 / 다음 세션 가드

1. **anthropic 모델로 swap 시도 전** 반드시 GitHub openclaw issue tracker 검색:
   - 키워드: `MissingAgentHarness claude-cli not registered`
   - 알려진 regression: v2026.4.24, v2026.5.18, v2026.5.22 모두 영향
2. **모델 swap 후 즉시 실증 테스트**: heartbeat 작동 ≠ user message 작동. **반드시 사용자 메시지로 검증**.
3. **GitHub fix 적용 시도 시간 한계**: 1시간 안에 fix 안 되면 GPT-5.5로 임시 우회. 시간 비용 vs 운영 정상화.
4. **우회 후 fix 후속 작업**: `commands/openclaw-claude-cli-recovery.md` skill로 디버깅 절차 누적.

## 관련 GitHub Issues

- [#84604 — 4.x → 5.18 upgrade leaves claude-cli harness unregistered (auth-profile mapping not migrated)](https://github.com/openclaw/openclaw/issues/84604)
- [#72434 — Regression in 2026.4.24: agent harness "claude-cli" is not registered, all gateway requests fail](https://github.com/openclaw/openclaw/issues/72434)
- [#61093 — claude-cli backend fails to register model catalog](https://github.com/openclaw/openclaw/issues/61093)
- [#81649 — Agent harness "anthropic" not registered - Plugin fails to load on version 2026.5.7](https://github.com/openclaw/openclaw/issues/81649)

## 적용 이력

- 2026-05-25 01:10 — 옵션 A 적용 (nyongjong primary GPT-5.5 복귀)
- 백업 위치: `~/.openclaw/openclaw.json.bak-20260525-011017-pre-gpt5.5-rollback`
- PITFALL 등록: 2026-05-25 01:13
- **2026-05-25 01:21 — 진짜 fix 발견**: 모델 swap만으로 부족. **stuck Opus session** (179% context overflow, claude-cli runtime) 자체를 archive 처리해야 fresh state.
  - Stuck session 식별: `openclaw sessions list`에서 context > 100% 또는 모델이 기대값과 다른 항목
  - Archive 명령:
    ```bash
    mkdir -p ~/.openclaw/agents/main/sessions/_archive-$(date +%Y%m%d)
    mv ~/.openclaw/agents/main/sessions/<sessionId>-topic-<channelId>.* \
       ~/.openclaw/agents/main/sessions/_archive-$(date +%Y%m%d)/
    python3 -c "
    import json; p='~/.openclaw/agents/main/sessions/sessions.json'
    d=json.load(open(p)); del d['agent:main:discord:channel:<channelId>']
    json.dump(d, open(p,'w'), indent=2, ensure_ascii=False)
    "
    systemctl --user restart openclaw-gateway.service
    ```
  - 검증: 01:27 대표님 "테스트" → nyongjong "대표님, 수신 정상입니다. 🐙" 1분 안에 응답
- 백업 위치: `~/.openclaw/agents/main/sessions/sessions.json.bak-20260525-012139-pre-stuck-cleanup`

## 향후 복귀 트리거 조건

다음 중 하나라도 충족되면 Opus 4.7 복귀 재시도:
- OpenClaw 새 버전(v2026.5.23+) 출시 + changelog에 `claude-cli` 또는 `MissingAgentHarness` fix 명시
- GitHub Issue #84604, #72434 등 closed 상태로 변경 + 추가 confirmed fix 발견
- anthropic plugin source code 깊은 디버깅으로 root cause 직접 fix
