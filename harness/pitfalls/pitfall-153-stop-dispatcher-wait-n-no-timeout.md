# P-153: stop-dispatcher.sh의 `wait -n`이 timeout 없어 stop hook이 22분 hang

- **발견**: 2026-05-15
- **영향**: Claude Code 세션 종료 시 `running stop hooks 6/7`에서 22분 8초 hang. 사용자 인터럽트 강제. 토큰 누적 소비.

## 증상

- 응답 완료 후 stop hook 단계에서 `Tomfoolering... (running stop hooks 6/7 · 22m 8s · ↓ 23.4k tokens)` 표시.
- 22분이 지나도 hook이 종료되지 않음. 사용자 Ctrl+C 또는 새 메시지로 인터럽트 필요.
- 다음 turn까지 진행 불가.

## 원인

`harness/hooks/stop-dispatcher.sh` line 213:

```bash
# Wait for background jobs (max 5s)   ← 거짓 주석
wait -n 2>/dev/null
```

- bash의 `wait -n`은 **timeout 옵션이 없다**. 첫 background child가 종료될 때까지 무한 대기.
- 주석에는 "max 5s"라 적혀있지만 실제 timeout 강제는 어디에도 없음.
- spawn된 background children:
  1. `self-evolve.sh --apply` (line 186)
  2. `node curation.ts` (line 190) — `http://localhost:8765/memory/checkpoint` fetch 호출
  3. `telegram-notify.sh done` (line 199)
- curation.ts 내부는 5s timeout 있지만 어떤 child라도 stall하면 dispatcher가 영원히 wait.

## 해결 (2026-05-15)

`harness/hooks/stop-dispatcher.sh` 수정:

1. 각 background spawn을 `timeout 5` 명령으로 wrap:
   ```bash
   timeout 5 bash self-evolve.sh --apply &
   timeout 5 node curation.ts &
   timeout 5 bash telegram-notify.sh done &
   ```
2. `wait -n` → `wait` (모든 child 종료 대기 — 각 child가 5s 강제 cap이라 합 최대 ~5s).

## 재발 방지

- **bash hook에서 background spawn 시 반드시 `timeout` wrapper 적용**.
- `wait`/`wait -n` 단독 사용 금지 — bash는 wait에 timeout 없으므로 children 측에서 강제해야 함.
- 향후 새 stop hook 추가 시 본 패턴 적용.
- 코드 주석에 "max Ns" 같은 거짓 주석 금지 — 강제 메커니즘이 실제 있어야만 표기.

## 검증

- `bash -n stop-dispatcher.sh` PASS.
- 빈 stdin으로 dispatcher 실행 시 5초 내 종료되어야 함 (별도 timing 검증).
- 메모리 API(localhost:8765) 부재해도 dispatcher가 5초 안에 종료.

## 관련

- 토큰 23.4k 소비는 본 hang과 별개 — 메인 응답 streaming 누적으로 추정. hang 자체로는 추가 토큰 발생 안 함.
