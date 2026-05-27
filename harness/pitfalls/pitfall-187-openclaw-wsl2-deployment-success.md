# P-187: OpenClaw v2026.5.18 WSL2 Ubuntu 전환 + 영구화 성공 절차

- **발견**: 2026-05-20
- **영향**: P-184 (Native Windows 채널 응답 불안정) 우회 + Discord 봇 즉시 응답 + Codex runtime 정상 동작 확보

## 검증된 결과

- Discord 채널 멘션 → 1분 이내 즉시 응답 (09:22 멘션 → 09:23 봇 응답)
- 한국어 합니다체 + "대표님" 호칭 + 🦞 이모지 자동 적용
- 외부 검색 도구 정상 사용 (날씨 질문 → 실시간 날씨 + 우산·겉옷 권유, "수정됨" = tool 호출 흔적)
- Native Windows에서 불가능했던 일관성 + tool 사용이 WSL2에서 완전 정상화

## 검증된 설치 절차

### 1. WSL Ubuntu 확인

```powershell
wsl --list --verbose
```

이미 설치되어 있으면 `wsl --install` 불필요. Ubuntu가 목록에 있으면 바로 2단계 진행.

### 2. user-level npm prefix 설정 (sudo 회피)

```powershell
wsl -d Ubuntu -e bash -c "mkdir -p ~/.npm-global && npm config set prefix '~/.npm-global' && echo 'export PATH=\$HOME/.npm-global/bin:\$PATH' >> ~/.profile"
```

sudo 없이 npm 글로벌 패키지를 설치하기 위한 사전 설정입니다.

### 3. OpenClaw 설치

```powershell
wsl -d Ubuntu -e bash -lc "npm i -g openclaw"
```

user-level, sudo 없음. `-lc` 플래그로 `.profile` 반영 (PATH 적용).

### 4. ⚠️ 함정: which openclaw 우선순위 문제

```bash
which openclaw
# /mnt/c/Users/<USER>/AppData/Roaming/npm/openclaw  ← Windows binary 반환!
```

`which openclaw`가 Windows binary (`/mnt/c/...`)를 우선 반환합니다. WSL2 Linux native binary를 호출하려면 반드시 절대경로 사용:

```bash
~/.npm-global/bin/openclaw --version
```

### 5. Linux native @openai/codex 설치

```powershell
wsl -d Ubuntu -e bash -lc "npm i -g @openai/codex"
```

Windows용 codex는 `codex-linux-x64` platform binary가 없어 WSL 내부에서 실행 시 깨집니다. Linux native 버전을 별도 설치해야 합니다.

### 6. onboard skip 모드 실행

```powershell
wsl -d Ubuntu -e bash -lc "~/.npm-global/bin/openclaw onboard --flow quickstart --auth-choice skip --accept-risk --non-interactive --skip-health"
```

### 7. Discord 채널 등록

```powershell
wsl -d Ubuntu -e bash -lc "~/.npm-global/bin/openclaw channels add --channel discord --token <BOT_TOKEN> --name OpenClaw-Discord"
```

Native Windows config에서 토큰 재사용 가능:
```bash
cat /mnt/c/Users/<USER>/.openclaw/openclaw.json | grep token
```

### 8. Codex OAuth 자격증명 복사

Native Windows에서 이미 Codex 인증이 완료된 경우 그대로 복사합니다:

```bash
cp -r /mnt/c/Users/<USER>/.codex/* ~/.codex/
cp /mnt/c/Users/<USER>/.openclaw/agents/main/agent/auth-profiles.json \
   ~/.openclaw/agents/main/agent/
cp -r /mnt/c/Users/<USER>/.openclaw/agents/main/agent/codex-home/ \
   ~/.openclaw/agents/main/agent/
```

### 9. agentRuntime 매핑 (openclaw.json 직접 수정)

Python으로 JSON 구조 수정 (jq 미설치 환경 대응):

```python
import json, pathlib

p = pathlib.Path.home() / ".openclaw/openclaw.json"
cfg = json.loads(p.read_text())

cfg["agents"]["defaults"]["model"]["primary"] = "openai/gpt-5.5"
cfg["agents"]["defaults"]["models"]["openai/gpt-5.5"] = {
    "agentRuntime": {"id": "codex"}
}
cfg["plugins"]["entries"]["codex"]["enabled"] = True
cfg["plugins"]["entries"]["discord"]["enabled"] = True

p.write_text(json.dumps(cfg, indent=2))
print("완료")
```

### 10. systemd user service 영구화

서비스 파일 생성:

```bash
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/openclaw-gateway.service << 'EOF'
[Unit]
Description=OpenClaw Gateway
After=network-online.target

[Service]
Type=simple
ExecStart=%h/.npm-global/bin/openclaw gateway run
Restart=on-failure
RestartSec=5
Environment=PATH=%h/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

[Install]
WantedBy=default.target
EOF
```

서비스 활성화:

```bash
systemctl --user daemon-reload
systemctl --user enable openclaw-gateway.service
systemctl --user start openclaw-gateway.service
loginctl enable-linger creator   # WSL 재시작 후에도 user service 유지
```

### 11. Native Windows daemon 충돌 방지

```powershell
schtasks /End /TN "OpenClaw Gateway"
```

부팅 시 자동 시작 영구 disable은 관리자 권한 필요 (별도 작업). 수동으로 끄는 것만으로도 WSL2 daemon과 충돌 방지 가능합니다.

## 동작 원리 요약

| 항목 | Native Windows | WSL2 Ubuntu |
|------|--------------|-------------|
| Discord gateway READY | 30초 timeout 반복 | 정상 도달 (즉시) |
| guild channel inbound | 간헐 (매우 불안정) | 안정 (1분 내 응답) |
| tool 사용 (날씨 등) | 불안정 | 정상 |
| 합니다체 + 이모지 | 불안정 | 정상 |
| Codex runtime | .cmd 경로 혼선 | 네이티브 바이너리 |

## 재발 방지

- OpenClaw 계열 도구는 WSL2 Ubuntu를 기본 실행 환경으로 사용합니다
- Native Windows에서 Discord gateway 문제가 재발하면 WSL2 daemon 상태를 먼저 확인합니다:
  ```bash
  systemctl --user status openclaw-gateway.service
  ```
- `which <tool>` 결과가 `/mnt/c/...`이면 Windows binary임 — 절대경로 사용 필수

## 관련

- [[pitfall-184-openclaw-windows-discord-readiness]] — 이 절차로 해결된 Native Windows 불안정 문제
- [[pitfall-186-openclaw-codex-binary-env-var-fix]] — Native Windows 시도 흔적 (WSL2에서는 불필요)
- OpenClaw 매뉴얼: docs.openclaw.ai/channels/discord, docs.openclaw.ai/deployment/linux
