# P-250: OpenClaw native hook relay 사망 → 워커(TARS) 도구 전면 차단 = "빈 바퀴 티키타카" (자율진행 멈춤 근본)

- **발견**: 2026-06-02 (대표님 "JARVIS 분배·반환 잘 했는지, 문제 분석하라" + codex 교차)
- **영향**: JARVIS 분배·반환 메시징은 정상인데 워커가 실제 작업을 0건 수행 → 자율진행이 반복적으로 멈추고 대표님께 보고만 반복(분노 누적). 8개 group 세션에서 반복.

> ⚠️ **정정 (2026-06-02): 이 문서의 "relay socket 죽음/생명주기" 가설은 오진이었다.** 워커 실증(`openclaw agent --agent codex -m "echo"`) 결과 진짜 원인은 **@openclaw/codex 플러그인 5.18 방치로 인한 워커 기동 불가**([[pitfall-251-openclaw-528-codex-plugin-518-stale-worker-blocked-relay-unavailable]])였다. socket 0개는 워커 미활성 시 정상(동적 생성)이었고, relay socket을 추측 수정하지 않은 게 9봇을 지켰다. 아래 socket 관련 해결책(경로 이전 등)은 미적용·불필요.

## 증상
- group(Discord) 세션 실측: JARVIS→`@TARS`/`@EVE` 분배 정상(20건/세션), 워커→`@JARVIS` 반환도 형식상 정상(8건).
- **그러나 TARS(codex 워커)가 첫 명령(`echo relay-ok`/pwd/find/package.json 확인)부터 PreToolUse hook에서 `Native hook relay unavailable`로 전건 차단** → 실질 작업 0.
- gateway restart로도 재사망(직후 RELAY_OK였다가 다시 RELAY_DOWN). 8개 세션 반복.
- 대표님 체감: "멘션하는데 못 봄", "또 막혔어", "자율진행이 뭔지 알기나 해", "진짜 짜증나".

## 근본 원인 (실측 + codex 교차 — 단일 경계면 장애)
**오케스트레이션(분배/반환) 문제가 아니라 워커 PreToolUse hook ↔ native relay socket 구간 장애.** relay = unix socket bridge로 워커 도구호출을 gateway에 중계 → 죽으면 도구 전부 차단.

3가설 × 실측:
1. **socket 경로/생명주기** — `/tmp/openclaw-native-hook-relays-<uid>/` 디렉토리는 존재하나 **socket 파일 0개**(실측, 빈 디렉토리). /tmp + WSL2/systemd-user/UID/TMPDIR/stale정리로 socket 소멸 가능.
2. **relay 서버 accept loop 사망** — gateway 프로세스는 active인데 listener만 죽음(FD 누수/EMFILE/uncaught exception/idle).
3. **hook CLI fail-closed (확정)** — `dist/hooks-cli-*.js`가 "relay unavailable이면 모든 도구 차단"으로 하드코딩(`isNativeHookRelayBridgeStaleRegistrationError`→`renderNativeHookRelayUnavailableResponse`). `registrationTimeoutMs: 100`(100ms, 매우 짧음). node_modules 직접 patch는 npm 재설치 시 소멸.

**gateway restart 무효 이유**: 프로세스만 재생성, 근본(socket 경로/listener/fail-closed/소멸 패치) 그대로 → 같은 조건 재사망. watchdog 20분 debounce가 재사망 직후 복구를 막는 역효과.

## 해결 방향 (미적용 — 봇 인프라 코드, 대표님 결정 + TARS 구현 게이트)
1. **즉효(피해 축소)**: 저위험 도구(`echo`/`pwd`/`find`)는 **fail-open/degraded mode** — relay 죽어도 워커가 진단·기본작업 가능하게. 전역 차단 과확대 제거.
2. **영속**:
   - socket을 `/tmp` → `/run/user/<uid>/openclaw/native-hook-relay.sock`($XDG_RUNTIME_DIR) 이전 + systemd `RuntimeDirectory`, perm 0700, readiness check.
   - relay 서버 listener `close/error/uncaughtException/unhandledRejection` 핸들링 + 같은 프로세스 내 socket 재바인딩. systemd `Restart=always`/`WatchdogSec`/`LimitNOFILE`.
   - patch-package를 `postinstall`에 연결(또는 fork 고정/lockfile pinning) — npm 재설치 생존.
   - watchdog debounce를 재사망 시엔 단축(현 20분은 재사망 직후 복구 차단).

## "우리 hook 때문인가? 다 지우면 자율진행 되나?" 검증 (2026-06-02 대표님 가설 + codex 공식문서)
- **결론: 절반만 맞음.** relay 장애는 우리 hook이 직접 원인이 **아니다**.
- **native hook relay = OpenClaw Codex harness 구조적 기능** — codex가 공식문서(`docs.openclaw.ai/plugins/codex-harness-runtime`) 확인: Codex harness가 thread마다 PreToolUse/PostToolUse/PermissionRequest/Stop 설정을 주입하고 native shell/patch/MCP를 **relay로 관찰·차단**. 즉 relay는 **워커가 codex harness를 쓰는 한 항상 걸린다(B 구조)**.
- **우리 `nyongjong-write-guard` 플러그인은 워커를 통과시킨다**(index.js line 99 `if (isWorkerContext) return`). JARVIS(nyongjong/main/default)의 Discord live write/deploy만 차단. **워커 차단의 원인이 아님.**
- **플러그인 + internal hook(command-logger/session-memory)을 전부 꺼도 relay 자체는 안 빠진다** → relay 죽으면 여전히 fail-closed 차단. 즉 **hook 청소로는 자율진행 완전 회복 불가.** handler 실행은 줄어 부하/실패표면만 감소.
- `nativeHookRelay.events`는 config에 명시 없음(= OpenClaw 기본 동작). relay 회피책은 hook 비활성화가 아니라 **relay 안정화(위 해결책) 또는 codex harness relay 이벤트 주입 설정 조정**이어야 함.
- **핵심 교훈**: "봇 자율 멈춤 = 우리 커스텀 설정 탓"으로 단정 금지. 워커 실행계층(codex harness native relay)은 OpenClaw 구조라 우리 hook과 독립. 근본은 relay socket 안정성.

## 재발 방지 / 감사 체크리스트
- **봇 자율진행 멈춤 = 분배/반환 의심 전에 워커 도구 relay 생존부터 확인**: `ls /tmp/openclaw-native-hook-relays-$(id -u)/`에 socket 파일 있나. 빈 디렉토리면 RELAY_DOWN = 워커는 무엇을 시켜도 0 실행.
- "반환 메시지가 온다 ≠ 작업이 됐다" — 워커 반환이 "차단됨/blocked"이면 티키타카는 빈 바퀴. 반환 본문 내용까지 확인.
- relay 관련 파일: `workspace/scripts/openclaw-native-hook-relay-watchdog.js`(socket probe + gateway-restart-trigger), 에러출처 `dist/hooks-cli-*.js`.

## 관련
- [[pitfall-201-openclaw-hidden-cron-agentturn-self-driven-evolution]] (자율 트리거)
- [[pitfall-247-openclaw-jinmusil-channel-no-operating-rule-bot-unused]] (인프라≠활용; 이번은 인프라 자체 장애)
- [[pitfall-249-openclaw-528-agentruntime-key-removed-gateway-startup-failed]] (같은 세션 gateway 계층 이슈)
