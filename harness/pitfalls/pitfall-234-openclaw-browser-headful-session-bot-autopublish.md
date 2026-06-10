# P-234: OpenClaw browser headful 세션 심기 + 봇 자율 발행 구축 (티스토리)

- **구축**: 2026-05-30 (대표님 지시: "OpenClaw browser 운영 문서 정독 후 세션 심기 경로 확정, 한 번에 완성")
- **목적**: 메인세션(claude-in-chrome) 직접 개입 없이 **OpenClaw 봇이 자체 browser로 티스토리 자율 발행**.

## 확정 경로 (문서 정독 + 실측)
출처: docs.openclaw.ai/tools/browser, /cli/browser, /tools/browser-login

### 1. headless fallback 원인 + 해결
- **원인**: OpenClaw browser는 gateway가 관리. gateway systemd 서비스 Environment에 **DISPLAY 없음** → "Linux hosts without DISPLAY/WAYLAND_DISPLAY run headless automatically". CLI 앞에 env 붙여도 이미 뜬 gateway엔 무관.
- **해결**: gateway 서비스에 디스플레이 env 주입 (WSLg):
  ```
  ~/.config/systemd/user/openclaw-gateway.service.d/headful.conf
  [Service]
  Environment=DISPLAY=:0
  Environment=WAYLAND_DISPLAY=wayland-0
  Environment=XDG_RUNTIME_DIR=/run/user/1000
  Environment=OPENCLAW_BROWSER_HEADLESS=0
  ```
  → `systemctl --user daemon-reload && restart openclaw-gateway.service` → `browser stop && start` → `status`에 **headless: false (env)**.
- WSLg 확인: `/mnt/wslg/runtime-dir/wayland-0` 존재, `/run/user/1000/wayland-0` 심링크.

### 2. 세션 심기 (카카오 1회 로그인 → 영속)
- 카카오 OAuth는 봇 자동로그인 불가(CAPTCHA/Cloudflare, 실측+조사 일치). **최초 1회 사람 로그인 필수**.
- headful Edge 창(WSLg로 Windows 화면 표시)에서 대표님이 "카카오계정으로 로그인" 1회.
- **쿠키 영속 확인됨(실측)**: browser 완전 stop/start 후에도 `manage/newpost` 접근 + 제목란 존재. 문서: "Cookies persist within a managed browser profile between runs". 만료(수일~수주) 시만 재로그인.
- 프로필: `openclaw` (userdata `~/.openclaw/browser`). `user` 프로필(existing-session/chrome-mcp)은 attach 300ms 타임아웃 — 안 씀.

### 3. 봇 자율 발행 (능력)
- 4봇 전원 `tools: inherit=all plugins` + `plugins.allow`에 browser → browser 도구 전원 상속.
- browser CLI 풀세트: navigate/snapshot/click/type/fill/select/press/**upload**(파일 직접, claude-in-chrome "세션폴더만" 제약 없음)/**dialog --accept**(KEDITOR HTML모드 confirm 한 줄 처리)/cookies/screenshot/evaluate.
- 워크플로우: ORCHESTRATION.md §14-B.

### 4. 봇간 통신 제약 (봇 테스트 시 주의)
- `channels.discord.allowBots: "mentions"` + `allowFrom: ['discord:1200798952665137183']` (default/main 계정).
- **봇→봇 메시지는 @멘션 + 허용목록에 발신 봇 ID 있어야** 트리거. claude/ollama/codex 계정엔 `1506248517478518854` 추가됨.
- **사람(대표님)→봇은 무관** (requireMention=None) → 실사용 "발행해" 트리거 정상.
- 메인세션이 EVE(jamesclaw-cc) Discord MCP로 봇 테스트 시 멘션+allowFrom 필요. JARVIS가 별도 allowFrom 패치 준비 중(게이트웨이 재시작 시 적용).

## 재발 방지 / 재현
- gateway 재시작 시 headful.conf override 유지됨(systemd drop-in). 단 P-229 5.27 재설치 등으로 서비스 파일 갱신 시 override 잔존 확인.
- 봇 발행 트리거 실사용 = 대표님→JARVIS. 봇 자율 체인(EVE→JARVIS)은 allowFrom 정비 후.
- headful Edge 창은 WSLg 의존 → WSL 재부팅 후 DISPLAY/wayland 재확인(P-223/P-224 keepalive와 함께).

## 관련
- [[pitfall-233-openclaw-browser-capability-not-checked-manual]] (능력 매뉴얼 확인)
- [[pitfall-230-blog-publish-firebase-image-pipeline]] (이미지 — upload면 Firebase 우회 불필요)
- ORCHESTRATION.md §14-B
- docs.openclaw.ai/tools/browser
