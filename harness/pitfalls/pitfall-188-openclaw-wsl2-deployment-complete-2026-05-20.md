# P-188: OpenClaw v2026.5.18 WSL2 완전 운영 절차 및 함정 5종

- **발견**: 2026-05-20
- **영향**: OpenClaw를 WSL2 Ubuntu에 처음 배포할 때 마주치는 비명시적 함정들. 각각 독립적으로 silent fail.

## 증상

- `which openclaw` → Windows binary 반환 → WSL 내에서 실행 시 동작 불안정
- `@openai/codex` WSL에서 platform binary 없음 에러 (Windows용 `.exe` 번들 불일치)
- `@anthropic-ai/claude-code` ELF binary 미설치로 `claude` 명령 실행 불가
- `state_5.sqlite` migration 충돌로 codex 기동 실패
- `agents.defaults.fast` / `agents.defaults.thinking` 키 적용 안 됨 (schema 미존재)

## 원인 및 함정 5종

### 함정 1 — `which openclaw`가 Windows binary 우선 반환
- PATH에 Windows `/mnt/c/.../.npm-global/bin`이 먼저 잡혀 있으면 Windows `.cmd` 래퍼 반환
- WSL에서 `.cmd` 직접 실행 → ENOENT (P-185 동일 패턴)
- **해결**: 항상 WSL native 절대경로 `~/.npm-global/bin/openclaw` 호출

### 함정 2 — `@openai/codex` Windows 설치본이 WSL에서 깨짐
- Windows에서 설치된 codex는 `codex-win32-x64` platform binary 번들 → ELF 환경에서 실행 불가
- WSL에서 `npm i -g @openai/codex` 재설치 필수 (`codex-linux-x64` platform binary 별도 다운로드)

### 함정 3 — `@anthropic-ai/claude-code-linux-x64` optional dependency가 npm platform detection으로 skip됨
- `@anthropic-ai/claude-code` 메인 패키지 설치 시 platform-specific optional dependency가 자동으로 선택되지 않는 경우 있음
- `npm i -g @anthropic-ai/claude-code-linux-x64` 명시 설치 후 심볼릭 링크 확인 필요
- npm prefix bin에 `claude.exe` (Windows) 링크가 남아 있으면 ELF binary로 redirect

### 함정 4 — codex-home Windows→Linux 복사 시 SQLite migration 충돌
- `/mnt/c/Users/<USER>/.codex/` (또는 `$APPDATA/codex/`) 전체를 `~/.codex/`로 복사하면 `state_5.sqlite` schema migration 충돌 → codex 기동 실패
- **안전 복사 대상**: `sessions/*.jsonl` 만 (순수 텍스트, platform 무관)
- **조치**: `~/.codex/` 전체 삭제(백업) → codex가 새 DB 자동 생성하게 둠

### 함정 5 — `agents.defaults.fast` / `agents.defaults.thinking` 키가 OpenClaw schema에 없음
- `openclaw.json` 에 이 키를 넣어도 무시됨 (unknown field)
- **실제 위치**:
  - fast (priority 서비스 티어): `plugins.entries.codex.config.appServer.serviceTier = "priority"`
  - thinking (추론 강도): codex CLI 자체 설정 `~/.codex/config.toml` → `model_reasoning_effort = "high" | "xhigh" | "medium" | "low" | "minimal"`

## 검증된 배포 절차 (2026-05-20)

```bash
# 1. WSL Ubuntu 확인 (이미 설치 시 install 불필요)
wsl --list --verbose

# 2. WSL 진입 후 user-level npm prefix 설정 (sudo 회피)
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=$HOME/.npm-global/bin:$PATH' >> ~/.profile
source ~/.profile

# 3. OpenClaw WSL native 설치
npm i -g openclaw

# 4. codex Linux native 설치 (Windows용 재설치 필수)
npm i -g @openai/codex

# 5. claude Linux binary 명시 설치 (함정 3 대응)
npm i -g @anthropic-ai/claude-code-linux-x64

# 6. Claude credentials Windows → Linux 복사
cp /mnt/c/Users/<USER>/.claude/.credentials.json ~/.claude/.credentials.json
chmod 600 ~/.claude/.credentials.json

# 7. codex-home: sessions만 안전 복사 (함정 4 대응)
mkdir -p ~/.codex/sessions
cp /mnt/c/Users/<USER>/.codex/sessions/*.jsonl ~/.codex/sessions/ 2>/dev/null || true
# state_*.sqlite 는 복사하지 않음

# 8. onboard skip (이미 설정 완료 시)
~/.npm-global/bin/openclaw onboard \
  --flow quickstart --auth-choice skip \
  --accept-risk --non-interactive --skip-health

# 9. Discord 채널 등록 (Windows config에서 토큰 재사용)
DISCORD_TOKEN=$(jq -r '.plugins.entries.discord.config.token' \
  /mnt/c/Users/<USER>/.openclaw/openclaw.json)
~/.npm-global/bin/openclaw channels add \
  --channel discord --token "$DISCORD_TOKEN"
```

## openclaw.json 핵심 설정 (검증됨)

```json
{
  "agents": {
    "defaults": {
      "models": {
        "openai/gpt-5.5": {
          "agentRuntime": { "id": "codex" }
        },
        "anthropic/claude-sonnet-4-5": {
          "agentRuntime": { "id": "claude-cli" }
        }
      }
    },
    "entries": {
      "codex-agent": { "id": "codex-agent", "model": "openai/gpt-5.5" },
      "claude-agent": { "id": "claude-agent", "model": "anthropic/claude-sonnet-4-5" }
    }
  },
  "plugins": {
    "entries": {
      "discord": { "enabled": true, "config": { "token": "<TOKEN>" } },
      "codex": {
        "config": {
          "appServer": { "serviceTier": "priority" }
        }
      }
    }
  },
  "channels": {
    "bindings": [
      { "match": { "peer": { "id": "<CODE_CHANNEL_ID>" } }, "agentId": "claude-agent" },
      { "match": { "peer": { "id": "<CHAT_CHANNEL_ID>" } }, "agentId": "codex-agent" }
    ]
  }
}
```

## thinking 강도 설정 (~/.codex/config.toml)

```toml
model_reasoning_effort = "high"   # "xhigh" | "high" | "medium" | "low" | "minimal"
```

## 페르소나 영구화 (봇 재시작 후에도 유지)

- `~/.openclaw/workspace/IDENTITY.md` — 에이전트 자기소개, 호칭, 이모지 등
- `~/.openclaw/workspace/USER.md` — 대표님 선호, 합니다체, "대표님" 호칭 명시
- 봇 응답에서만 페르소나를 설정하면 재시작 시 초기화됨 → 반드시 파일 작성 필요

## systemd 영구화

```bash
# systemd user service 등록
mkdir -p ~/.config/systemd/user/
cat > ~/.config/systemd/user/openclaw.service <<'EOF'
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
ExecStart=/home/<USER>/.npm-global/bin/openclaw start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable openclaw
systemctl --user start openclaw
loginctl enable-linger $USER

# Native Windows daemon 영구 disable (관리자 PowerShell)
# schtasks /Change /TN "OpenClaw Gateway" /DISABLE
```

## 검증된 결과 (2026-05-20 09:22 KST)

| 항목 | 결과 |
|------|------|
| Discord 채널 멘션 응답 | ✅ 즉시 응답 |
| 한국어 합니다체 + "대표님" 호칭 | ✅ |
| 🦞 이모지 | ✅ |
| 외부 검색 도구 사용 (날씨 등) | ✅ |
| 두 채널 독립 agent 라우팅 | ✅ (#코드작업=claude, #일반채팅=codex) |
| 봇 재시작 후 페르소나 유지 | ✅ (IDENTITY.md/USER.md 기반) |

## 재발 방지

- WSL 환경에서 `which <tool>` 결과를 맹신하지 말 것 — Windows PATH 오염 항상 의심
- platform-specific npm optional dependency는 반드시 명시 설치 확인
- codex state DB는 절대 cross-platform 복사 금지 (sessions/*.jsonl 만 안전)
- OpenClaw config 키는 공식 schema 기준으로 확인 (`agents.defaults.*` 비공식 키 시도 금지)

## 관련

- [[pitfall-184-openclaw-windows-discord-readiness]] ← Native Windows 불안정성 (정정됨)
- [[pitfall-185-openclaw-anthropic-plugin-cmd-enoent]] ← .cmd ENOENT (Native Windows 한정)
- [[pitfall-186-openclaw-codex-binary-env-var-fix]] ← env var fix (Native Windows 한정)
- [[pitfall-187-openclaw-wsl2-deployment-success]] ← 초기 WSL2 성공 확인
