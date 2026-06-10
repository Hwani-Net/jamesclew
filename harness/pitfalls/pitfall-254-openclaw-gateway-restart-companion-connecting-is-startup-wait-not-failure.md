# P-254: gateway 재시작/변경 후 Companion "Connecting…" = startup 대기(9봇 순차 90초), 재연결 실패 아님

- **발견**: 2026-06-03 (대표님 "gateway 한번 다운/변경하면 왜 자꾸 재연결 실패?")
- **영향**: gateway 재시작 직후 Companion operator가 1~2분 "Connecting"에 머물러 "재연결 실패"로 오인. 불필요한 추가 재시작 유발 위험(악순환).

## 증상
- Companion Connection 화면 gw1(18789) "Connecting…" 무한 지속, Op/Node 회색.
- gateway는 `systemctl is-active` = active, 18789 리스닝 정상.

## 근본 원인 (실측 — 크래시/watchdog 오판 아님)
- **크래시 루프 아님**: `NRestarts=0`, 30분간 재시작 2회뿐, RSS 348MB·CPU 13.9% 정상.
- **watchdog 오판 아님**: relay watchdog 로그 `"note":"no_active_relay_registrations", "recovered":false, "trigger":null` — socket 0개를 정상으로 인식, restart 트리거 안 함. (socket 0개는 워커 미활성 시 정상 = P-251)
- **진짜 원인 = startup 지연**: gateway 재시작 시 9봇 Discord probe가 **순차 10초 간격**으로 connect(02:32:52~02:35:07 ≈ 90초~2분). OpenClaw가 Discord IDENTIFY rate limit(같은 IP 다수 봇) 회피하려 순차 처리. 이 동안 operator(Companion) 연결이 awaiting → "Connecting".
- **부하 가중**: opus 4봇(JARVIS/EVE/FRIDAY/KITT) + thinkingDefault high 격상으로 provider auth pre-warm 부하↑(`eventLoopMax=1273ms`, event loop 1.2초 블록). startup 더 느려짐.
- 단일 gateway 9봇 집중(P-226 폐지로 gw1 단독)도 한몫.

## 해결 / 대응
- **즉효**: 그냥 기다린다(1~2분). `channels status`에서 connected 수가 9가 되면 startup 완료 → Companion에서 **Connect** 누르면 즉시 붙음. **추가 재시작 금지**(startup만 다시 늘어남 = 악순환).
- **재발 감소**:
  - config 변경은 **hot-reload 우선**(모델·thinkingDefault 변경은 hot-reload됨 → restart 불필요). `[reload] config hot reload applied` 확인. restart는 꼭 필요할 때만.
  - opus 격상이 pre-warm을 무겁게 함 → 한도/속도 압박 시 일부 sonnet 환원이 startup도 단축.
  - (미검토 옵션) 봇 connect 동시성 상향 설정이 있으면 순차 90초 단축 가능 — 단 Discord rate limit 위험.

## 재발 방지 (감사 체크)
- gateway "재연결 실패" 호소 시 **먼저 `channels status` connected 수 + `NRestarts` + watchdog trigger 확인**. connected가 올라가는 중이면 = startup 대기지 실패 아님.
- "Connecting"을 실패로 단정해 재시작 난사 금지(P-243 하향나선) — startup이 매번 90초+ 리셋됨.

## 트리거 확장 (2026-06-03) — Windows 재부팅 아니어도 WSL2만 재시작하면 동일
- **증상 재발**: 대표님 "Claude Desktop 업데이트했더니 connect 풀림". 실측: **WSL2 uptime 1분 vs Windows uptime 34h** — Windows는 안 껐는데 WSL2만 재시작됨.
- **원인**: WSL을 쓰는 앱(Claude Desktop 등)의 업데이트가 `wsl --shutdown` 류를 유발 → WSL2 전체 종료 → KeepWSLAlive(P-224)가 즉시 재기동 → **그 안의 gateway도 재기동 → 9봇 90초 startup → Companion 대기**.
- **감별 포인트**: `wsl uptime`(짧음) vs `Windows LastBootUpTime`(김)을 비교. Windows 안 껐어도 WSL2만 재시작될 수 있다. IPv4 고정(P-255)이 유지되고 연결이 `127.0.0.1`이면 IPv6 막힘이 아니라 이 startup 대기다.
- **구조적**: gateway가 WSL2 안이라, WSL2 재시작 트리거(앱 업데이트/윈도우 업데이트/wsl shutdown)는 모두 gateway 재기동→startup 대기를 부른다. 고장 아님. 봇 9 connect 완료까지 기다리면 Companion 자동 연결.

## 관련
- [[pitfall-226...]] 단일 gateway 9봇 event-loop 부하 (폐지됐으나 부하 우려 현실화)
- [[pitfall-251-openclaw-528-codex-plugin-518-stale-worker-blocked-relay-unavailable]] socket 0개 정상(동적생성)
- [[pitfall-246-openclaw-probe-resolved-not-equal-online-presence]] probe resolved 단계 이해
