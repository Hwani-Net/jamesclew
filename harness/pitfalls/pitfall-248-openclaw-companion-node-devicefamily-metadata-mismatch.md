# P-248: OpenClaw Companion node 연결 deviceFamily=<none> ↔ gateway pinnedDeviceFamily=Windows metadata 충돌 (node mode 페어링 불가)

- **발견/규명**: 2026-06-01 (대표님 "node 켜줘" → 페어링 반복 실패 끝에 근본 규명)
- **영향**: OpenClaw Windows Companion의 **operator는 정상 연결**되나 **node mode는 페어링 불가**. 봇이 이 PC의 screen/browser/canvas capability를 빌려쓰는 기능 차단. (봇 9개 자체 운영엔 영향 0 — operator로 명령·조회 정상)

## 증상 (단계별 오인 → 정정)
1. node Connect 시 `[ws] closed before connect ... code=1006` → "alpha 1006 버그"로 **오판**.
2. `nodes pending`=0, 화면 id로 `nodes approve` → `unknown requestId`.
3. 실제 원인은 `nodes`가 아니라 **device role-upgrade** (Companion 로그 `OpenClawTray/openclaw-tray.log`):
   `NOT_PAIRED / reason=role-upgrade / requestedRole=node / approvedRoles=[operator]` → `devices`로 처리해야 함.
4. role-upgrade 승인 후 node 재연결 시 gateway 로그에 진짜 원인:
   ```
   [gateway] security audit: device metadata upgrade requested reason=metadata-upgrade
   claimedDeviceFamily=<none>   pinnedDeviceFamily=Windows   client=cli  → closed before connect 1006
   ```

## 근본 원인 (실측 확정)
- 같은 device(operator+node 공유)에서 **operator 연결은 deviceFamily=Windows**를 보내 gateway가 그 값으로 **pin**. 
- **node 연결(Companion 0.6.0-alpha / Tray cli v1.0.0)은 deviceFamily를 비워(`<none>`) 보냄** → pinned(Windows)와 불일치 → gateway 보안이 `metadata-upgrade` 요구 후 연결 거부(1006).
- gateway 코드상 `metadata-upgrade` = "device identity changed and must be re-approved"로 **승인 가능한 요청**이지만, Companion이 즉시 1006으로 끊어 `devices/nodes pending`에 **등록조차 안 됨** → 승인 창구가 안 열리는 악순환.
- `gateway.security`·`gateway.devices` = `null` (기본 보안). dist는 minified라 `metadataPin` 비활성 config 키 경로 확정 불가 → **추측 수정 금지(P-229)**.

## 시도한 것 (모두 metadata 충돌로 막힘)
- device remove → setup code(`openclaw qr --setup-code-only --public-url ws://localhost:18789`) → Advanced setup 붙여넣기 → operator 재pairing 승인 ✅ → node role-upgrade 승인 ✅ → **node 재연결 시 또 metadata-upgrade 1006**.
- 새 device로 깨끗이 재등록해도 operator=Windows pin은 동일 → node=<none> 충돌 재발.

## 해결 (operator + node 둘 다 완전 복구 — 결국 성공)
> ⚠️ 진행 중 "node는 alpha 버그로 불가"라 **성급히 단정했으나 틀림**. 재등록 절차를 끝까지 밀어붙이니 metadata가 정렬되며 node도 Connected됨. premature_conclusion 주의.

**해결 절차(검증됨)**:
1. `devices remove <deviceId>` (operator+node 공유 device 제거)
2. `openclaw qr --setup-code-only --no-ascii --public-url ws://localhost:18789` → setup code 생성
3. Companion **Advanced setup**("Install new WSL Gateway" 금지) → "Paste setup code here" 붙여넣기 → Apply
4. `devices list --json` pending에서 **operator** requestId → `devices approve` (operator 복구)
5. Companion node mode 토글 ON → `devices list --json` pending의 **node role-upgrade** requestId → `devices approve`
6. node mode 토글 **off → on** 재트리거 (이 과정에서 operator 재pairing도 뜨면 함께 승인)
7. 결국 Companion이 **deviceFamily=Windows로 정렬된 node 연결** 수립 → `nodes status` **Connected: 1**
8. `nodes pending`에 **capability grant 요청** 등장("1 approval waiting on you") → `nodes approve <requestId>` → caps 제공 시작

**최종 검증**: `nodes status --json` → deviceFamily=Windows, caps=[browser, camera, canvas, device, location, screen, system], commands=[browser.proxy, camera.list, device.info, screen.*, ...]. operator도 동시 Connected. 봇 9개 영향 0.

**교훈**: metadata-upgrade 1006이 떠도 **재등록 + 토글 재트리거를 반복하면 결국 정렬됨**. "alpha 버그 불가"로 조기 포기 금지. node capability는 `nodes approve`(devices approve 아님)로 별도 승인.

## gw2(profile pro :18790) 재발 사례 (2026-06-02)
- 대표님 "4개만 보인다" → 9봇 표시 위해 Companion에 **gw2(ws://localhost:18790) Add gateway**. token=gw1과 동일(`4e087352...`, gw2도 `~/.openclaw-pro/secrets.local.json`에 같은 값).
- gw2 operator device 승인(`devices approve cf37e14f` → `Approved a5a6067...`) 후 **재연결 시 gw1과 똑같은 metadata 루프**:
  ```
  [gateway] device metadata upgrade requested reason=metadata-upgrade
  device=a5a6067... claimedDeviceFamily=<none> pinnedDeviceFamily=Windows client=cli
  → [ws] closed before connect 1006   (30s~1m 간격 무한 반복)
  ```
- **핵심 판정**: gw2 봇 **KITT/C3PO/Joi는 channels status `running·connected·transport:just now`로 이미 정상 운영 중** — 이 1006 루프는 **Companion operator/node 연결만** 막을 뿐 봇 영향 0.
- **결론**: gw2를 Companion에 붙이는 실익 없음(봇은 이미 살아있음). gw1에선 토글 반복으로 우연히 정렬됐으나 gw2 재현은 비결정적. **무리하게 매달리지 말고 gw2는 Companion에서 Disconnect**(루프 정지) 권고. Companion은 gw1만으로 충분.
- **토큰 중복 확정 + 해소(2026-06-02 후속)**: secrets 지문 비교로 **kitt/c3po/joi 토큰이 gw1·gw2 완전 동일**(sha 일치) 확정 — 같은 Discord 봇을 두 게이트웨이가 동시 IDENTIFY하는 진짜 충돌원. **javis(FRIDAY)≠javis_claw(TRON)는 다른 토큰**(@javis 표시명만 동일, 안전). 실측 핵심: **gw1이 9봇 전부 단독 운영**(agents 9 + channels 9 connected) → gw2는 잉여. 대표님 결정으로 **gw2(`openclaw-gateway-pro.service`) stop+disable**, gw1 단독 9봇(중단 전후 9→9 검증). CLAUDE.md P-226 항목 "폐지" 갱신 + 다음 세션 gw2 부활 금지 명시. → P-246 "gw2 awaiting readiness"의 진짜 원인 = 이 토큰 중복으로 추정 확정.
- **교훈**: "봇 N개만 보인다"류 표시 의문은 **Companion이 연결한 gateway 1개의 config만 본다**는 사실 + **gateway가 실제 몇 봇을 운영하는지(agents/channels list)**를 분리해서 실측할 것. 트리 개수 ≠ 분산 구조. 추측 모델("gw1 4 + gw2 3") 세우지 말고 `agents list`/`channels status`로 확정.

## 재발 방지
- node 페어링 "1006" 보면 **alpha 버그로 단정 말 것** — `OpenClawTray/openclaw-tray.log` + gateway `security audit ... metadata-upgrade claimedDeviceFamily` 로그로 진짜 원인(metadata pin 충돌) 확인.
- **표시(Companion 트리)를 위해 봇 인프라에 매달리지 말 것**: 봇이 channels connected면 운영은 OK. Companion 연결은 부가 기능 — 1006 루프에 시간/리스크 쓰지 말고 Disconnect.
- node 승인은 `nodes pending`이 아니라 **device role-upgrade** → `devices list --json`의 pending에서 requestId 찾아 `devices approve`.
- setup code 생성: gateway loopback이면 `--public-url ws://localhost:18789` 강제.

## 관련
- [[pitfall-246-openclaw-probe-resolved-not-equal-online-presence]] (probe≠online, 봇 상태 오판)
- [[pitfall-243-gw1-restart-breaks-gw2-websocket-specialist-bots-down]] (봇 인프라 함부로 건드리기 금지)
- [[pitfall-229-openclaw-522-harness-bug-527-recovery]] (정확한 에러 문구 → 타겟 수정, 추측 금지)
