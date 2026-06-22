# P-262: codex OAuth 토큰 전 계정 만료 → TARS(OpenClaw codex agent) 다운, refresh token rotation 무효 → 재로그인 필수

- **발견**: 2026-06-08 (대표님 "TARS 구현 작업 전부 막힘", JARVIS는 "gpt-5.3-codex-spark 모델 거부"로 오진)
- **영향**: OpenClaw codex agent(TARS) 전면 다운. Discord 멘션 무응답. codex 기반 모든 작업(코드 리뷰/구현) 차단.

## 증상
- TARS(codex 봇) Discord 무응답 또는 빈 응답
- JARVIS 진단: "기본모델 gpt-5.3-codex-spark가 ChatGPT 백엔드에서 거부" ← **오진** (실제 model은 openai/gpt-5.5)
- codex 호출 시: `401 Unauthorized, url: wss://chatgpt.com/backend-api/codex/responses`

## 근본 원인 (실측 규명)
1. **codex OAuth 토큰 만료**: `~/.codex/auth.json` last_refresh=2026-05-15 (24일 경과). access_token 13일 전 만료, account-1~8 전부 60일 전 만료.
2. **codex-refresh 14일 주기 누적 미실행** — 주기적 갱신이 안 돼 refresh token까지 무효화.
3. **refresh token rotation 무효**: 자동 refresh 시도 시 `"refresh token was already used. Please log out and sign in again."` — OAuth refresh token은 one-time rotation이라, 어떤 이유로 무효화되면 자동 갱신 불가 → **재로그인만이 해법**.

## 진단 절차 (모델 거부로 오인 금지)
```bash
# 1. codex agent model 확인 (gpt-5.5인데 "spark 거부"면 오진)
python3 -c "import json; d=json.load(open('/home/creator/.openclaw/openclaw.json')); print([a.get('model') for a in d['agents']['list'] if a.get('id')=='codex'])"
# 2. 토큰 만료 실측 (JWT exp 디코드)
python3 -c "import json,time,base64; d=json.load(open('/home/creator/.codex/auth.json')); t=d['tokens']['access_token']; p=t.split('.')[1]; p+='='*(-len(p)%4); exp=json.loads(base64.urlsafe_b64decode(p))['exp']; print('exp', time.strftime('%Y-%m-%d', time.localtime(exp)), f'{(exp-time.time())/86400:+.1f}d')"
# 3. 자동 refresh 가능 여부 (실패 메시지로 판단)
CODEX_HOME=/home/creator/.codex /home/creator/.npm-global/bin/codex exec 'reply OK'  # "already used" = 재로그인 필요
```

## 해결 (검증됨)
1. **refresh 자동갱신 먼저 시도** — access만 만료고 refresh 유효하면 codex 호출 시 자동 갱신. 실패("already used")면 2단계.
2. **재로그인** (대표님 ChatGPT 계정 OAuth):
   ```bash
   CODEX_HOME=/home/creator/.codex /home/creator/.npm-global/bin/codex login   # background 실행
   # → "navigate to this URL" OAuth URL 출력 (localhost:1455 콜백)
   # → 대표님이 브라우저에서 ChatGPT 로그인 → "Successfully logged in"
   ```
   - **mirrored 네트워킹(P-255-B)이라 Windows 브라우저에서 WSL localhost:1455 콜백 정상**. NAT였으면 콜백 실패 위험.
   - 비번 입력은 메인 세션 금지 — 대표님 브라우저에서만.
3. **검증**: auth.json last_refresh 갱신 + codex exec "TARS_OK" + **TARS 봇 Discord 멘션 실응답** (codex appServer가 새 토큰 자동 로드, gateway 재시작 불필요 — 매 호출 토큰 읽음).

## 핵심 사실
- OpenClaw codex agent는 **codexHome 기본값 = ~/.codex 공유** (per-agent 격리 home 아님). appServer command = `~/.npm-global/bin/codex`. 즉 codex CLI 재인증이 TARS에 그대로 반영.
- codex appServer는 **매 호출 토큰 읽음** → 재인증 후 gateway 재시작 불필요 (실측: 재시작 없이 TARS_OK).

## 재발 방지
- **codex-refresh 14일 주기 강제** — 누적 미실행이 refresh token 무효화의 근본. 주기 자동화(cron/알림) 점검 필요.
- TARS 무응답 시 "모델 문제"로 단정 말고 **토큰 만료 먼저 실측** (auth.json exp).
- last_refresh가 14일 초과면 사전 재인증.

## 재발 — 2026-06-22 (Windows 메인 + Cowork, 동시 갱신 burn + 콜백 오탐)

같은 `401 ... refresh token was already used`가 **Windows 메인 머신**에서 재발(TARS/WSL 아님). 대표님이 "codex MCP 에러 잦음 → 삭제"했으나 **MCP는 증상이지 원인 아님** — CLI·MCP·plugin 모두 같은 `~/.codex/auth.json`을 공유하므로 토큰 만료 시 전부 401.

### 추가 규명
1. **동시 갱신이 refresh token을 태움**: Cowork 데스크톱 codex MCP(P-269) + CLI(`codex exec`) + codex-rotate가 **single-use refresh token을 동시 갱신** → 한쪽이 rotation하면 나머지가 "already used". → **codex 접속은 CLI 단일 경로만 유지, 데스크톱 MCP 재추가 금지**(갱신 경쟁자 제거 = 근본 재발 방지).
2. **콜백 "사이트에 연결할 수 없음" = 오탐 가능**: `localhost:1455` 로그인 서버가 종료 직전 콜백을 받아 **토큰 교환은 성공**할 수 있음. 브라우저 에러로 실패 단정 금지 → **반드시 `codex exec`로 실검증** (이번: 브라우저 "연결 안 됨"에도 auth.json 생성 + `codex exec`→PONG 성공).
3. **백그라운드 `codex login` 프로세스 미유지 주의**: Start-Process 백그라운드 login이 콜백 도착 전 죽으면 1455 listener 소멸 → 콜백 실패. 가장 안정적인 건 **사용자 터미널에서 직접 `codex login`**. 단 죽어도 교환이 끝났을 수 있으니 codex exec 검증 우선.

### Windows 재인증 절차 (검증됨, 2026-06-22)
```bash
bash harness/scripts/codex-refresh-helper.sh prepare 1   # rm ~/.codex/auth.json (⛔ codex logout 금지 — P-069 서버측 revoke)
codex login                                              # 브라우저 OAuth, hwanizero01(계정1). 콜백 에러 떠도 일단 진행
codex exec --skip-git-repo-check "say PONG"              # 실검증 (PONG=성공, 401=재시도)
bash harness/scripts/codex-refresh-helper.sh save 1      # 새 토큰 → account1.json 백업
```
- 현 체제: **Pro 단일 계정 hwanizero01**(account2~6 아카이브, CLAUDE.md STICKY) — 6계정 아님.
- 비용 인지: `codex exec` 1회 = 풀 에이전트 턴(실측 ~38s·~27.5k tokens·GPT-5.5, Claude와 별도 quota).

## 관련
- CLAUDE.md codex-refresh 스킬 (6계정 OAuth 갱신, 14일 주기)
- [[pitfall-269-cowork-desktop-mcp-separate-from-cli-codex-mcp-server]] — Cowork MCP ≠ CLI codex MCP (이번 동시 갱신 원인)
- [[pitfall-069-codex-logout-revokes-server-token]] — logout 금지 (rm auth.json만)
- [[pitfall-255-...]] mirrored 네트워킹 (OAuth localhost 콜백 의존)
- P-241 WSL codex 경로 (Windows stale binary 구분)
