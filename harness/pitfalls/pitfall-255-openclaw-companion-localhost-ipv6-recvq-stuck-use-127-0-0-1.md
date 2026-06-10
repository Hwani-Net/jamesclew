# P-255: Companion이 localhost(IPv6 [::1])로 붙으면 ws Recv-Q 쌓여 "Connecting" 무한 → 127.0.0.1(IPv4)로 우회

- **발견**: 2026-06-03 (대표님 "여전히 접속 안 됨" + "Add로 네트워크 올리는 건 뭐냐")
- **영향**: gateway·9봇 모두 정상인데 Companion operator만 무한 "Connecting". startup 대기(P-254)로 오인하기 쉬움.

## 증상
- Companion Connection "Connecting…" 무한, Op/Node 회색.
- gateway active, 18789 리스닝, **9봇 connected**(=정상), device "Windows Node" operator **paired**(거부 아님), 거부 로그 없음.
- 그런데도 operator 연결 안 됨.

## 근본 원인 (ss 실측 — 결정적)
`ss -tnp | grep 18789`:
```
[::1]:56548 -> [::1]:18789   Recv-Q 124746   # IPv6: 124KB 안 읽힘 = 막힘
[::1]:57054 -> [::1]:18789   Recv-Q 129922   # IPv6: 129KB 쌓임
127.0.0.1:.. -> 127.0.0.1:18789  Recv-Q 0    # IPv4: 정상
```
- Companion이 `ws://localhost:18789`의 **localhost를 IPv6(`[::1]`)로 해석**해 연결 → gateway가 그 IPv6 ws의 수신 데이터를 처리(read)하지 못해 **Recv-Q에 124KB+ 적체** → handshake 미완 → 무한 Connecting.
- **IPv4(`127.0.0.1`) 연결은 Recv-Q 0 정상.** CPU 7%로 부하/event-loop 포화도 아님 → 순수 IPv6 ws 처리 문제.
- (이전 gw2 `1006 closed before connect`도 peer=`[::1]` IPv6였음 — 같은 계열 정황)

## 해결 (검증 경로)
- **Companion gateway URL을 `localhost` → `127.0.0.1`(IPv4 강제)로**:
  - Companion "Discovered on your network → Local Gateway (127.0.0.1:18789) → **Add**" (대표님이 물은 그 Add가 바로 IPv4 직접연결 = 해결책).
  - 또는 Add gateway에서 URL을 `ws://127.0.0.1:18789`로 직접 입력. Shared token = gateway_auth_token.
  - device는 이미 operator paired라 재승인 불필요할 가능성.
- 기존 `localhost`(IPv6 막힘) gateway 항목은 `···` → 제거.

## "자주 재발"의 진짜 메커니즘 (2026-06-03 재확인)
- 재발 정황: `[::1]:18789` 연결이 **CLOSE-WAIT 상태로 2.6MB Recv-Q 적체**(좀비 연결 누적). gateway가 IPv6 ws를 read도 close도 못 함. IPv4(127.0.0.1)는 Recv-Q 0.
- **gateway 재시작 자체는 잦지 않음**(1회/1시간 수준). 진짜 문제는 **restart 후 Companion이 또 `localhost`→IPv6로 재연결 → 막힘 재발**. 즉 "자주 connect 안 됨"의 근본은 restart 빈도가 아니라 **localhost(IPv6)를 계속 쓰는 것**.
- **영구 해결은 한 번만 하면 됨**: Companion saved gateway를 `ws://127.0.0.1:18789`(IPv4)로 등록 + `localhost` 항목 제거. 그러면 restart 몇 번을 해도 IPv4로 붙어 재발 0. localhost를 안 지우고 두면 매번 재발.
- (더 근본: gateway를 IPv4 only bind로 묶으면 IPv6 리스닝 자체 제거 가능하나, gateway restart 필요 → 봇 90초 startup(P-254) 발생. Companion IPv4 고정이 더 간단·안전.)

## 적용된 영구 해결 (2026-06-03 검증됨) — gateways.json url 직접 수정
- gateway 측 IPv4 전용 bind는 **OpenClaw 미지원**(`--bind`는 loopback 모드만 = IPv4+IPv6 강제). Windows hosts `127.0.0.1 localhost` 추가는 **admin 거부**.
- **실제로 통한 해결**: Companion saved 설정 파일 직접 수정.
  - 파일: `%APPDATA%\OpenClawTray\gateways.json` (배열 `gateways[]`, 각 항목 `url`/`sharedGatewayToken`/`identityDirName`, 최상위 `activeId`).
  - **활성 gateway(activeId가 가리키는 항목)의 `url`을 `ws://localhost:18789` → `ws://127.0.0.1:18789`로 replace.** id/token/identityDirName 유지 → device 재pairing 불필요.
  - 절차: `OpenClaw.Tray.WinUI.exe`(= `%LOCALAPPDATA%\OpenClawTray\OpenClaw.Tray.WinUI.exe`) Stop-Process → url 수정 → Start-Process. **Companion 실행 중 수정하면 종료 시 메모리값으로 덮어쓰므로 반드시 종료 후 수정.**
  - 검증: `ss -tn | grep 18789` → `127.0.0.1` ESTAB이 Recv-Q 0으로 뜨면 성공. 옛 `[::1]` CLOSE-WAIT 좀비는 gateway 다음 restart 시 정리.
- ⚠️ 프로세스 식별 주의: `Name -like '*Tray*'`는 **Logitech `lghub_system_tray`를 오인**함. OpenClaw은 `Name -like 'OpenClaw*'`(OpenClaw.Tray.WinUI)로 정확히 잡을 것.

## 재발 방지 / 감사 체크
- Companion "Connecting" 무한 + 봇은 connected면 → **`ss -tnp | grep 18789`로 Recv-Q 확인**. `[::1]`(IPv6) 연결에 Recv-Q 큰 값이 쌓이면 IPv6 막힘 = 127.0.0.1로 우회.
- gateway 측 listen은 IPv4(`127.0.0.1:18789`)·IPv6(`[::1]:18789`) 둘 다 뜨지만(`bind: loopback`), **클라이언트는 IPv4로 명시 연결**이 안전.
- 후속(근본): gateway IPv6 ws 핸들링이 왜 read를 멈추는지(OpenClaw 버그 가능) 추적 — 단 127.0.0.1 우회로 운영엔 지장 없음.

## 2026-06-08 재발 — 이번엔 IPv4(127.0.0.1)가 좀비 + mirrored 모드 근본 해결

- **증상 역전**: 과거(6/3)는 IPv6([::1]) Recv-Q 막힘 → IPv4 우회였는데, 6/8엔 **IPv4(127.0.0.1)가 CLOSE-WAIT + Recv-Q 289KB 적체** 좀비. IPv6([::1])는 200 OK. Companion이 P-255로 `ws://127.0.0.1`(IPv4) 고정돼 있어서 **이번엔 IPv4 좀비로 연결 실패**.
- **진짜 근본 원인 = WSL2 NAT 모드 localhost forwarding 불안정**: gateway 재시작/SIGHUP 연타가 누적되면 NAT relay(wslrelay)가 IPv4·IPv6 중 한쪽 loopback을 stale CLOSE-WAIT로 만든다. 프로토콜은 그때그때 바뀜(6/3 IPv6, 6/8 IPv4) → 127.0.0.1 고정이든 localhost든 한쪽이 주기적으로 막힘. 우회(IPv4↔IPv6 토글)는 임시방편일 뿐 재발.
- **진단 실측 (Windows `curl.exe` 프로토콜 분리가 결정적)**:
  ```
  curl.exe -4 http://127.0.0.1:18789/config  → 000 (막힘)
  curl.exe -6 http://[::1]:18789/config       → 200
  ss -tn|grep 18789 → CLOSE-WAIT Recv-Q 289186  127.0.0.1→127.0.0.1:18789 (좀비)
  ```
  - WSL **내부** curl은 항상 200(gateway 정상) — 문제는 순수 Windows→WSL 포워딩 경로.

### 영구 해결 (2026-06-08 검증) — WSL2 mirrored networking 전환
- **조건**: Windows 11 22H2+ (build 22621↑) + WSL 2.0+. 실측 환경 Win11 Pro build 26200 + WSL 2.6.3.0 → 지원.
- **`%USERPROFILE%\.wslconfig`**:
  ```ini
  [wsl2]
  vmIdleTimeout=-1
  networkingMode=mirrored          # ← 핵심: Windows↔WSL 네트워크 스택 직접 공유
  [experimental]
  autoMemoryReclaim=disabled
  hostAddressLoopback=true         # 호스트↔게스트 loopback 허용
  ```
- **절차**: .wslconfig 수정 → `wsl --shutdown` → `wsl -d Ubuntu`로 깨우기 → **WSL-KeepAlive 재기동**(`schtasks /run /tn WSL-KeepAlive`, P-224) → gateway systemd user service 자동 시작 → 봇 90초 startup 대기.
- **mirrored 적용 확인 지표**: WSL `eth0` IP가 **Windows LAN 대역**(예 192.168.x.x)으로 바뀜. NAT 모드면 172.x. 이게 mirrored 성공 증거.
- **검증 결과**: `curl.exe -4 127.0.0.1:18789/config` = **200**(000→복구), `ss -tn|grep 18789` 전부 **ESTAB Recv-Q 0**(좀비 소멸), gateway NRestarts=0, 9봇 connected.
- **왜 근본 해결인가**: mirrored는 127.0.0.1/[::1]을 Windows와 동일 스택으로 공유 → NAT relay의 IPv4/IPv6 한쪽 stale 현상 자체가 사라짐. 재시작 횟수와 무관하게 양쪽 loopback 안정. Companion IPv4 고정 그대로 유지 가능(재pairing 불필요).
- ⚠️ mirrored 부작용 점검: Discord 봇(WSL→외부 인터넷) 연결은 mirrored에서 정상(오히려 개선, 9봇 connected 확인). VPN/방화벽 특수환경에선 일부 영향 가능하나 본 환경 무이상.

## 관련
- [[pitfall-254-openclaw-gateway-restart-companion-connecting-is-startup-wait-not-failure]] (Connecting의 다른 원인 = startup 대기. 구분 필요)
- [[pitfall-248-openclaw-companion-node-devicefamily-metadata-mismatch]] (gw2 [::1] 1006 정황)
- [[pitfall-224-wsl2-instance-idle-timeout-gateway-death]] (mirrored 전환 시 wsl --shutdown → KeepWSLAlive 재기동 필요)
