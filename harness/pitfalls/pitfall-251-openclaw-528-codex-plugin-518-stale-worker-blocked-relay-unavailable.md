# P-251: openclaw 5.28 업데이트가 @openclaw/codex 플러그인 5.18 방치 → codex 워커 기동불가("Native hook relay unavailable"의 진짜 원인)

- **발견/해결**: 2026-06-02 (대표님 "고쳐" → 워커 실증으로 relay socket 가설 기각, 진짜 원인 확정)
- **영향**: codex 워커(TARS)가 도구 첫 명령부터 차단 → 8세션 자율진행 멈춤. 표면 증상은 "Native hook relay unavailable"이라 relay socket 문제로 오인(P-250 초기 가설).

## 증상
- codex 워커 도구 실행 시 PreToolUse에서 `Native hook relay unavailable`.
- `/tmp/openclaw-native-hook-relays-<uid>/` socket 0개 → "relay 죽음"으로 오판하기 쉬움.
- gateway restart 무효. 8세션 반복.

## 근본 원인 (워커 실증으로 확정 — 추측 기각)
**relay socket 문제가 아니라 codex 워커 플러그인 버전 불일치.** `openclaw agent --agent codex -m "echo 실행"` 실증 시 진짜 에러 노출:
```
Package subpath './plugin-sdk/codex-native-task-runtime' is not defined by "exports"
in .../@openclaw/codex/node_modules/openclaw/package.json
```
- main openclaw **5.28**인데 `@openclaw/codex` 플러그인은 **5.18**(구버전) 방치.
- 5.18 플러그인 dist가 `openclaw/plugin-sdk/codex-native-task-runtime`을 import하는데, **5.28에서 이 export가 `agent-harness-task-runtime`으로 개명**되어 사라짐 → codex 워커 기동 자체 실패 → 도구 호출 전 차단 → 표면상 "relay unavailable".
- 즉 OpenClaw 자동 업데이트가 main(`npm i -g openclaw`)만 올리고 **별도 설치 플러그인 `@openclaw/codex`는 안 올림** → 버전 드리프트(P-229/P-249 계보).

## 해결 (검증됨)
1. backup: `cp -r ~/.openclaw/npm/node_modules/@openclaw/codex /tmp/codex-plugin-bak-518`
2. `cd ~/.openclaw/npm && npm install @openclaw/codex@2026.5.28` (npm에 5.28 존재 확인 후)
   - 설치 후 dist가 `agent-harness-task-runtime`(새 경로) import + nested openclaw 정리 확인.
3. **gateway restart 필수** — gateway가 설치 전 5.18 플러그인을 메모리 캐시하므로 reload 안 하면 같은 에러 지속(이 단계 빠뜨려서 1회 헛심).
4. 검증: `openclaw agent --agent codex -m "bash로 echo relay-ok-test 실행"` → **`relay-ok-test` 출력 성공** = 워커 도구 실행 회복. 9봇 connected 유지.

## 잔여 (작동 중이라 미수정)
- `@openclaw/discord` 5.18, `@openclaw/acpx` 5.18도 방치 상태. **단 discord는 9봇 connected로 작동 중**(codex만 native-task-runtime 개명 영향, discord는 5.28 호환) → 지금 건드리면 9봇 끊길 위험이라 보호(P-243). 다음 안정적 시점에 5.28 정합 권장.
- claude(EVE)/ollama(Data) 워커는 codex harness가 아닌 claude-cli/ollama harness라 별도 — 감사에서 차단된 건 codex(TARS)만.

## 재발 방지 (핵심 교훈)
- **"Native hook relay unavailable" = relay socket 죽음으로 단정 금지.** socket 0개는 워커 미활성 시 정상(동적 생성). **워커 실증(`openclaw agent --agent <id> -m "echo"`)으로 진짜 에러를 노출**시킨 뒤 판단 — 이게 relay socket 추측 수정(9봇 위험)을 막았다.
- **OpenClaw 자동 업데이트 후 반드시 `@openclaw/*` 플러그인 버전을 main과 대조**: `for p in ~/.openclaw/npm/node_modules/@openclaw/*/; do version 확인; done`. main만 올라가고 플러그인 5.18 방치 = 워커 기동불가 시한폭탄.
- 플러그인 설치 후 **gateway restart**로 메모리 캐시 갱신 필수.

## 관련
- [[pitfall-250-openclaw-native-hook-relay-down-worker-tools-blocked-empty-tikitaka]] (초기 가설 = relay socket. 이 문서가 진짜 원인으로 정정)
- [[pitfall-249-openclaw-528-agentruntime-key-removed-gateway-startup-failed]] (같은 5.28 업데이트 다른 파손)
- [[pitfall-229-openclaw-522-harness-bug-527-recovery]] (버전 자동 업데이트 = 시한폭탄 원형)
