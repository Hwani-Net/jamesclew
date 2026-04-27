# JamesClaw Agent Harness

자율 실행 에이전트 "JamesClaw"의 하네스 (rules + hooks + commands + scripts).
Anthropic Harness Ablation 연구(2026-04) 기반 Planner-Generator-Evaluator 3-에이전트 구조.

> **상세 사용설명서**: [docs/index.md](./docs/index.md) — 설치, 규칙, 훅, 스킬, 라우팅, PITFALL 레퍼런스를 Diátaxis 4분면으로 정리한 풀 문서입니다.

## 핵심 철학

- **Build to Delete**: 모델이 강해지면 하네스 요소 제거 (ablation 기반)
- **Generator ≠ Evaluator**: 자기 검수 편향 차단을 외부 모델 분리로 강제
- **Evidence-First**: 도구 출력 증거 없이 보고 금지 (hook 강제)
- **Ghost Mode**: "할까요?" 금지, 즉시 실행

## 구조

```
harness/
├── CLAUDE.md              # 글로벌 에이전트 규칙 (persona 치환 전 템플릿)
├── settings.json          # Claude Code 설정 (hooks, MCP, 권한)
├── rules/                 # 상세 규칙 (architecture, quality, security, design_rubric)
├── hooks/                 # PreToolUse / PostToolUse / Stop / SessionStart 훅
├── commands/              # 슬래시 커맨드 (/prd, /pipeline-run, /qa, /audit)
├── scripts/               # 자동화 스크립트 (audit, evaluator, self-evolve)
├── agents/                # 서브에이전트 정의
├── tools/HydraTeams/      # Agent Teams 프록시 (GPT-4o-mini 라우팅)
├── install.sh             # 대화형 인스톨러 (bash / macOS / Linux / WSL)
├── install.ps1            # 대화형 인스톨러 (Windows PowerShell)
├── deploy.sh              # 개발자 로컬 배포 (~/.claude 즉시 덮어쓰기)
├── persona.yaml.example   # 페르소나 템플릿 (호칭·언어·톤)
├── modules.yaml           # MCP/외부도구 카탈로그
└── .env.example           # 환경변수 템플릿
```

## 새 머신 설치

### 원라인 설치 (대화형 마법사)

**macOS / Linux / WSL / Git Bash:**
```bash
git clone <YOUR_REPO_URL> jamesclew && cd jamesclew && bash harness/install.sh
```

**Windows PowerShell (관리자 권한 불필요):**
```powershell
git clone <YOUR_REPO_URL> jamesclew; cd jamesclew; powershell -ExecutionPolicy Bypass -File harness\install.ps1
```

설치 마법사는 다음을 순서대로 물어봅니다:
1. **페르소나** — 호칭(기본: 대표님), 언어, 톤
2. **모듈 선택** — Telegram 알림, Obsidian 연동, Codex/copilot-api/Ollama
3. **MCP 서버 선택** — Perplexity, Tavily, Stitch, Desktop Control
4. **API 키 입력** — 선택한 모듈에 필요한 키만 (hidden input)
5. **Obsidian Vault 자동 셋업** — OBSIDIAN_VAULT 경로 입력 시 폴더 구조 자동 생성
6. **gbrain 지식 베이스 셋업** — y/n 선택, pitfalls/rules 자동 임포트

설치 완료 시:
- `~/.harness.env` — API 키 (퍼미션 600)
- `~/.harness/persona.yaml` — 페르소나 설정
- `~/.claude/` — 렌더링된 CLAUDE.md(호칭·에이전트명 치환) + hooks/rules/scripts
- `$OBSIDIAN_VAULT/` — BASB 7계층 폴더 구조 자동 생성 (README 시드 포함)
- MCP 서버는 `claude mcp add`로 자동 등록

#### Obsidian Vault 자동 생성 폴더 구조
```
{OBSIDIAN_VAULT}/
├── 00-inbox/          # BASB Capture (gitkeep)
├── 01-jamesclaw/      # 하네스 설계, sessions, research, reviews, docs
├── 02-projects/       # 프로젝트별 문서
├── 03-knowledge/      # 영구 지식 베이스
├── 04-personal/       # 개인 메모
├── 05-wiki/           # BASB 3-tier
│   ├── sources/       # Raw tier
│   ├── entities/      # Raw tier
│   ├── distilled/     # Distilled tier
│   ├── concepts/      # Distilled tier
│   ├── analyses/      # Distilled tier
│   └── synthesized/   # Synthesized tier
└── 06-raw/            # Raw 자료 (gitkeep)
```

이미 폴더가 존재하면 건너뜀 (idempotent). 기존 데이터 삭제 없음.

#### gbrain 지식 베이스
gbrain이 설치된 경우 `harness/pitfalls/` + `harness/rules/`를 자동 임포트합니다.

```bash
# gbrain CLI 없으면 먼저 설치
bun install -g gbrain

# 수동 재실행
bash harness/scripts/bootstrap-gbrain.sh
```

### 사전 요구사항
- Node.js 20+
- Git
- [Claude Code CLI](https://docs.claude.com/en/docs/claude-code) (`claude` 명령어)
- (선택) `codex`, `copilot-api`, `ollama` — 인스톨러가 원하면 자동 설치
- (선택) `gbrain` — `bun install -g gbrain` (지식 베이스 셋업 시 필요)

### 재배포 / 업데이트
소스 업데이트 후 같은 명령 재실행:
```bash
cd jamesclew && git pull && bash harness/install.sh --non-interactive
```
`--non-interactive`는 기존 `~/.harness/persona.yaml` 값을 유지하고 rules/hooks만 새로고침합니다.

### 페르소나 수정
`~/.harness/persona.yaml`을 편집한 뒤 인스톨러 재실행하면 CLAUDE.md가 다시 렌더링됩니다. 예시 템플릿은 `harness/persona.yaml.example` 참조.

### 환경변수 로드
**Bash/Zsh**:
```bash
echo 'set -a; source ~/.harness.env; set +a' >> ~/.bashrc
```
**PowerShell (`$PROFILE`)**:
```powershell
Get-Content $HOME\.harness.env | ForEach-Object { if ($_ -match '^([^=]+)=(.*)$') { [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2]) } }
```

### 검증
```bash
claude
> /audit          # 23-항목 세션 감사 리포트
```

## 슬래시 커맨드

| 커맨드 | 용도 |
|-------|------|
| `/prd` | PRD 생성 (제품 레벨 마일스톤) |
| `/pipeline-install` | 11단계 품질 파이프라인 설치 |
| `/pipeline-run` | 파이프라인 실행 + 루프 |
| `/qa` | 외부 모델 사용자 관점 QA |
| `/audit` | 23-항목 세션 감사 |

## 핵심 훅 (Hooks)

| 훅 | 트리거 | 역할 |
|----|-------|------|
| `enforce-execution.sh` | Stop | Ghost Mode "할까요?" 차단 |
| `evidence-first.sh` | Stop | 증거 없는 보고 차단 |
| `enforce-build-transition.sh` | PreToolUse Write/Edit | 빌드 시 PRD/Plan 강제 |
| `verify-deploy.sh` | PreToolUse Bash (deploy) | Step 5/7 증거 없으면 차단 |
| `post-edit-dispatcher.sh` | PostToolUse Write/Edit | 포맷 + 회귀 + 변경 추적 |
| `stop-dispatcher.sh` | Stop | 5개 검증 훅 통합 실행 |

## 개발

```bash
# 하네스 편집 (D:/jamesclew/harness/ 또는 클론 위치)
vim hooks/some-hook.sh

# 로컬 배포 (개발 머신)
bash harness/deploy.sh

# Reload
> /reload-plugins
```

## Anthropic 4축 디자인 평가 (rules/design_rubric.md)

| 축 | 내용 | 통과 |
|---|------|------|
| Consistency | 화면 통일성 | 8/10+ |
| **Originality** | AI 클리셰 탈출 | 8/10+ |
| Polish | Typography/대비/간격 | 8/10+ |
| Functionality | UX 인터랙션 | 8/10+ |

`scripts/evaluator.sh <URL>` 한 번 실행 → expect MCP 스크린샷 + Codex 자동 등급 평가.

## 보안

- 모든 시크릿은 `~/.harness.env`에서만 로드 (저장소에 절대 포함 X)
- `.gitignore`: `harness/keys/`, `.env*`, `*.credentials*`, `.claude/`
- 배포 전 점검: `grep -rE 'sk-|ghp_|BOT_TOKEN' harness/` 결과 0건이어야 함

## 라이선스

Personal use. 출처 표기 시 자유 사용 가능.
