# JamesClaw Agent Harness

자율 실행 에이전트 "JamesClaw"의 하네스 (rules + hooks + commands + scripts).
Anthropic Harness Ablation 연구(2026-04) 기반 Planner-Generator-Evaluator 3-에이전트 구조.

## 핵심 철학

- **Build to Delete**: 모델이 강해지면 하네스 요소 제거 (ablation 기반)
- **Generator ≠ Evaluator**: 자기 검수 편향 차단을 외부 모델 분리로 강제
- **Evidence-First**: 도구 출력 증거 없이 보고 금지 (hook 강제)
- **Ghost Mode**: "할까요?" 금지, 즉시 실행

## 구조

```
harness/
├── CLAUDE.md              # 글로벌 에이전트 규칙 (~57줄)
├── settings.json          # Claude Code 설정 (hooks, MCP, 권한)
├── rules/                 # 상세 규칙 (architecture, quality, security, design_rubric)
├── hooks/                 # PreToolUse / PostToolUse / Stop / SessionStart 훅
├── commands/              # 슬래시 커맨드 (/prd, /pipeline-run, /qa, /audit)
├── scripts/               # 자동화 스크립트 (audit, evaluator, self-evolve)
├── agents/                # 서브에이전트 정의
├── deploy.sh              # 로컬 ~/.claude로 배포
├── install.sh             # 새 머신 1-command 설치
└── .env.example           # 환경변수 템플릿
```

## 새 머신 설치

### 1. 저장소 클론
```bash
git clone <YOUR_REPO_URL> jamesclew
cd jamesclew
```

### 2. 사전 요구사항
- Node.js 20+
- Git
- [Claude Code CLI](https://docs.claude.com/en/docs/claude-code) (`claude` 명령어)
- (선택) `codex`, `gemini` CLI — 외부 모델 검수용; `copilot-api` (GPT-4.1, localhost:4141)

### 3. 인스톨 실행
```bash
bash harness/install.sh
```

### 4. 환경변수 설정
`~/.harness.env` 파일을 열어 API 키 입력:
```bash
PERPLEXITY_API_KEY=pplx-...
TAVILY_API_KEY=tvly-...
OBSIDIAN_VAULT=/path/to/Obsidian-Vault
```

shell rc에 추가:
```bash
# ~/.bashrc, ~/.zshrc, ~/.bash_profile 중 하나
set -a; source ~/.harness.env; set +a
```

### 5. MCP 서버 (필요한 것만)
```bash
claude mcp add perplexity -s user -- npx -y server-perplexity-ask
claude mcp add tavily     -s user -- node ~/.claude/scripts/tavily-rotator.mjs
claude mcp add stitch     -s user -- npx -y @_davideast/stitch-mcp proxy
```

### 6. 검증
```bash
claude
> /audit          # 하네스 감사 실행 → 23개 항목 리포트
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

`scripts/evaluator.sh <URL>` 한 번 실행 → Playwright + Codex 자동 등급 평가.

## 보안

- 모든 시크릿은 `~/.harness.env`에서만 로드 (저장소에 절대 포함 X)
- `.gitignore`: `harness/keys/`, `.env*`, `*.credentials*`, `.claude/`
- 배포 전 점검: `grep -rE 'sk-|ghp_|BOT_TOKEN' harness/` 결과 0건이어야 함

## 라이선스

Personal use. 출처 표기 시 자유 사용 가능.
