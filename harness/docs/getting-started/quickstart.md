---
title: 5분 퀵스타트
type: tutorial
diátaxis: Tutorial
---

# 퀵스타트 — 5분 설치

## 사전 요구사항

설치 전 아래 항목을 확인하십시오.

| 항목 | 버전/조건 | 확인 명령 |
|------|----------|----------|
| Node.js | 20 이상 | `node -v` |
| Git | 2.40 이상 | `git --version` |
| Claude Code CLI | 최신 | `claude --version` |
| Git Bash (Windows) | — | Windows Terminal에서 `bash` 실행 |

---

## 1단계: 리포 클론

```bash
git clone https://github.com/yourorg/jamesclew.git
cd jamesclew
```

---

## 2단계: 설치 실행

**Git Bash (권장)**
```bash
bash harness/install.sh
```

**PowerShell (대안)**
```powershell
pwsh harness/install.ps1
```

---

## install.sh 5단계 마법사

인터랙티브 설치 시 아래 순서로 질문이 나타납니다.

| 단계 | 질문 | 입력 예시 |
|------|------|----------|
| 1. Persona | 호칭, 톤, 언어 등 | `대표님` / `witty` / `ko` |
| 2. Modules | Telegram/gbrain/Codex 등 활성화 | `y` / `n` |
| 3. MCP | Perplexity, Tavily 등 등록 | API 키 입력 |
| 4. API 키 | `.claude.env` 에 저장 | `TELEGRAM_BOT_TOKEN=...` |
| 5. 완료 | `~/.claude/` 배포 확인 | — |

설치가 완료되면 `~/.claude/hooks/`, `~/.claude/rules/`, `~/.claude/commands/` 에 파일이 복사됩니다.

---

## 3단계: 설치 검증

Claude Code를 새로 열고 다음 명령을 실행합니다.

```
/audit
```

정상 출력 예시:
```
[PASS] CLAUDE.md loaded (337 lines)
[PASS] hooks: 14 active
[PASS] rules: 5 loaded
[PASS] Ghost Mode: enabled
[PASS] 5H tracking: active
```

---

## 설치 실패 시 체크리스트

- `bash: harness/install.sh: No such file` → `cd jamesclew` 후 재실행
- `CLAUDE.md not loaded` → `bash harness/deploy.sh` 로 수동 배포
- hook이 0개 → `~/.claude/hooks/` 디렉토리 존재 여부 확인
- API 키 오류 → `~/.claude.env` 파일 직접 편집 후 Claude Code 재시작
- PowerShell 실행 정책 오류 → `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

---

## 다음 단계

- 하네스가 어떻게 동작하는지 이해하려면 `getting-started/how-it-works.md` 를 읽으십시오.
- 호칭·톤을 바꾸려면 `configure/persona.md` 를 참조하십시오.
- Windows 전용 이슈가 있으면 `getting-started/install-windows.md` 를 확인하십시오.
