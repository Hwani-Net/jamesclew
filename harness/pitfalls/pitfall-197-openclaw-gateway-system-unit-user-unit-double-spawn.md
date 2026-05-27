# PITFALL-197: OpenClaw gateway system-unit ↔ user-unit 이중 등록 → 무한 SIGTERM 루프

- **발견**: 2026-05-25 (P-196 영상 패턴 7채널 운영 셋업 직후)
- **영향**: 4봇 전원 오프라인. nyongjong / jamesclaw-cc / codex claw / ollama claw 모두 startup 단계 전에 죽음. Discord에서는 "claude만 온라인"으로 보이나 그 claude도 실제로는 새 메시지에 무응답.
- **재발 빈도**: 1회 (이번 세션 처음 발견). 단, OpenClaw 신규 환경 셋업 시마다 잠재적 재발 가능.
- **검증 자료**:
  - `journalctl --user -u openclaw-gateway --since "10 min ago"` — restart counter 35→39회 연속 SIGTERM
  - `/tmp/openclaw/openclaw-2026-05-25.log` — "starting channels and sidecars" 직후 SIGTERM 패턴 매번 동일
  - `ls /etc/systemd/system/openclaw-gateway.service` + `systemctl --user list-units` — 이중 등록 확정
  - `ps -ef | grep openclaw` + `cat /proc/<PID>/status` — 두 supervisor의 child process 경쟁

---

## 증상

P-196 적용(영상 패턴 7채널 운영 + `openclaw.json` defaultTo 봇별 매핑 + ORCHESTRATION.md §10/§11 추가) 후 게이트웨이 재시작을 했더니:

1. Discord 봇 목록(우측 사이드바)에서 **claude만 온라인**, nyongjong / codex claw / ollama claw 3봇 오프라인
2. 그나마 claude도 새 메시지에 무응답 — 라이브 reply 시도해도 아무 일 없음
3. `~/.openclaw/discord/`에 토큰은 그대로 존재하고 hot reload 1회 이전엔 4봇 다 정상 동작했음
4. ORCHESTRATION.md 변경 + openclaw.json defaultTo 패치 → gateway restart 직후 발생

**초기 추측(잘못)**: "ORCHESTRATION.md 변경이 system prompt 파싱 에러를 일으켰을 것" — 이 가설을 따라가면 P-195와 비슷한 백업 복원 루트로 빠지게 됨. 다행히 백업 복원 전에 추적을 한 단계 더 진행함.

---

## 진단 과정 (P-194 회피 — 외부 증거 누적)

### 1단계 — journalctl로 게이트웨이 supervisor 상태 확인

```bash
journalctl --user -u openclaw-gateway --since "10 min ago" --no-pager
```

출력 패턴 (반복):
```
... openclaw-gateway[XXXX]: starting channels and sidecars...
... openclaw-gateway[XXXX]: received SIGTERM, shutting down
... systemd[YYY]: openclaw-gateway.service: Main process exited, code=killed, status=15/TERM
... systemd[YYY]: openclaw-gateway.service: Scheduled restart job, restart counter is at 36.
... openclaw-gateway[XXXX+1]: starting channels and sidecars...
... openclaw-gateway[XXXX+1]: received SIGTERM, shutting down
... systemd[YYY]: openclaw-gateway.service: Scheduled restart job, restart counter is at 37.
```

핵심 신호:
- **restart counter 35→39회 연속**: 한 번 죽고 재시작이 아니라 무한 loop
- 매번 **6초 만에 SIGTERM** 수신 (uptime 너무 짧아 OOM/config error 아님)
- exit code = `15/TERM` (외부에서 보낸 SIGTERM — 자체 crash 아님)
- 매번 동일 라인 "starting channels and sidecars" 직후에 죽음 → channel/sidecar startup 직전에 외부 process가 SIGTERM 전송

### 2단계 — 게이트웨이 자체 로그로 cross-check

```bash
tail -200 /tmp/openclaw/openclaw-2026-05-25.log | jq -r '. | "\(.ts) \(.level) \(.msg)"' | tail -50
```

패턴 동일:
```
... INFO  starting channels and sidecars...
... WARN  received SIGTERM, gracefully shutting down
```

systemd 로그와 자체 로그가 동일한 라인에서 죽음을 확인 — 즉 **외부 SIGTERM이 정확히 channels/sidecars startup 단계에서 진입**.

### 3단계 — 같은 시점에 누가 살아있나? (process 추적)

```bash
ps -ef | grep -i openclaw | grep -v grep
```

출력:
```
creator  12345  232  0 ...  node /usr/local/lib/.../openclaw/dist/gateway.js   ← PPID=232
creator  12399    1  0 ...  node /usr/local/lib/.../openclaw/dist/gateway.js   ← PPID=1 (orphan)
```

**node openclaw process가 2개**. 하나는 creator의 `systemd --user` (PID 232)의 child, 다른 하나는 **PPID=1 (init parent — orphan)**.

확장 검증:
```bash
for pid in $(ls /proc/*/cmdline 2>/dev/null | xargs grep -l "openclaw" 2>/dev/null | sed 's|/proc/||;s|/cmdline||'); do
  ppid=$(awk '/^PPid:/ {print $2}' /proc/$pid/status 2>/dev/null)
  cmd=$(tr '\0' ' ' </proc/$pid/cmdline)
  echo "PID=$pid PPID=$ppid CMD=$cmd"
done
```

출력 확인:
- PID 12345 → PPID=232 (systemd --user)
- PID 12399 → PPID=1 (init)

PPID=1 process는 supervisor가 떠나서 init이 거둬간 orphan이 아니라, **다른 supervisor가 살아있는데 우리 user systemd에서 보이지 않는 것**일 가능성.

### 4단계 — orphan 죽여도 즉시 재spawn

```bash
kill 12399
sleep 2
ps -ef | grep openclaw | grep -v grep
```

출력에 **새로운 PPID=1 process 즉시 등장**. orphan이 아니라 다른 supervisor가 keepalive 중. user systemd 외에 또 다른 곳에서 openclaw를 띄우고 있다는 결정적 신호.

### 5단계 — system-wide systemd 확인

```bash
ls -la /etc/systemd/system/openclaw* 2>/dev/null
```

출력:
```
-rw-r--r-- 1 root root  XXX 2026-05-24 XX:XX /etc/systemd/system/openclaw-gateway.service
```

**system-wide unit 발견**. user unit과 동일 이름. `systemctl status openclaw-gateway` (sudo 없이 시도) → "Failed to get D-Bus connection" — 권한으로 인해 안 보이던 것.

```bash
sudo systemctl status openclaw-gateway --no-pager
```

출력:
```
● openclaw-gateway.service - OpenClaw Gateway (keepalive supervisor)
   Loaded: loaded (/etc/systemd/system/openclaw-gateway.service; enabled; vendor preset: enabled)
   Active: active (running) since ...
   Main PID: 12399 (node)
   Tasks: ...
```

확정: **system-wide unit이 enabled + active**. user unit과 같은 binary, 같은 port(18789), 같은 PID file을 두고 경쟁.

### 6단계 — 왜 이중 등록이 됐나 (가설)

확실치 않으나 어제(2026-05-24) 1.5시간 OpenClaw 디버깅 중(P-195 처리 시점) `openclaw daemon install` 명령이 어딘가에서 실행된 것으로 추정. `openclaw` CLI는 sudo가 있으면 자동으로 system unit으로 install하는 분기가 있고, 없으면 user unit으로 fallback.

이번 환경에서는 **둘 다 install되어 양쪽 모두 enabled** 상태.

---

## 진짜 원인

`/etc/systemd/system/openclaw-gateway.service` (root, system-wide) ↔ `~/.config/systemd/user/openclaw-gateway.service` (creator, user) **이중 등록**.

두 unit이 동시에 활성화되어 각자 `gateway.js`를 spawn → 같은 port 18789를 두고 경쟁. 게이트웨이 시작 코드에는 "stale gateway PID 발견 시 SIGTERM 전송" 로직이 들어있고, 양쪽이 서로를 stale로 인식하여 **상호 SIGTERM 전송 → 무한 재시작 루프**.

### 양 unit의 차이

| 항목 | system unit (`/etc/systemd/system/`) | user unit (`~/.config/systemd/user/`) |
|------|--------------------------------------|---------------------------------------|
| 권한 | root | creator |
| 시작 시점 | 부팅 시 자동 | user session 진입 시 |
| keepalive lock | `/run/openclaw-gateway-keepalive.lock` (flock) | (없음 또는 user-local) |
| 진단 시 가시성 | sudo 필요 | `journalctl --user`로 즉시 보임 |
| PID file 위치 | `/run/openclaw-gateway.pid` | `~/.openclaw/state/gateway.pid` |

문제 핵심:
1. 양 unit 모두 같은 `/usr/local/lib/.../openclaw/dist/gateway.js`를 spawn
2. 같은 18789 port 점유 시도
3. 먼저 binding한 process는 살아남고, 늦게 들어온 process는 EADDRINUSE → 종료
4. 그러나 양쪽 supervisor가 30초마다 재시작 트리거 → **6초마다 죽고 살기를 반복**
5. 매 라이프사이클이 너무 짧아 channel/sidecar startup이 못 끝남 → 봇 4개 startup 실패

---

## 해결

`sudo`가 필요하므로 대표님 권한으로 1회 실행. 이후 영구 해소.

### 적용 순서

```bash
# 1. system-wide unit 중지 + 비활성화
sudo systemctl stop openclaw-gateway
sudo systemctl disable openclaw-gateway

# 2. unit 파일을 백업으로 옮겨 자동 재등록 차단 (rm 대신 mv로 복원 가능성 유지)
sudo mv /etc/systemd/system/openclaw-gateway.service /etc/systemd/system/openclaw-gateway.service.bak-20260525

# 3. user unit 실패 상태 reset (실제로는 "Unit not loaded" 정상)
systemctl --user reset-failed openclaw-gateway.service

# 4. user unit으로만 재시작
systemctl --user start openclaw-gateway.service
```

3단계의 `reset-failed`가 "Unit not loaded"로 실패해도 무시. user unit이 이미 실패 누적 없이 깨끗한 상태였음을 의미하므로 정상.

### 검증

```bash
# 30초 polling — 6회 연속 active 확인
for i in 1 2 3 4 5 6; do
  state=$(systemctl --user is-active openclaw-gateway.service)
  gw=$(pgrep -af "openclaw.*gateway" | wc -l)
  echo "[$i] active=$state gw_processes=$gw"
  sleep 5
done
```

기대 출력:
```
[1] active=active gw_processes=3
[2] active=active gw_processes=3
... (6회 연속)
```

`gw_processes=3` = master + worker process 2개. 정상 fork 패턴.

### 봇 startup 시퀀스

```bash
tail -f /tmp/openclaw/openclaw-2026-05-25.log | jq -r '. | "\(.ts) \(.msg)"'
```

확인된 순서:
1. `gateway ready` (T=0s)
2. `heartbeat started` (T=0s)
3. `claude (jamesclaw-cc) startup → Discord Message Content Intent OK` (T=0s, no delay)
4. `codex startup` (T=10s, intentional delay for rate-limit avoidance)
5. `nyongjong startup` (T=20s)
6. `ollama startup` (T=30s)

각 봇이 Discord gateway에 connect 후 사이드바에 온라인 표시.

### 라이브 reply 테스트

대표님 Discord에서 `#작업-요청` 채널에 "테스트" 입력 → **nyongjong이 "대표님, 수신 정상입니다." 응답** → P-196 + P-197 양쪽 fix 완전 동작 확인.

---

## 재발 방지

### 신규 환경 셋업 시 사전 확인

OpenClaw 신규 환경(WSL2 / Linux server / 다른 사용자 home) 셋업 직전 다음 체크 명령 실행:

```bash
# 1. system unit 존재 여부
ls -la /etc/systemd/system/openclaw* 2>/dev/null

# 2. user unit 존재 여부
ls -la ~/.config/systemd/user/openclaw* 2>/dev/null

# 3. 양쪽 다 있으면 즉시 중단 — system unit 처리부터
```

system unit이 이미 있으면 user unit install을 보류하고 한쪽으로 통일.

### `openclaw daemon install` 실행 전 user unit 존재 여부 확인

`openclaw daemon install`은 sudo 권한이 있으면 자동으로 system unit으로 install. user unit이 이미 있는 환경에서 sudo로 install하면 이중 등록 위험.

대안 명령:
```bash
# user unit 전용 install (sudo 회피)
openclaw daemon install --user

# 또는 install 전 명시적 확인
[ -f ~/.config/systemd/user/openclaw-gateway.service ] && echo "USER UNIT EXISTS — skip install" || openclaw daemon install --user
```

### gateway 무한 재시작 패턴 진단 단축 절차

다음 패턴 감지 시 즉시 system vs user unit 경쟁 의심:

| 신호 | 임계값 |
|------|--------|
| `journalctl` restart counter | 5회 이상 빠르게 증가 |
| 라이프사이클 | 10초 이하 |
| exit code | `15/TERM` (자체 crash 아님) |
| 죽는 라인 | 매번 동일 (port binding 직전) |

진단 단축:
```bash
# 1. user systemd 외 다른 supervisor 존재 확인
ls /proc/*/cmdline 2>/dev/null | xargs -I{} sh -c 'grep -l openclaw {} 2>/dev/null' | while read f; do
  pid=$(echo "$f" | sed 's|/proc/||;s|/cmdline||')
  ppid=$(awk '/^PPid:/ {print $2}' /proc/$pid/status)
  echo "PID=$pid PPID=$ppid"
done | sort -k2 -t= | uniq -c -f1

# 2. PPID=1 process가 있으면 다른 supervisor 후보
# 3. /etc/systemd/system/ 확인
sudo ls /etc/systemd/system/openclaw* 2>/dev/null
```

### 운영 환경 통일 원칙

WSL2 환경에서는 **user unit 단독 운영을 표준**으로 채택. 이유:
1. WSL2는 부팅 개념이 약함 — system unit의 boot-time start 이점이 적음
2. user 권한으로 충분히 디버깅·재시작 가능 (sudo 불필요)
3. `journalctl --user`로 즉시 가시성 확보
4. 다른 사용자가 같은 WSL2 instance에 들어와도 충돌 없음

system unit이 필요한 경우는 **headless Linux server에 다중 사용자가 접근**하는 시나리오. 대표님 환경(WSL2 단일 사용자)에서는 user unit만 사용.

### 백업 복원 antipattern 회피

P-195와 비슷한 "ORCHESTRATION.md 변경이 원인일까?" 가설로 빠르게 백업 복원하면 **진짜 원인을 영영 못 찾는다**. 이번 case도 백업 복원 전에:

1. journalctl로 SIGTERM 패턴 확인
2. process 2개 발견
3. PPID 추적으로 supervisor 2개 확인

이 3단계를 거쳤기에 system unit 발견에 도달함. 가설을 세웠으면 백업 복원 전에 **그 가설이 맞는지 외부 증거 1개 이상 확보** 후 진행.

---

## 적용 이력

| 시각 (KST) | 행동 | 결과 |
|-----------|------|------|
| 2026-05-25 03:15 | P-196 적용 후 gateway restart | 모든 봇 오프라인 발견 |
| 03:18 | journalctl 확인 → restart counter 35→39 | SIGTERM 루프 확정 |
| 03:20 | `/tmp/openclaw/openclaw-2026-05-25.log` JSON 파싱 | 6초 라이프사이클 패턴 확정 |
| 03:23 | `ps -ef | grep openclaw` → process 2개 발견 | PPID=232 + PPID=1 확인 |
| 03:25 | orphan kill 후 즉시 재spawn | 다른 supervisor 존재 confirm |
| 03:27 | `ls /etc/systemd/system/openclaw*` (sudo) | system unit 발견 |
| 03:30 | `sudo systemctl stop/disable openclaw-gateway` | system unit 중지 |
| 03:31 | unit 파일 백업으로 mv | 자동 재등록 차단 |
| 03:32 | `systemctl --user start openclaw-gateway.service` | user unit 단독 운영 시작 |
| 03:33~03:36 | 30초 polling 6회 | active=active 6회 연속 + gw_processes=3 |
| 03:36 | 4봇 startup 로그 확인 | jamesclaw-cc(0s) / codex(10s) / nyongjong(20s) / ollama(30s) 정상 |
| 03:38 | Discord `#작업-요청`에 대표님 "테스트" → nyongjong "대표님, 수신 정상입니다." | ✅ P-196 + P-197 양쪽 fix 완전 동작 |

---

## 관련

- [[pitfall-187-openclaw-wsl2-deployment-success]] — WSL2 최초 deploy. system unit 등록 가능성 시작점
- [[pitfall-188-openclaw-wsl2-deployment-complete-2026-05-20]] — WSL2 deploy 완료. 이 시점에는 user unit만 있었음 (추정)
- [[pitfall-191-openclaw-codex-cannot-fire-discord-mentions]] — raw ID mention syntax 문제 (이번 PITFALL과는 별개 layer)
- [[pitfall-194-task-completed-without-external-evidence]] — 검증 없는 결론 보고 antipattern. 이번엔 백업 복원 전에 외부 증거 3단계 확보로 회피
- [[pitfall-195-openclaw-claude-cli-harness-not-registered-after-model-swap]] — system prompt 추측 antipattern 사례. 이번 case도 같은 함정에 빠질 뻔함
- [[pitfall-196-openclaw-channel-separation-video-pattern]] — 영상 패턴 7채널 운영 직전에 발생. P-196 적용 직후 노출됨

---

## 향후 진화 트리거

다음 중 하나라도 충족 시 본 PITFALL 보강 또는 후속 PITFALL 작성:

1. **다른 환경(macOS / native Linux)에서 동일 증상 재발**: OS별 systemd 동작 차이가 있으면 분리 PITFALL 검토.
2. **`openclaw daemon install` CLI에 `--user-only` flag가 추가됨**: 영상 패턴 가이드에 명시 + 본 PITFALL의 명령 예시 갱신.
3. **WSL2 재부팅 후 system unit 자동 재생성**: 어딘가의 install script가 매번 system unit을 다시 만든다면 그 source 추적 + 차단 PITFALL 작성.
4. **봇 5개 이상으로 확장 시 startup delay 충돌**: 현재 0/10/20/30s delay 패턴이 봇 추가로 깨지면 별도 PITFALL.
5. **port 18789 외 다른 port로 conflict 발생**: gateway 외 sidecar/heartbeat port에도 같은 이중 등록 패턴이 있는지 점검.
