# P-224: WSL2 instanceIdleTimeout로 OpenClaw gateway 반복 사망 (vmIdleTimeout만으론 불충분)

- **발견**: 2026-05-29
- **영향**: WSL2의 OpenClaw gateway가 idle 시 instance 통째로 종료 → 4봇 동반 사망 + boot/shutdown 사이클. P-223 fix(vmIdleTimeout=-1)가 있었는데도 재발.

## 증상

- gateway 시작 직후 곧 죽음. `systemctl --user is-active`는 active지만 uptime 매우 짧음.
- 로그: `SIGTERM received` → Stopped → Started 반복. systemd user manager PID가 계속 바뀜 (systemd[222]→[223]→[234]).
- WSL uptime이 몇 분 단위로 리셋.
- gateway 부팅 로그가 매번 처음부터 (wslg-session, sockets.target, default.target 새로 시작).

## 원인 (microsoft/WSL #8659 + 공식 동작 확인)

WSL2엔 **idle 타이머가 2개**:
| 타이머 | 기본값 | 역할 | .wslconfig 키 |
|--------|--------|------|--------------|
| instanceIdleTimeout | **8초** | user 프로세스 idle 시 **instance(distro+systemd+gateway) 종료** | ❌ 이 빌드에서 무시됨 (MS 미지원) |
| vmIdleTimeout | 60초 | instance 종료 후 **VM** 종료 | ✅ 유효 |

P-223은 `vmIdleTimeout=-1`만 설정 → VM은 유지되나 **instance는 instanceIdleTimeout(8초)로 계속 종료**됨. gateway는 instance 위에서 도니 instance가 죽으면 동반 사망.

⚠️ `instanceIdleTimeout=-1`을 .wslconfig에 넣으면 WSL이 **"무시됨" 경고** 출력 (이 빌드에서 미지원 키). 즉 config로는 instance idle 비활성 불가.

## 해결 (검증됨)

instance가 idle로 안 죽게 **항상 활성 wsl 세션을 유지**(keepalive):

1. **`C:\Users\AIcreator\.harness\KeepWSLAlive.vbs`** — hidden 루프로 `wsl -d Ubuntu -u creator --exec /usr/bin/sleep 3600`을 동기 실행, 반환 시(만료/WSL재시작) 2초 후 재수립 → 사실상 영구 활성 세션 유지.
2. **Windows 시작프로그램 폴더 등록** (admin 불필요):
   `C:\Users\<USER>\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\KeepWSLAlive.vbs`
   (Scheduled Task는 admin 권한 필요해서 거부됨 → Startup 폴더로 우회)
3. .wslconfig: `vmIdleTimeout=-1` 유지 + `[experimental] autoMemoryReclaim=disabled` 추가. **무효한 instanceIdleTimeout 키는 제거** (경고 노이즈 방지).

### 검증
- 90초 idle 후 gateway **active, NRestarts=0** (이전엔 8~60초 내 사망).

## 재발 방지

- WSL2 24/7 서비스는 vmIdleTimeout만으론 부족 — **keepalive 세션 필수**.
- `.wslconfig` 변경은 `wsl --shutdown` 완전 종료 후 재시작해야 적용.
- WSL 명령 실행 후 "uptime 4분 + systemd manager PID 변동" 보이면 instance idle 사망 의심.
- keepalive가 죽었는지 확인: `powershell "Get-Process wscript"` + Startup 폴더 VBS 존재 확인.

## 윈도우 업데이트 재부팅 후 Startup 미실행 (2026-06-02 추가 사례)

- **증상**: 윈도우 업데이트 자동 재부팅 후 Companion "Can't reach gateway / Transport error". WSL2 `uptime` = up 0 min(종료됐다 명령으로 깨어남), gateway 포트 없음 → startup pre-warm + 봇 connect grace(~90s) 후 9봇 connect. **KeepWSLAlive wscript 프로세스 미실행**(Startup 폴더 등록·vmIdleTimeout=-1은 정상).
- **원인**: 윈도우 업데이트 재부팅이 **Startup 폴더 프로그램 실행을 건너뜀**(로그온 자동화/업데이트 후 상태 차이). keepalive 부재 → WSL2 instance idle 종료 노출.
- **빠른 복구(검증됨)**:
  1. `wsl -d Ubuntu -e bash -c 'systemctl --user is-active openclaw-gateway.service; ss -tlnp | grep 18789'` — gateway active면 startup 대기(~90s), 봇 0→9 점진 connect 확인.
  2. KeepWSLAlive 수동 기동: `powershell "Start-Process wscript.exe -ArgumentList '<Startup>\KeepWSLAlive.vbs'"` → `Get-Process wscript`로 기동 확인.
  3. Companion에서 Connect.
- **주의**: 로그 `OpenClaw Gateway (v2026.5.18)`는 **systemd unit Description 텍스트 잔재** — 실제 ExecStart는 `.npm-global/.../dist/index.js`(5.27)이고 `index.js --version`이 진실. 버전 회귀로 오판 금지(P-241과 구분).
- **해결 (2026-06-03 적용)**: Startup 폴더(업데이트 재부팅이 가끔 건너뜀) 대신 **Scheduled Task `WSL-KeepAlive`로 전환**. onlogon 트리거 = 윈도우 업데이트 재부팅 후 로그온 시 확실히 실행.
  - 등록: admin 단발 상승(`Start-Process powershell -Verb RunAs -File <register>.ps1`, UAC ConsentPromptBehaviorAdmin=0이라 자동 상승) → `Register-ScheduledTask -TaskName WSL-KeepAlive -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Principal (... -RunLevel Limited) -Settings (... -ExecutionTimeLimit ([TimeSpan]::Zero))`. **ExecutionTimeLimit 0 필수**(KeepWSLAlive 영구 루프라 기본 3일 제한 걸리면 안 됨). RunLevel **Limited**(일반 권한 충분, highest 불필요 = 보안).
  - 본문의 "Scheduled Task는 admin 필요해서 거부됨"은 **계정이 Administrators 멤버이고 단발 RunAs 상승하면 등록 가능**으로 정정. 거부됐던 건 비상승 세션에서 시도했기 때문.
  - 검증: `schtasks /query /tn WSL-KeepAlive`(Status Ready) → `schtasks /run` → wscript 새 pid 기동 확인 → Startup 폴더 KeepWSLAlive.vbs 휴지통 제거(중복 일원화). `.harness\KeepWSLAlive.vbs` 본체는 유지(Task가 이걸 실행).

## 관련
- [[pitfall-223-wsl2-vmidletimeout-openclaw-autostart]] — vmIdleTimeout 부분만 다룬 선행 fix (불충분)
- CLAUDE.md STICKY DECISIONS 활성 인프라 — keepalive 등록 필요
