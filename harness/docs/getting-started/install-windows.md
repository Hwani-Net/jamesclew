---
title: Windows 설치 가이드
type: tutorial
diátaxis: Tutorial
platform: windows
---

# Windows 설치 가이드

## Git Bash vs PowerShell

하네스 hooks는 bash 스크립트입니다. Windows에서는 **Git Bash 필수**입니다.

| 방법 | 명령 | 주의 |
|------|------|------|
| Git Bash (권장) | `bash harness/install.sh` | hook 전체 동작 |
| PowerShell | `pwsh harness/install.ps1` | 기본 배포만. hook은 Git Bash 경유 |

Claude Code 자체는 Windows Terminal 또는 PowerShell에서 실행해도 됩니다. 단, 하네스 hook이 bash를 호출하므로 Git Bash가 `PATH`에 있어야 합니다.

---

## 환경변수 등록

PowerShell 프로필에 영구 등록합니다.

```powershell
# 프로필 열기
notepad $PROFILE

# 아래 내용 추가
$env:TELEGRAM_BOT_TOKEN = "your-token"
$env:TELEGRAM_CHAT_ID   = "your-chat-id"
$env:OBSIDIAN_VAULT     = "C:/Users/YourName/Obsidian-Vault"
$env:TAVILY_API_KEY     = "tvly-..."
$env:PERPLEXITY_API_KEY = "pplx-..."
```

또는 `.claude.env` 파일을 사용합니다 (Claude Code가 자동 로드).

```bash
# D:/jamesclew/.claude.env
TELEGRAM_BOT_TOKEN=your-token
TELEGRAM_CHAT_ID=your-chat-id
OBSIDIAN_VAULT=C:/Users/YourName/Obsidian-Vault
```

---

## .claude.env 보안 설정

`.claude.env` 는 시크릿이 포함된 파일입니다. 소유자만 읽을 수 있도록 권한을 제한합니다.

```powershell
# 현재 사용자만 읽기 허용
icacls "$env:USERPROFILE\.claude.env" /inheritance:r /grant "$env:USERNAME:(R)"
```

---

## Windows 전용 이슈

### 1. bash hook 경로 오류

증상: `bash: $HOME/.claude/hooks/xxx.sh: No such file`

원인: Windows에서 `$HOME` 이 `/c/Users/YourName` 형식이 아닐 수 있습니다.

해결:
```bash
# Git Bash에서 확인
echo $HOME
# 예상: /c/Users/YourName

# 아니라면 .bashrc에 추가
echo 'export HOME=/c/Users/YourName' >> ~/.bashrc
```

### 2. PowerShell Tool (v2.1.112+)

PowerShell 스크립트를 Claude Code에서 직접 실행하려면 opt-in이 필요합니다.

```powershell
$env:CLAUDE_CODE_USE_POWERSHELL_TOOL = "1"
claude
```

bash hook은 이 설정과 무관하게 여전히 Git Bash를 경유합니다.

### 3. 경로 구분자

하네스 내부에서 파일 경로는 항상 슬래시(`/`)를 사용합니다. 백슬래시(`\`)는 bash에서 오동작합니다.

```bash
# 올바름
D:/jamesclew/harness/hooks/

# 잘못됨
D:\jamesclew\harness\hooks\
```

---

## 배포 업데이트

하네스 소스(`D:/jamesclew/harness/`)를 수정한 후 배포합니다.

```bash
# 페르소나 치환 없이 빠른 배포 (개발용)
bash harness/deploy.sh

# 페르소나 치환 포함 전체 재설치
bash harness/install.sh --non-interactive
```

배포 후 Claude Code를 재시작해야 새 설정이 적용됩니다.

---

## Agent Teams (Windows Terminal)

Agent Teams는 tmux 없이 Windows Terminal에서 바로 동작합니다.

- teammate 전환: `Shift+Down`
- in-process 모드 기본 활성
- 환경변수 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 필요 (settings.json에 이미 설정됨)
