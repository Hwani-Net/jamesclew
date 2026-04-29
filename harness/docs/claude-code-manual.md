---
title: Claude Code 공식 매뉴얼 (로컬 신뢰 소스)
type: reference
version: 2.1.123
updated: 2026-04-29
sources:
  - ~/.claude/cache/changelog.md
  - harness/CLAUDE.md (v2.1.112~v2.1.123 섹션)
  - Obsidian-Vault/05-wiki/entities/claude-code-runtime.md
  - harness/docs/hooks/hooks-reference.md
  - harness/docs/skills/skills-reference.md
  - harness/settings.json
known_regressions:
  - "v2.1.120: --resume/--continue CLI 플래그 크래시 (Issue #53086, OPEN). 워크어라운드: 2.1.119 다운그레이드 또는 REPL 내부 /resume 사용. PITFALL: pitfall-067"
---

# Claude Code 공식 매뉴얼 (로컬 신뢰 소스)

> 최종 갱신: 2026-04-29 | Claude Code v2.1.123 기준
> 1차 소스: `~/.claude/cache/changelog.md` / docs.claude.com
> 관리: `bash harness/deploy.sh` 시 옵시디언 자동 미러

---

## 목차

1. [개요 및 런타임 철학](#1-개요-및-런타임-철학)
2. [버전 히스토리 (v2.1.85~123)](#2-버전-히스토리)
3. [핵심 개념](#3-핵심-개념)
4. [명령어 레퍼런스](#4-명령어-레퍼런스)
5. [설정 (settings.json)](#5-설정-settingsjson)
6. [모델 선택](#6-모델-선택)
7. [플랫폼 / 백엔드](#7-플랫폼--백엔드)
8. [보안 / 권한](#8-보안--권한)
9. [Remote Control / Scheduling](#9-remote-control--scheduling)
10. [플러그인 (Plugin 네임스페이스)](#10-플러그인-plugin-네임스페이스)
11. [트러블슈팅 & 알려진 제약](#11-트러블슈팅--알려진-제약)
12. [참고 링크](#12-참고-링크)

---

## 1. 개요 및 런타임 철학

### 1.1 Claude Code란

Claude Code는 Anthropic이 제공하는 CLI 기반 AI 코딩 도구이며, 현재는 **범용 에이전트 런타임 플랫폼**으로 진화하였습니다. 단순한 코딩 도우미를 넘어, 외부 시스템과의 연동, 멀티 에이전트 조율, 자동화 파이프라인 실행을 지원하는 실행 기반(substrate)으로 활용됩니다.

출처: Obsidian-Vault/05-wiki/entities/claude-code-runtime.md (2026-04-13)

### 1.2 런타임으로서의 핵심 역할

| 역할 | 설명 |
|------|------|
| 프로세스 수명 관리 | 외부 디스패처·브리지·스케줄러가 CC 프로세스를 감싸 지속적으로 운영 |
| CLAUDE.md 컨텍스트 주입 | 메모리·정체성·규칙을 시작 시 로드하여 코어 로직 수정 없이 상태 유지 |
| MCP 확장 | `--mcp-config`로 DB·API·플랫폼 도구를 인증 상태로 주입 |
| 서브에이전트 스폰 | 리드 프로세스가 격리된 컨텍스트 창에서 전문 서브에이전트를 스폰 |
| 훅 기반 자동 개입 | 이벤트(도구 실행 전후, 세션 전환 등)마다 사이드카 스크립트 자동 실행 |

### 1.3 컨텍스트 창 특성

| 항목 | 수치 / 설명 |
|------|------------|
| 공칭 컨텍스트 창 | 200K 토큰 |
| 품질 저하 임계 | 147K~152K 토큰 (하드 리밋 전에 품질 하락 시작) |
| 오토 컴팩션 트리거 | 64~75% 사용 시 (요약 방식, 손실 발생 가능) |
| JamesClaw 하네스 compact 정책 | 45%에 옵시디언 저장 후 `/compact` (P-007) |
| 1M 컨텍스트 | Vertex AI / 지원 모델 한정 옵션 (v2.1.92+ `/setup-vertex`) |

### 1.4 에이전트 SDK

2025년 9월 "Claude Code SDK"에서 **Claude Agent SDK**로 명칭 변경되었습니다. Anthropic이 CC를 범용 에이전트 플랫폼으로 공식 인정한 신호입니다.

- TypeScript: `@anthropic-ai/claude-agent-sdk`
- Python: `claude-agent-sdk`

출처: Obsidian-Vault/05-wiki/entities/claude-code-runtime.md

---

## 2. 버전 히스토리

중요 버전을 역순으로 정리합니다. 전체 원문은 `~/.claude/cache/changelog.md` 참조.

### 2.-6 v2.1.123 (2026-04-29)

#### 버그 수정

| 항목 | 내용 |
|------|------|
| **OAuth 401 retry loop 수정** | `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` 설정 사용자에 한해 OAuth 인증 실패 시 401 무한 재시도 루프 발생하던 문제 수정 |

> **하네스 영향**: 없음. `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1`을 사용하지 않는 일반 환경에서는 해당 없음.

---

### 2.-5 v2.1.122 (2026-04-28)

#### 신규 기능

| 항목 | 변경 내용 |
|------|----------|
| `ANTHROPIC_BEDROCK_SERVICE_TIER` env var | Bedrock 서비스 티어 선택 (`default`, `flex`, `priority`). `X-Amzn-Bedrock-Service-Tier` 헤더로 전송 |
| `/resume` PR URL 입력 | GitHub, GitHub Enterprise, GitLab, Bitbucket PR URL을 `/resume` 검색창에 붙여넣으면 해당 PR을 만든 세션 탐색 |
| `/mcp` 중복 서버 힌트 | 수동 추가 서버와 동일 URL의 claude.ai 커넥터가 숨겨진 경우 힌트 표시 |
| MCP 미인증 메시지 개선 | 브라우저 로그인 후에도 미인증 상태인 경우 `/mcp` 메시지 문구 명확화 |

#### 버그 수정

| 항목 | 내용 |
|------|------|
| `/branch` fork 실패 | rewound timeline 포함 세션에서 "tool_use ids were found without tool_result blocks" 에러 수정 |
| `/model` Bedrock ARN effort | Bedrock application inference profile ARN에서 Effort 옵션 미표시 + `output_config.effort` 미전송 수정 |
| Vertex AI / Bedrock 400 에러 | 세션 제목 생성 등 structured-output 요청 시 `invalid_request_error: Extra inputs are not permitted` 수정 |
| Vertex AI count_tokens 400 | 프록시 게이트웨이 환경에서 `count_tokens` 엔드포인트 400 수정 |
| 이미지 사이즈 제한 오류 | 신규 모델에 이미지 전송 시 2576px 대신 올바른 **2000px** 최대값으로 수정 |
| Remote control 상태 redraw | 세션 idle 상태가 초당 2회 redraw → `tmux -CC` 파이프 범람 및 터미널 정지 수정 |
| `!exit` / `!quit` bash 모드 | CLI 전체 종료 대신 shell 명령으로 실행되도록 수정 |
| ToolSearch MCP 누락 | 세션 시작 후 nonblocking 모드로 연결된 MCP 도구가 ToolSearch에서 누락되던 문제 수정 |
| `spinnerTipsOverride.excludeDefault` | 시간 기반 spinner tips 미억제 수정 |

> **하네스 영향**: 이미지 사이즈 수정(2000px)은 블로그 이미지 캡처 파이프라인에 영향 없음 (현재 800x800 사용). ToolSearch MCP 누락 수정은 온디맨드 MCP(Stitch, korean-law 등) 안정성 향상.

---

### 2.-4 v2.1.121 (2026-04-27)

#### 신규 기능 — 하네스 영향 큼

| 항목 | 변경 내용 |
|------|----------|
| **PostToolUse `updatedToolOutput` 전체 도구 지원** | 기존엔 MCP 도구만 지원. 이제 **모든 도구(Read, Bash, Write 등)**의 출력을 `hookSpecificOutput.updatedToolOutput`으로 교체 가능 |
| **MCP `alwaysLoad` 옵션** | `mcpServers` 설정에 `"alwaysLoad": true` 추가 시 해당 서버의 도구가 ToolSearch 지연 없이 항상 즉시 사용 가능 |
| **MCP transient 에러 자동 재시도** | 서버 시작 시 transient 에러 발생 시 연결 끊김 대신 최대 3회 자동 재시도 |
| **`--dangerously-skip-permissions` 화이트리스트 확장** | `.claude/skills/`, `.claude/agents/`, `.claude/commands/` 쓰기는 더 이상 승인 프롬프트 없이 허용 |
| `claude plugin prune` 신규 | 고아 플러그인 의존성 제거. `plugin uninstall --prune`은 cascade 삭제 |
| `/skills` 검색 필터 | 긴 목록에서 type-to-filter 검색 박스로 빠른 skill 탐색 |

#### UI / 안정성

| 항목 | 변경 내용 |
|------|----------|
| Fullscreen 스크롤 유지 | 프롬프트 입력 시 스크롤이 바닥으로 튕기던 문제 수정 |
| 다이얼로그 스크롤 | 터미널 넘치는 다이얼로그를 방향키/PgUp·PgDn/Home·End/마우스 휠로 스크롤 가능 |
| Fullscreen URL 클릭 | 줄 넘침된 긴 URL의 아무 줄 클릭 시 전체 URL 열기 |
| 세션 탭 제목 언어 | `language` 설정에 따라 터미널 탭 제목 언어 생성 |
| claude.ai 커넥터 중복 제거 | 동일 upstream URL 커넥터 중복 표시 수정 |

#### 버그 수정

| 항목 | 내용 |
|------|------|
| 이미지 메모리 누수 | 이미지 다수 처리 시 수 GB RSS 무한 증가 수정 |
| `/usage` 메모리 누수 | 대용량 트랜스크립트 히스토리에서 ~2GB 누수 수정 |
| Bash tool 영구 사용 불가 | 시작 디렉토리 삭제·이동 시 Bash tool이 영구적으로 사용 불가해지던 버그 수정 |
| `--resume` 크래시 | 외부 빌드에서 startup 크래시 수정 (v2.1.120 회귀 해결) |
| 트랜스크립트 라인 손상 대응 | 비정상 종료로 인한 손상 라인 건너뛰기 |
| Microsoft 365 MCP OAuth | duplicate `prompt` 파라미터 오류 수정 |
| tmux/Windows Terminal 스크롤백 중복 | Ctrl+L 또는 redraw 시 중복 표시 수정 |
| claude.ai MCP 커넥터 사라짐 | 시작 시 transient auth 에러로 커넥터 묵시적 소멸 수정 |
| managed settings 승인 | 승인 시 세션 종료되던 문제 → 설정 적용 후 계속 |
| `/usage` 속도 제한 | stale OAuth 토큰 → "rate limited" 대신 자동 갱신 |
| settings.json 레거시 enum | 잘못된 레거시 값으로 전체 설정 파일 무효화되던 문제 수정 |

> **하네스 영향 분석 (v2.1.121)**:
>
> 1. **PostToolUse `updatedToolOutput` 전체 도구 지원**: 기존 하네스 hook은 MCP 출력만 교체 가능했으나, 이제 Read/Bash/Write 등 내장 도구 출력도 교체 가능. `post-edit-dispatcher.sh`에서 응용 가능 (예: Bash 출력 필터링, 민감 정보 마스킹). 현행 hook 동작에는 영향 없음.
> 2. **`alwaysLoad`**: `settings.json`의 고정 사용 MCP(gbrain, telegram 등)에 `"alwaysLoad": true` 추가 시 Tool Budget 절감 가능. ToolSearch 우회로 응답 속도도 향상.
> 3. **`--dangerously-skip-permissions` 확장**: `.claude/skills/`, `.claude/agents/`, `.claude/commands/` 쓰기가 승인 없이 허용됨. `bash-tool-blocker.sh`는 독립 동작 유지 (P-026).
> 4. **`--resume` 크래시 수정**: v2.1.120 회귀(PITFALL pitfall-067) 해결. v2.1.119 다운그레이드 불필요.

---

### 2.-3 v2.1.120 (2026-04-24)

#### ⚠️ 알려진 회귀 (반드시 확인)

| 항목 | 내용 |
|------|------|
| `--resume` / `--continue` CLI 플래그 크래시 | `FKH/g9H is not a function` 에러로 즉시 종료. v2.1.119 까지 정상. [Issue #53086 OPEN](https://github.com/anthropics/claude-code/issues/53086). PITFALL: `pitfall-067-claude-code-2120-resume-fkh-undefined` |
| 워크어라운드 1 | `npm i -g @anthropic-ai/claude-code@2.1.119` (다운그레이드) |
| 워크어라운드 2 | `claude --new` → REPL 내부에서 `/resume <session-id>` (다른 코드 경로 → 정상) |
| ✅ **v2.1.121에서 수정 완료** | `--resume` 외부 빌드 startup 크래시 수정. v2.1.121+ 업그레이드로 해결 |

#### Windows / Shell

| 항목 | 변경 내용 |
|------|----------|
| **Git for Windows(Git Bash) 더 이상 필수 아님** | 부재 시 PowerShell 툴로 자동 폴백. Windows 신규 설치 진입장벽 제거 |

#### CI / 자동화

| 항목 | 변경 내용 |
|------|----------|
| `claude ultrareview [target]` 비대화형 | CI/스크립트에서 `/ultrareview` 실행. `--json` raw output, exit 0 성공 / 1 실패 |
| `AI_AGENT` env var 자동 주입 | 서브프로세스에서 `gh` 등이 Claude Code 트래픽 식별 가능 |

#### Skills / 기타

| 항목 | 변경 내용 |
|------|----------|
| `${CLAUDE_EFFORT}` skill 변수 | skill 본문에서 현재 effort level 참조 |
| Auto-compact in auto mode | misleading token value 대신 `auto` (소문자) 표시 |
| 데스크톱앱/skills 보유 시 추천 spinner tip 숨김 | UI 깔끔 |

#### 주요 버그 수정

- `claude --resume` 후 `/rewind` 등 인터랙티브 오버레이가 키 입력을 받지 못하던 문제
- 비-fullscreen 모드에서 터미널 스크롤백 중복 (resize, dialog dismiss, 긴 세션)
- Esc 키가 stdio MCP tool call 중 전체 서버 연결 닫던 문제 (v2.1.105 회귀)
- `DISABLE_TELEMETRY` / `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` 가 API/엔터프라이즈 사용량 메트릭 텔레메트리 차단 못 하던 문제
- auto mode multi-line bash 명령(파이프+리다이렉트)에서 "Dangerous rm" 오탐
- fullscreen 긴 선택 메뉴 클리핑
- fullscreen Write 도구 출력 "+N lines" 클릭 시 펼침이 아닌 접힘
- slash command picker 깜빡임 + 하이라이트가 contiguous substring 만 매칭
- `/plugin` marketplace 한 항목이 인식 못 하는 source format 사용 시 전체 로드 실패
- VSCode `/usage` 가 plain-text session cost 대신 native Account & Usage dialog 열음
- VSCode 음성 받아쓰기가 `~/.claude/settings.json` `language` 설정 존중
- `find` 도구가 큰 디렉토리 트리에서 fd 고갈 → 호스트 다운시키던 문제 (macOS/Linux 네이티브)
- `claude plugin validate` 가 `marketplace.json` 최상위 `$schema`/`version`/`description`, `plugin.json` `$schema` 허용

---

### 2.-2 v2.1.119 (2026-04-23)

#### 설정 / CLI

| 항목 | 변경 내용 |
|------|----------|
| `/config` 설정 persist | theme, editor mode, verbose 등이 `~/.claude/settings.json` 에 저장 + project/local/policy override precedence 참여 |
| `prUrlTemplate` 설정 | footer PR badge 가 github.com 대신 커스텀 코드 리뷰 URL 가리킴 |
| `CLAUDE_CODE_HIDE_CWD` env var | 시작 로고에서 작업 디렉토리 숨김 |
| `--from-pr` 확장 | GitLab merge-request, Bitbucket pull-request, GitHub Enterprise PR URL 지원 |
| `--print` 모드 | 에이전트의 `tools:` / `disallowedTools:` frontmatter 존중 (interactive 와 동일) |
| `--agent <name>` | 빌트인 에이전트의 `permissionMode` 존중 |
| PowerShell 명령 auto-approve | permission mode 에서 Bash 와 동일하게 자동 승인 |

#### Hooks / SDK

| 항목 | 변경 내용 |
|------|----------|
| `PostToolUse` / `PostToolUseFailure` 입력 | `duration_ms` 필드 추가 (도구 실행 시간, permission prompt 와 PreToolUse hook 제외) |
| Subagent / SDK MCP 서버 재구성 | 직렬 → 병렬 연결 |
| Plugins | 다른 plugin 의 version 제약으로 pin 된 경우 가장 높은 만족 git tag 로 자동 업데이트 |

#### 주요 버그 수정

- Vim mode INSERT 의 Esc 가 큐된 메시지 입력으로 끌어오던 문제 (한 번 더 누르면 인터럽트)
- CRLF 붙여넣기 (Windows 클립보드, Xcode 콘솔) 가 줄마다 빈 줄 삽입하던 문제
- kitty keyboard protocol bracketed paste 에서 multi-line paste 가 newline 잃던 문제
- Bash 가 permissions 로 거부됐을 때 macOS/Linux 네이티브에서 Glob/Grep 도구가 사라지던 문제
- fullscreen 에서 도구 완료 시마다 스크롤이 바닥으로 튕기던 문제
- MCP HTTP 연결이 OAuth discovery 비-JSON 응답에 "Invalid OAuth error response" 로 실패
- Rewind 오버레이 가 이미지 첨부 메시지를 "(no prompt)" 로 표시
- auto mode 가 plan mode 를 "Execute immediately" 지시로 덮어쓰던 문제
- 응답 페이로드 없는 async `PostToolUse` 훅이 세션 트랜스크립트에 빈 항목 쓰던 문제
- subagent task notification 이 큐에 고아로 남으면 spinner 가 계속 돌던 문제
- Vertex AI 에서 ToolSearch 가 unsupported beta header 에러로 실패 → 기본 비활성 (`ENABLE_TOOL_SEARCH` 로 opt-in)
- `@`-file Tab 보완이 슬래시 커맨드 + 절대 경로 안에서 전체 prompt 를 교체하던 문제
- macOS Terminal.app 에서 Docker/SSH 시작 시 prompt 에 stray `p` 문자 나타나던 문제
- HTTP/SSE/WebSocket MCP 서버 `headers` 의 `${ENV_VAR}` placeholder 가 요청 전에 치환되지 않던 문제
- `--client-secret` 으로 저장된 MCP OAuth client secret 이 `client_secret_post` 요구 서버에 토큰 교환 시 전송 안 되던 문제
- `/skills` Enter 가 다이얼로그 닫고 prompt 에 `/<skill-name>` 자동 입력 안 하던 문제
- `/agents` 상세 뷰에서 subagent 에 사용 불가능한 빌트인 도구를 "Unrecognized" 로 잘못 라벨링
- 플러그인의 MCP 서버가 plugin cache 불완전 시 Windows 에서 spawn 안 되던 문제
- `/export` 가 실제 사용된 모델 대신 현재 default model 표시
- verbose output 설정이 재시작 후 persist 안 되던 문제
- `/usage` progress bar 가 "Resets …" 라벨과 겹치던 문제
- 플러그인 MCP 서버가 `${user_config.*}` 가 optional field 빈 값일 때 실패
- 마지막에 숫자 있는 list item 이 숫자를 자기 줄로 wrap 하던 문제
- `/plan` 과 `/plan open` 이 plan mode 진입 시 기존 plan 에 작용하지 않던 문제
- auto-compaction 직전 호출된 skill 이 다음 user message 에 재실행되던 문제
- `/reload-plugins` 와 `/doctor` 가 비활성 플러그인의 로드 에러 보고
- `Agent` 도구 `isolation: "worktree"` 가 이전 세션의 stale worktree 재사용
- 비활성 MCP 서버가 `/status` 에 "failed" 로 표시
- `gh` 출력에 "rate limit" 언급한 PR 제목 포함 시 spurious "GitHub API rate limit exceeded" 힌트
- SDK/bridge `read_file` 이 자라는 파일에 size cap 정확히 적용 안 하던 문제
- git worktree 작업 시 PR 이 세션에 링크 안 되던 문제
- `/doctor` 가 더 높은 우선순위 scope 에 의해 override 된 MCP 서버 항목 경고
- Windows: false-positive "Windows requires 'cmd /c' wrapper" MCP config 경고 제거
- VSCode: macOS 마이크 권한 prompt 표시 중 음성 받아쓰기 첫 녹음이 아무것도 생성 안 하던 문제

---

### 2.-1 v2.1.118 (2026-04-23)

#### Hook에서 MCP 도구 직접 호출 (하네스 큰 영향)

| 항목 | 변경 내용 |
|------|----------|
| Hook `type: "mcp_tool"` | bash subprocess 없이 MCP 도구 직접 호출 가능 |

> **활용 후보**: `telegram-notify.sh` → `mcp__plugin_telegram_telegram__reply` 직접 호출, pitfall 저장 → `mcp__gbrain__put_page` 직접 호출. 환경변수 보간 지원 여부 확인 필요 (v2.1.63 HTTP hook과 동일 제약 가능성).

#### 명령어 통합 / UI

| 항목 | 변경 내용 |
|------|----------|
| `/cost` + `/stats` → `/usage` | 통합. 구 명령은 typing shortcut으로 유지 (관련 탭 열림) |
| Named custom themes | `/theme`에서 생성·전환. `~/.claude/themes/` JSON. 플러그인이 `themes/` 디렉토리로 배포 가능 |
| Vim visual mode | `v` (character), `V` (line) + operators + 시각 피드백 |
| `/color` Remote Control 동기화 | accent color를 claude.ai/code와 동기화 |

#### Hook / 권한 / 업데이트

| 항목 | 변경 내용 |
|------|----------|
| `DISABLE_UPDATES` env | 수동 `claude update` 포함 모든 업데이트 경로 차단. 기존 `DISABLE_AUTOUPDATER`보다 강함 |
| Auto mode `"$defaults"` | `autoMode.allow/soft_deny/environment`에 포함 시 built-in 규칙 덮어쓰지 않고 병합 |
| "Don't ask again" | auto mode opt-in 프롬프트에 옵션 추가 |

#### 플러그인

| 항목 | 변경 내용 |
|------|----------|
| `claude plugin tag` | 플러그인용 release git tag 생성 + 버전 검증 |

#### 세션 / 모델

| 항목 | 변경 내용 |
|------|----------|
| `--continue` / `--resume` 범위 확장 | `/add-dir`로 추가된 디렉토리 세션도 찾음 |
| `/model` picker + custom base URL | `ANTHROPIC_DEFAULT_*_MODEL_NAME/_DESCRIPTION` override 지원 (copilot-api/HydraTeams 게이트웨이 모델 라벨 커스터마이징) |
| WSL managed settings 상속 | `wslInheritsWindowsSettings` 정책 키로 Windows-side managed settings 상속 |

#### 주요 버그 수정

| 영역 | 변경 내용 |
|------|----------|
| MCP OAuth | 토큰 만료 감지, `expires_in` 누락 처리, step-up scope 403, refresh race, macOS keychain race, revoked token 6건 수정 |
| `/login` + env token | `CLAUDE_CODE_OAUTH_TOKEN` 만료 시 env 클리어 후 disk credentials 사용 |
| `--dangerously-skip-permissions` | plan acceptance 대화상자에 "auto mode" 대신 "bypass permissions" 표시 |
| Agent-type hooks | Stop/SubagentStop 외 이벤트에서 "Messages are required for agent hooks" 에러 수정 |
| `prompt` hooks | agent-hook verifier 서브에이전트 도구 호출에 재발동하던 문제 수정 |
| `/fork` | 부모 대화 전체 디스크 쓰기 → pointer + hydrate-on-read |
| Remote Control | 세션이 `~/.claude/settings.json`의 `model` 설정 덮어쓰던 문제 수정 |
| 서브에이전트 `SendMessage` resume | explicit `cwd` 복원 안 되던 버그 수정 |

---

### 2.0 v2.1.117 (2026-04-22)

#### 중대 수정 — Opus 4.7 컨텍스트 계산 버그

| 항목 | 변경 내용 |
|------|----------|
| Opus 4.7 `/context` 수치 | 기존 200K 기준 계산 → 네이티브 1M 기준으로 수정. autocompact 조기 발동 해결 |

> **하네스 영향**: "Opus 세션 45% compact" 규칙의 실효 공간이 실제로 여유 있음. `telegram-notify.sh heartbeat` 수치 재검증 필요.

#### 기본 설정 변경

| 항목 | 변경 내용 |
|------|----------|
| 기본 effort | Pro/Max 구독자 + Opus 4.6/Sonnet 4.6: `medium` → `high` |

> 하네스 정책(effortLevel 고정 금지)과 정합. settings.json 변경 불필요.

#### 신규 기능

| 항목 | 변경 내용 |
|------|----------|
| Agent frontmatter `mcpServers` main-thread | `--agent` 플래그 실행 시 `agents/*.md`의 `mcpServers`도 로드 (v2.1.116 `hooks:` 확장 후속) |
| `/model` 영구 지속 | 재시작 시 유지. 프로젝트 pin과 불일치 시 startup header 표시 |
| `/resume` summarize 옵션 | 대용량 세션 재읽기 전 선택적 요약 |
| MCP 병렬 연결 | 로컬 + claude.ai MCP 동시 구성 시 startup 가속 (기본 활성) |
| `cleanupPeriodDays` 커버리지 | `~/.claude/tasks/`, `shell-snapshots/`, `backups/` 포함 |
| Windows `where.exe` 캐싱 | 서브프로세스 launch 속도 ↑ |
| OpenTelemetry 확장 | `user_prompt`에 `command_name`/`command_source`, 비용/토큰 이벤트에 `effort` attribute. 커스텀·MCP 커맨드명은 `OTEL_LOG_TOOL_DETAILS=1` 없으면 redact |
| Forked subagents (실험) | `CLAUDE_CODE_FORK_SUBAGENT=1` 외부 빌드에서 활성 가능 |
| Plugin 관리 개선 | 이미 설치된 plugin에 `plugin install` 시 누락 의존성 설치. `blockedMarketplaces`/`strictKnownMarketplaces` managed-settings 강제 |
| Advisor Tool | "experimental" 라벨, learn-more 링크, startup notification. "Advisor tool result content could not be processed" 스턱 버그 해결 |

#### 플랫폼 / 빌드

| 항목 | 변경 내용 |
|------|----------|
| 네이티브 빌드 Glob/Grep 교체 (macOS/Linux만) | embedded `bfs`/`ugrep`으로 Bash 경유 실행. **Windows/npm 빌드는 기존 Glob/Grep 유지** |

#### 주요 버그 수정

| 항목 | 변경 내용 |
|------|----------|
| `WebFetch` 대용량 HTML hang | pre-truncation으로 HTML→Markdown 변환 전 입력 truncate |
| 서브에이전트 file read malware 오판정 | 다른 모델 운용 시 발생하던 오판정 수정 |
| Plain-CLI OAuth 401 | 토큰 만료 시 reactive refresh (기존엔 `/login` 요구로 세션 사망) |
| Bedrock application-inference-profile | Opus 4.7 + thinking disabled 조합에서 400 에러 수정 |
| Proxy HTTP 204 `TypeError` | clear error 메시지로 surface |
| Prompt input undo (`Ctrl+_`) | 타이핑 직후 동작 안 되던 문제 + undo step 스킵 수정 |
| Bun 환경 `NO_PROXY` | remote API 요청 시 존중 안 되던 문제 수정 |
| SDK `reload_plugins` | MCP 서버 직렬 재연결 → 병렬 |
| MCP `elicitation/create` auto-cancel | print/SDK 모드에서 mid-turn 연결 완료 시 auto-cancel되던 버그 수정 |

---

### 2.1 v2.1.116 (2026-04-21)

#### 성능 개선

| 항목 | 변경 내용 |
|------|----------|
| `/resume` 속도 | 40MB+ 세션에서 최대 67% 가속. dead-fork 처리 개선 |
| MCP 시작 가속 | stdio 서버 다수 시 `resources/templates/list`를 `@`-mention 전까지 지연 로드 |
| 풀스크린 스크롤 | VS Code / Cursor / Windsurf에서 `/terminal-setup`이 스크롤 감도 조정 |

#### 신규 기능

| 항목 | 변경 내용 |
|------|----------|
| Agent frontmatter `hooks:` main-thread 동작 | `--agent` 플래그 실행 시 `agents/*.md`의 `hooks:` 필드가 작동. 기존엔 subagent에서만 발동 |
| Settings Usage 탭 rate-limit 내성 | 5H/7D 사용량 수치를 endpoint 429 시에도 즉시 표시 |
| Bash gh rate-limit 힌트 | `gh` 명령이 GitHub API rate limit 도달 시 Claude에게 back-off 힌트 제공 |
| `/doctor` 실행 중 가능 | 현재 turn 완료 대기 없이 즉시 실행 |
| `/config` 검색 값 매칭 | 예: "vim" 검색 시 Editor mode 설정 발견 |
| Thinking 스피너 inline | "still thinking", "thinking more", "almost done thinking" 진행 표시 |
| `/reload-plugins` 자동 의존성 설치 | 마켓플레이스 등록 플러그인 누락 의존성 자동 설치 |

#### 보안

- sandbox auto-allow에서 `rm`/`rmdir`의 위험 경로(`/`, `$HOME`) 차단 강화
- `harness/hooks/irreversible-alert.sh`와 중복 없이 두 레이어 병행 동작

#### 버그 수정 (주요)

- `/branch` 50MB+ 트랜스크립트 거부 문제 수정
- `/resume` 대형 세션에서 빈 대화 표시 오류 수정
- API 400 오류 (cache control TTL 순서 관련) 수정

**하네스 영향**: CLAUDE.md / hooks / commands 변경 없음. `agents/*.md`에 `hooks:` 추가 가능해짐.

---

### 2.2 v2.1.113~v2.1.114 (2026-04-18)

#### 네이티브 바이너리 전환 (v2.1.113)

CLI가 번들 JavaScript 대신 **플랫폼별 네이티브 바이너리**를 spawn합니다. 사용자는 기존과 동일하게 `claude` 실행. 내부 시작 속도 개선.

#### Agent Teams 안정화

| 항목 | 변경 내용 |
|------|----------|
| Subagent stall 자동 실패 (v2.1.113) | 10분간 stream 없이 stall 시 clear error로 실패. 기존엔 silent hang |
| Permission dialog crash fix (v2.1.114) | teammate가 도구 권한 요청 시 발생하던 crash 해결 |

하네스의 R14 watchdog (5분 wake, 10분 re-spawn)와 중복 없이 상호 보완합니다.

#### 보안 강화 (v2.1.113)

| 항목 | 변경 내용 |
|------|----------|
| deny rules 확장 매칭 | `env`, `sudo`, `watch`, `ionice`, `setsid` 등 exec wrapper로 감싸도 deny rule 적용 |
| `Bash(find:*)` 자동 승인 제외 | `find -exec`, `-delete`는 이제 자동 승인 안 됨 |
| macOS 위험 경로 | `/private/{etc,var,tmp,home}` — `rm:*` allow rule 있어도 dangerous target으로 분류 |
| `dangerouslyDisableSandbox` 강제 프롬프트 | sandbox 비활성 시 반드시 승인 필요 |
| `sandbox.network.deniedDomains` 신규 | 특정 도메인만 차단 가능 (allowedDomains 와일드카드 아래에서도 적용) |

#### 권한 완화 (v2.1.113)

- `cd <current-directory> && git …` no-op cd → permission prompt 없이 즉시 실행
- Multi-line Bash 첫 줄이 주석이어도 transcript에 전체 명령 표시

---

### 2.3 v2.1.111~v2.1.112 (2026-04-17)

#### 신규 슬래시 커맨드

| 커맨드 | 기능 | 과금 |
|--------|------|------|
| `/less-permission-prompts` | 트랜스크립트 스캔 → read-only bash/MCP 커맨드 allowlist 자동 제안 | 무료 |
| `/ultrareview` | 클라우드 병렬 멀티에이전트 PR 리뷰. 인자 없으면 현재 브랜치, `<PR#>` 시 GitHub PR fetch | 체험 3회 후 유료 |

#### Effort Level (v2.1.111)

| 레벨 | 설명 | 대상 |
|------|------|------|
| `low` | 최소 사고 | 모든 모델 |
| `medium` | 기본 (구 기본값) | 모든 모델 |
| `high` | 향상된 추론 (v2.1.94부터 기본값) | 모든 모델 |
| `xhigh` | high와 max 사이 신규 레벨 | Opus 4.7 전용. 타 모델은 high로 fallback |
| `max` | 최대 사고 | Opus 4.7 |

- `/effort` 인자 없이 호출 시 interactive slider 열림 (화살표 키 탐색 + Enter 확인)
- Auto mode: Max 구독자에게 Opus 4.7 + xhigh 자동 적용. `--enable-auto-mode` 플래그 제거됨

#### 권한 완화 (v2.1.111~112)

- read-only bash glob 패턴 (`ls *.ts`) + `cd <project-dir> &&` 형태 → permission prompt 없이 즉시 실행
- 하네스 `bash-tool-blocker.sh`는 여전히 독립 동작 (P-026 유효)

#### Windows PowerShell Tool (v2.1.111, 점진 롤아웃)

- `CLAUDE_CODE_USE_POWERSHELL_TOOL=1` 환경변수로 opt-in/out
- Linux/macOS에서도 `pwsh`가 PATH에 있으면 `=1`로 활성화
- bash hook은 여전히 bash 경유

#### UI 개선 (v2.1.111~112)

| 단축키/기능 | 설명 |
|------------|------|
| `Ctrl+U` | 전체 input 버퍼 클리어 (구: 커서 앞까지 삭제) |
| `Ctrl+Y` | 클리어한 input 복원 |
| `Ctrl+L` | 전체 화면 강제 재그리기 |
| `[` (트랜스크립트 뷰) | scrollback dump |
| `v` (트랜스크립트 뷰) | editor 열기 |
| `/skills` | `t` 토글로 토큰 수 기준 정렬 |
| Plan 파일명 | 프롬프트 기반 자동 생성 (`fix-auth-race-snug-otter.md`) |
| LSP diagnostics | 편집 직전 진단이 후에 나타나 모델 오판하던 버그 수정 |

---

### 2.4 v2.1.110

| 항목 | 변경 내용 |
|------|----------|
| `/tui` 커맨드 | `fullscreen` 모드 전환. `tui` settings 키로도 설정 |
| push notification | Remote Control + "Push when Claude decides" 활성 시 Claude가 모바일 푸시 발송 |
| `autoScrollEnabled` | fullscreen 모드에서 자동 스크롤 비활성화 옵션 |
| `--resume`/`--continue` | 만료 안 된 scheduled task 재활성화 |
| `Ctrl+O` | focus view 토글 (이전: verbose transcript 포함. v2.1.110부터 focus 전용) |
| Write tool | IDE diff에서 제안 내용 편집 후 accept 시 모델에게 알림 |

---

### 2.5 v2.1.108~v2.1.109

| 항목 | 변경 내용 |
|------|----------|
| `ENABLE_PROMPT_CACHING_1H` | 1시간 prompt cache TTL opt-in. `FORCE_PROMPT_CACHING_5M`으로 5분 강제 |
| `/recap` | 세션 복귀 시 요약 제공. `/config`에서 설정, `CLAUDE_CODE_ENABLE_AWAY_SUMMARY`로 강제 |
| `/undo` | `/rewind` 별칭 |
| extended-thinking 인디케이터 | 회전 진행 힌트 표시 (v2.1.109) |
| `/team-onboarding` (v2.1.101) | 로컬 Claude Code 사용 기록 기반 팀원 온보딩 가이드 생성 |

---

### 2.6 v2.1.105

| 항목 | 변경 내용 |
|------|----------|
| `EnterWorktree` path 파라미터 | 기존 worktree로 재진입 가능 (`path: "existing/worktree"`) |
| PreCompact hook 지원 | `exit 2` 또는 `{"decision":"block"}` 반환으로 compact 차단 가능 |
| `/proactive` | `/loop` 별칭 |
| stall 처리 개선 | 5분 무데이터 스트림 abort → 비스트리밍 재시도 |
| `/doctor` | `f` 키로 Claude가 이슈 자동 수정 |
| 서브에이전트 MCP 도구 상속 | 동적 추가된 MCP 도구도 서브에이전트에 자동 상속 |

---

### 2.7 v2.1.101

| 항목 | 변경 내용 |
|------|----------|
| OS CA 인증서 자동 신뢰 | 기업 TLS 프록시 추가 설정 없이 동작 (`CLAUDE_CODE_CERT_STORE=bundled`로 번들만 사용) |
| `/ultraplan` 자동 환경 생성 | 별도 웹 설정 없이 클라우드 환경 자동 생성 |
| 서브에이전트 MCP 상속 | `Agent(model: "sonnet")` 호출 시 동적 MCP 도구 자동 상속 (v2.1.101+) |

---

### 2.8 v2.1.98

| 항목 | 변경 내용 |
|------|----------|
| Monitor tool | 백그라운드 스크립트의 stdout 스트리밍 감시 |
| `/setup-vertex` 개선 | 실제 settings.json 경로 표시, 1M context 옵션 |
| `CLAUDE_CODE_PERFORCE_MODE` | Perforce 환경에서 read-only 파일 쓰기 시 `p4 edit` 힌트 |
| Bash 보안 강화 | 백슬래시 이스케이프 플래그 bypass 수정, 복합 명령 강제 프롬프트 수정 |

---

### 2.9 v2.1.94

| 항목 | 변경 내용 |
|------|----------|
| 기본 effort 레벨 변경 | medium → **high** (API key, Bedrock/Vertex/Foundry, Team, Enterprise 사용자) |
| `hookSpecificOutput.sessionTitle` | `UserPromptSubmit` hook에서 세션 제목 설정 가능 |
| Amazon Bedrock Mantle 지원 | `CLAUDE_CODE_USE_MANTLE=1` |

---

### 2.10 v2.1.92

| 항목 | 변경 내용 |
|------|----------|
| Vertex AI setup wizard | 로그인 화면에서 GCP 인증·프로젝트·리전 설정 대화형 안내 |
| `/cost` 개선 | 구독 사용자용 모델별·캐시 히트별 세분화 표시 |
| `forceRemoteSettingsRefresh` | 원격 설정 갱신 실패 시 시작 차단 (fail-closed) |

---

### 2.11 v2.1.91

| 항목 | 변경 내용 |
|------|----------|
| MCP tool result 크기 override | `_meta["anthropic/maxResultSizeChars"]` (최대 500K)로 DB 스키마 등 대용량 결과 통과 |
| `disableSkillShellExecution` | 스킬·슬래시 커맨드·플러그인의 인라인 쉘 실행 비활성화 |

---

### 2.12 v2.1.90

| 항목 | 변경 내용 |
|------|----------|
| `/powerup` | Claude Code 기능 interactive 학습 (애니메이션 데모 포함) |
| `.husky` 보호 디렉토리 | acceptEdits 모드에서 보호 |
| `CLAUDE_CODE_PLUGIN_KEEP_MARKETPLACE_ON_FAILURE` | git pull 실패 시 기존 마켓플레이스 캐시 유지 |

---

### 2.13 v2.1.89

| 항목 | 변경 내용 |
|------|----------|
| `defer` permission decision | `PreToolUse` hook에서 `"permissionDecision": "defer"` 반환 → 실행 일시정지 + 사용자 확인 요청 |
| `CLAUDE_CODE_NO_FLICKER=1` | flicker-free alt-screen 렌더링 + 가상 scrollback (opt-in) |
| `PermissionDenied` hook | auto mode classifier 거부 후 발동. `{retry: true}` 반환 시 재시도 허용 |
| autocompact thrash 루프 차단 | 3회 연속 compact 직후 컨텍스트 리필 감지 시 API 소비 방지 |

하네스 `irreversible-alert.sh`는 이 `defer` 결정을 활용합니다. v2.1.89+ 기능.

---

### 2.14 v2.1.85

| 항목 | 변경 내용 |
|------|----------|
| hook `if` 조건 필드 | permission rule 문법으로 hook 실행 조건 필터링 (`Bash(git *)`) |
| hook 출력 50K+ 차단 | 50K 초과 hook 출력을 디스크에 저장 후 경로+미리보기만 컨텍스트에 주입 |
| PreToolUse `AskUserQuestion` 응답 | `updatedInput` + `permissionDecision: "allow"` 반환으로 headless에서 질문 응답 가능 |

---

## 3. 핵심 개념

### 3.1 CLAUDE.md — 컨텍스트 주입

CLAUDE.md는 Claude Code 시작 시 자동 로드되는 규칙·정체성·메모리 파일입니다. 계층 구조는 다음과 같습니다.

| 우선순위 | 경로 | 적용 범위 |
|---------|------|----------|
| 1 (최고) | `{프로젝트루트}/CLAUDE.md` | 해당 프로젝트 전용 |
| 2 | `~/.claude/CLAUDE.md` (글로벌) | 모든 프로젝트 공통 |
| 3 | `~/.claude/rules/*.md` | 글로벌에서 include됨 |

**JamesClaw 하네스 위치**: `D:/jamesclew/harness/CLAUDE.md` 편집 → `bash harness/deploy.sh`로 `~/.claude/CLAUDE.md`에 배포.

CLAUDE.md 변경 감지는 `InstructionsLoaded` 훅이 MD5를 비교하여 자동 알림을 주입합니다.

**sections.json (v2.1.85+)**: 조건부 스킬·규칙 로드 지원. `if` 필드로 특정 상황에서만 섹션 활성화 가능.

---

### 3.2 Hooks — 이벤트 게이트

훅은 Claude Code 이벤트 발생 시 자동 실행되는 사이드카 스크립트입니다. 세 가지 동작 방식이 있습니다.

| 동작 방식 | 트리거 | 구현 |
|----------|--------|------|
| 경고 주입 | stdout에 JSON `{"systemMessage": "..."}` 출력 | 에이전트가 다음 턴에 인지 |
| 강제 차단 | `exit 2` 반환 | 도구 실행 완전 차단 |
| defer 결정 | `{"permissionDecision": "defer"}` 반환 (v2.1.89+) | 실행 일시정지, 사용자 확인 요청 |

**지원 이벤트 (13종)**

| 이벤트 | 실행 시점 |
|--------|----------|
| `PreToolUse` | 도구 실행 직전 |
| `PostToolUse` | 도구 실행 직후 |
| `SubagentStop` | 서브에이전트 종료 |
| `UserPromptSubmit` | 사용자 메시지 수신 |
| `PreCompact` | compact 직전 |
| `PostCompact` | compact 직후 |
| `Stop` | 에이전트 응답 완료 |
| `StopFailure` | 에이전트 실패 종료 |
| `SessionStart` | 세션 시작 |
| `InstructionsLoaded` | CLAUDE.md 로드 완료 |
| `ConfigChange` | settings.json 변경 |
| `WorktreeCreate` | worktree 생성 |
| `WorktreeRemove` | worktree 제거 |

**settings.json hook 구문**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/example.sh",
            "if": "Bash(git commit *)",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `matcher` | string (regex) | 대상 도구명 패턴. `Write\|Edit`, `mcp__tavily__.*` 등 |
| `type` | `"command"` / `"http"` | 실행 방식. http는 v2.1.63+, 환경변수 보간 미지원 |
| `command` | string | 실행할 bash 명령 |
| `if` | string (permission rule 문법) | 조건 필터 (v2.1.85+). `Bash(git *)` 형식 |
| `timeout` | number (ms) | 훅 최대 실행 시간 |

**Agent frontmatter `hooks:` (v2.1.116+)**

`harness/agents/*.md` 파일에 `hooks:` 필드를 추가하면 `--agent` 플래그로 main-thread 실행 시에도 발동합니다. 기존엔 subagent에서만 동작했습니다.

**JamesClaw 하네스 훅**: 총 41개. 상세는 `harness/docs/hooks/hooks-reference.md` 참조.

---

### 3.3 Slash Commands (Skills) — 재사용 절차

슬래시 커맨드는 복잡한 다단계 작업을 하나의 호출로 실행하는 재사용 절차입니다.

**파일 형식** (`harness/commands/{name}.md`):

```markdown
---
description: "커맨드 설명 (1536자 이내, v2.1.105+)"
argument-hint: "<keyword>"
allowed-tools: ["Bash", "Read", "Write"]
---

## 절차

1. 단계 1
2. 단계 2
```

| 항목 | 설명 |
|------|------|
| 위치 | `~/.claude/commands/` (글로벌) 또는 `.claude/commands/` (프로젝트) |
| 호출 | `/{커맨드명}` 또는 `/{커맨드명} <인자>` |
| description 한도 | 1536자 (v2.1.105+. 초과 시 시작 시 경고) |
| `/skills` 정렬 | 알파벳순 (기본) 또는 `t` 토글로 토큰 수 순 (v2.1.111+) |
| 인라인 쉘 실행 | `disableSkillShellExecution: true`로 비활성화 가능 (v2.1.91+) |

**JamesClaw 하네스 커맨드**: 총 21개. 상세는 `harness/docs/skills/skills-reference.md` 참조.

---

### 3.4 MCP (Model Context Protocol)

MCP는 Claude Code에 외부 도구·데이터소스를 플러그인 방식으로 연결하는 프로토콜입니다.

**등록 방법**

```bash
# 온디맨드 추가 (user scope)
claude mcp add <서버명> -s user -- npx @패키지명/mcp

# 설정 파일 직접 등록 (~/.claude/settings.json의 mcpServers 키)
```

**전송 방식**

| 방식 | 설명 |
|------|------|
| `stdio` | 로컬 프로세스. 다수 시 시작 가속 (v2.1.116) |
| `sse` / `http` | 원격 서버. SSE transport 대용량 프레임 선형 처리 (v2.1.90) |

**비용 고려**

| 도구 | 평균 토큰 | 비고 |
|------|----------|------|
| Tavily search | ~11KB/회 | 도구 결과 중 최대. `max_results=5`, `search_depth="basic"` 기본 사용 |
| Perplexity search | ~$0.006/회 | URL/목록 검색 기본 |
| Perplexity research | ~$0.80/회 | search 대비 133배 비용 |

**도구 수 제한**: 총 50개 이하 유지 권장 (230+에서 서브에이전트 실패 확인, 50~100이 안전 범위).

**MCP concurrent-call timeout fix** (v2.1.113): 한 도구 호출 메시지가 다른 호출 watchdog를 silent disarm하던 버그 해결됨.

---

### 3.5 Agents / Subagents / Agent Teams

**용어 정의**

| 용어 | 도구 | 설명 | 선택 기준 |
|------|------|------|----------|
| 서브에이전트 | `Agent(model: sonnet)` | 1회성 위임. 결과만 반환 | 독립 작업 (코딩, 리서치, 탐색) |
| Agent Teams | `TeamCreate` + `SendMessage` + `TaskList` | 세션 내 지속 팀. teammate끼리 직접 DM | 조율 필요한 협업 (리뷰, 디버깅, 멀티 프로젝트) |
| Managed Agents | Claude API `POST /v1/agents` | 서버 관리 에이전트. 외부 앱용 | 하네스 미사용 |

**Agent Teams (v2.1.107+, 실험적)**

```bash
# Agent Teams 활성화 환경변수
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

| 항목 | 설명 |
|------|------|
| in-process 모드 | tmux 불필요. Windows Terminal에서 바로 동작 |
| teammate 전환 | `Shift+Down` |
| teammate 수 제한 | 없음 (작업 복잡도에 따라 자율 결정) |
| 권장 구성 | Lead(Opus) + 구현(Sonnet teammate) + 검수(GPT-4.1 via HydraTeams) |
| 비용 최적 | `model: sonnet` 명시 필수. 미지정 시 Opus 풀 차감 |

**HydraTeams 프록시** (`harness/tools/HydraTeams/`): Agent Teams teammate를 GPT-4o-mini 등 외부 모델로 라우팅.

```bash
node dist/index.js --model gpt-4o-mini --provider openai --port 3456 --passthrough lead
```

**서브에이전트 stall 자동 실패** (v2.1.113): 10분간 stream 없으면 clear error. silent hang 방지.

**워크트리 격리** (v2.1.105+):

```javascript
Agent({ isolation: "worktree" })         // 신규 worktree 생성
EnterWorktree({ path: "existing/path" }) // 기존 worktree 재진입
```

---

### 3.6 Sessions (SessionStart / Stop / PreCompact / PostCompact)

**세션 생명주기**

```
SessionStart
  → (작업 반복)
  → [컨텍스트 70%+] PreCompact → compact → PostCompact
  → Stop 또는 StopFailure
```

**세션 상태 파일** (`~/.harness-state/`)

| 파일 | 내용 |
|------|------|
| `last_result.txt` | 마지막 작업 결과 요약. Stop hook이 텔레그램 전송 |
| `claude_md_hash` | CLAUDE.md MD5. InstructionsLoaded에서 변경 감지 |
| `config_changes.log` | settings.json 변경 이력 |
| `worktree.log` | worktree 생성/제거 이력 |
| `api_cost_log.jsonl` | API 비용 누적 로그 |
| `session_changes.log` | 세션 내 변경 파일 누적 (change-tracker.sh) |

**`/resume` 개선 이력**

| 버전 | 개선 내용 |
|------|----------|
| v2.1.116 | 40MB+ 세션 최대 67% 가속, dead-fork 처리 개선 |
| v2.1.108 | 현재 디렉토리 세션 기본 표시, `Ctrl+A`로 전체 프로젝트 |
| v2.1.101 | 다수 resume 관련 버그 수정 |

**PreCompact hook 활용** (v2.1.105+)

JamesClaw 하네스의 PreCompact 파이프라인 (5단계 순차 실행):

1. `pre-compact-snapshot.sh` — 옵시디언 세션 저장 (실패 시 exit 2로 compact 차단)
2. `audit-session.sh --compact` — 세션 감사
3. `self-evolve.sh --apply` — 규칙 자동 개선 적용
4. `curation.ts` — 세션 지식 큐레이션 + gbrain 저장
5. `gbrain sync` — 리포 동기화

---

### 3.7 Context Window & Compaction (200K·1M)

**Compaction 동작**

| 항목 | 설명 |
|------|------|
| 트리거 조건 | 컨텍스트 64~75% 사용 시 auto compact |
| 방식 | 대화 내역을 요약으로 압축 (손실 발생 가능) |
| 차단 방법 | PreCompact hook에서 `exit 2` 또는 `{"decision":"block"}` 반환 |
| `DISABLE_COMPACT` | 설정 시 `/compact` 힌트 표시 억제 (v2.1.98+) |
| thrash 방지 | 3회 연속 compact 후 즉시 리필 감지 시 자동 차단 (v2.1.89+) |

**contextCompactionThreshold** (settings.json)

```json
{
  "contextCompactionThreshold": 0.8
}
```

80% 도달 시 자동 compact. JamesClaw 하네스 정책: **45%에 옵시디언 저장 후 수동 `/compact`**.

**`CLAUDE_CODE_MAX_CONTEXT_TOKENS`** (v2.1.98+): `DISABLE_COMPACT`와 연동하여 컨텍스트 상한 직접 지정 가능.

---

## 4. 명령어 레퍼런스

### 4.1 내장 슬래시 커맨드

| 커맨드 | 목적 | 인자 | 도입 버전 |
|--------|------|------|----------|
| `/audit` | 세션 규칙 준수·품질·보안 체크 | — | 하네스 커스텀 |
| `/branch` | 현재 대화를 새 브랜치로 분기 | — | 구버전 |
| `/clear` | 대화 내역 삭제 (컨텍스트 절약) | — | 구버전 |
| `/compact` | 수동 컨텍스트 압축 | — | 구버전 |
| `/config` | 설정 메뉴 열기. v2.1.116: 값 검색 매칭 | — | 구버전 |
| `/context` | 현재 컨텍스트 사용량 표시 | — | 구버전 |
| `/cost` | API 비용 요약 보고 | — | v2.1.92+ |
| `/doctor` | 설정·MCP·환경 진단. v2.1.116: 실행 중 가능 | — | 구버전 |
| `/effort` | Effort level 조정. v2.1.111: 인자 없으면 slider | `low\|medium\|high\|xhigh\|max` | v2.1.94+ |
| `/env` | 환경변수 설정 (PowerShell tool에도 적용) | `<KEY=VALUE>` | 구버전 |
| `/feedback` | 피드백 제출 | — | 구버전 |
| `/focus` | focus view 토글 (v2.1.110에서 Ctrl+O에서 분리) | — | v2.1.110 |
| `/help` | 도움말 표시 | — | 구버전 |
| `/init` | 프로젝트 초기화 (CLAUDE.md 생성) | — | 구버전 |
| `/less-permission-prompts` | read-only bash/MCP allowlist 자동 제안 | — | v2.1.111 |
| `/loop` | 재귀 자율 실행 루프 시작. `/proactive` 별칭 | — | 구버전 |
| `/mcp` | MCP 서버 관리 메뉴 | — | 구버전 |
| `/model` | 모델 선택. opus / sonnet / opusplan 등 | `<model>` | 구버전 |
| `/permissions` | 권한 규칙 현황·Recent 탭 | — | 구버전 |
| `/plugin` | 플러그인 설치·관리 | `install\|update\|enable\|disable` | 구버전 |
| `/powerup` | Claude Code 기능 interactive 학습 | — | v2.1.90 |
| `/recap` | 세션 복귀 요약 (수동 실행) | — | v2.1.108 |
| `/reload-plugins` | 플러그인 재로드 (재시작 불필요, v2.1.98+) | — | v2.1.98 |
| `/release-notes` | 버전별 릴리즈 노트 interactive picker | — | v2.1.92 |
| `/resume` | 이전 세션 재개 | `[세션ID\|세션명]` | 구버전 |
| `/rewind` | 대화 이전 지점으로 되감기. `/undo` 별칭 (v2.1.108) | — | 구버전 |
| `/security-review` | 보안 리뷰 실행 | — | 구버전 |
| `/skills` | 슬래시 커맨드 목록 (토큰 수 정렬: `t` 토글) | — | 구버전 |
| `/stats` | 세션 통계 (서브에이전트 포함 v2.1.89+) | — | 구버전 |
| `/terminal-setup` | 터미널 설정 최적화 | — | 구버전 |
| `/theme` | 색상 테마 변경. "Auto (match terminal)" 추가 (v2.1.111) | — | 구버전 |
| `/tui` | fullscreen 모드 전환 | `fullscreen` | v2.1.110 |
| `/ultraplan` | 클라우드 VM 병렬 멀티에이전트 플래닝 | — | 구버전 |
| `/ultrareview` | 클라우드 병렬 PR 리뷰. 인자 없으면 현재 브랜치 | `[PR#]` | v2.1.111 |
| `/update` | Claude Code 업데이트 | — | 구버전 |
| `/usage` | 사용량 확인 (5H/7D) | — | 구버전 |

**JamesClaw 하네스 추가 커맨드**: `/prd`, `/pipeline-install`, `/pipeline-run`, `/qa`, `/blog-generate`, `/blog-review`, `/blog-fix`, `/blog-publish`, `/blog-pipeline`, `/agent-team`, `/ralph-loop`, `/self-heal`, `/design-review`, `/annotate-plan`, `/wiki-sync`, `/cost`, `/audit`, `/feedback-loop`, `/저장` 등 21개. 상세: `harness/docs/skills/skills-reference.md`.

---

### 4.2 CLI 플래그

| 플래그 | 설명 | 버전 |
|--------|------|------|
| `--agent <파일>` | 지정 에이전트 파일을 main-thread에서 실행 | 구버전 |
| `--add-dir <경로>` | 추가 작업 디렉토리 허용 | 구버전 |
| `--bare` | 최소 UI 모드 | 구버전 |
| `--continue` | 현재 세션 계속 | 구버전 |
| `--dangerously-skip-permissions` | 권한 프롬프트 전체 건너뜀 | 구버전 |
| `--debug` | 디버그 출력 (hook stderr 포함) | 구버전 |
| `--effort <레벨>` | 시작 시 effort level 지정 | v2.1.94+ |
| `--enable-auto-mode` | **제거됨** (v2.1.111. Max 구독자 자동) | v2.1.111에서 제거 |
| `--exclude-dynamic-system-prompt-sections` | print 모드에서 캐시 효율화 | v2.1.98+ |
| `--mcp-config <파일>` | MCP 서버 설정 파일 지정 | 구버전 |
| `--model <모델>` | 시작 모델 지정 | 구버전 |
| `--name <이름>` | 세션 이름 지정 | 구버전 |
| `--no-update` | 자동 업데이트 비활성화 | 구버전 |
| `--output-format <형식>` | `json`, `stream-json`, `text` | 구버전 |
| `-p` / `--print` | non-interactive 단일 실행 | 구버전 |
| `--resume <ID\|이름>` | 특정 세션 재개 | 구버전 |
| `--setting-sources` | 설정 소스 범위 제한 | 구버전 |
| `--worktree <이름>` | 새 worktree에서 세션 시작 | 구버전 |

**환경변수 플래그**

| 환경변수 | 설명 | 버전 |
|---------|------|------|
| `ANTHROPIC_BASE_URL` | API 기본 URL 오버라이드 (프록시 용도) | 구버전 |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | Agent Teams 실험 기능 활성화 | v2.1.107+ |
| `CLAUDE_CODE_NO_FLICKER` | flicker-free 렌더링 opt-in | v2.1.89+ |
| `CLAUDE_CODE_USE_POWERSHELL_TOOL` | PowerShell tool opt-in/out | v2.1.111+ |
| `CLAUDE_CODE_ENABLE_AWAY_SUMMARY` | 세션 복귀 요약 강제 | v2.1.108+ |
| `CLAUDE_STREAM_IDLE_TIMEOUT_MS` | 스트림 유휴 타임아웃 (ms) | 구버전 |
| `ENABLE_PROMPT_CACHING_1H` | 1시간 prompt cache TTL opt-in | v2.1.108+ |
| `FORCE_PROMPT_CACHING_5M` | 5분 TTL 강제 | v2.1.108+ |
| `DISABLE_COMPACT` | compact 힌트 억제 | v2.1.98+ |
| `OTEL_LOG_RAW_API_BODIES` | OpenTelemetry에 전체 API 요청/응답 바디 emit | v2.1.111+ |
| `CLAUDE_CODE_PERFORCE_MODE` | Perforce 환경 지원 | v2.1.98+ |

---

## 5. 설정 (settings.json)

### 5.1 최상위 키 레퍼런스

| 키 | 타입 | 설명 | 버전 |
|----|------|------|------|
| `thinking.budget_tokens` | number | Extended thinking 최대 토큰 예산 | 구버전 |
| `env` | object | 세션 전체 환경변수 주입 | 구버전 |
| `permissions` | object | 허용/거부 규칙, 기본 모드 | 구버전 |
| `hooks` | object | 이벤트별 hook 배열 | 구버전 |
| `enabledPlugins` | object | 플러그인 활성화 상태 | 구버전 |
| `language` | string | 응답 언어 (`"korean"` 등) | 구버전 |
| `skipDangerousModePermissionPrompt` | boolean | dangerous mode 승인 프롬프트 건너뜀 | 구버전 |
| `statusLine` | object | 커스텀 상태바 명령 | 구버전 |
| `contextCompactionThreshold` | number (0~1) | auto compact 트리거 임계값 | 구버전 |
| `tui` | string | 기본 TUI 모드 (`"fullscreen"`) | v2.1.110+ |
| `autoScrollEnabled` | boolean | fullscreen 자동 스크롤 (기본 true) | v2.1.110+ |
| `showThinkingSummaries` | boolean | thinking 요약 표시 (기본 false, v2.1.89+) | v2.1.89+ |
| `cleanupPeriodDays` | number | 세션 이력 보관 일수 (0 설정 불가, v2.1.89+) | v2.1.89+ |
| `disableSkillShellExecution` | boolean | 스킬 인라인 쉘 실행 비활성화 | v2.1.91+ |
| `refreshInterval` | number (초) | 상태바 명령 재실행 주기 | v2.1.97+ |
| `sandbox.network.deniedDomains` | string[] | 허용 와일드카드 아래에서도 차단할 도메인 | v2.1.113+ |
| `forceRemoteSettingsRefresh` | boolean | 원격 설정 갱신 실패 시 시작 차단 | v2.1.92+ |

---

### 5.2 permissions (allow / deny / defaultMode)

**JamesClaw 하네스 현행 설정** (`harness/settings.json`):

```json
{
  "permissions": {
    "allow": [
      "Bash(*)", "Read(*)", "Edit(*)", "Write(*)",
      "Glob(*)", "Grep(*)", "WebFetch(*)", "WebSearch(*)",
      "Agent(*)", "NotebookEdit(*)", "TodoWrite(*)", "Skill(*)",
      "mcp__lazy-mcp__*", "mcp__windows-mcp__*",
      "mcp__plugin_telegram_telegram__*",
      "Plugin:telegram:*", "Plugin:ralph-loop:*", "Plugin:awesome-statusline:*"
    ],
    "deny": [
      "Bash(rm -rf /)", "Bash(rm -rf ~)",
      "Bash(*format*C:*)",
      "Bash(*Remove-Item*-Recurse*-Force*C:\\*)",
      "Bash(*|*curl*)", "Bash(*|*wget*)",
      "Bash(*&&*rm -rf*)", "Bash(*;*rm -rf*)"
    ],
    "defaultMode": "bypassPermissions"
  }
}
```

**권한 패턴 문법**

| 패턴 | 의미 |
|------|------|
| `Bash(*)` | 모든 bash 명령 허용 |
| `Bash(git *)` | git으로 시작하는 bash 명령 허용 |
| `Read(*)` | 모든 파일 읽기 허용 |
| `mcp__tavily__.*` | tavily MCP 전체 도구 허용 |
| `Bash(rm -rf /)` | 루트 삭제 완전 차단 |

**defaultMode 값**

| 값 | 설명 |
|----|------|
| `"default"` | 도구별 기본 정책 |
| `"acceptEdits"` | 파일 편집 자동 승인, bash는 확인 |
| `"bypassPermissions"` | 모든 승인 프롬프트 건너뜀 (하네스 hook으로 대체 관리) |
| `"auto"` | AI가 안전성 판단 후 자율 결정 |

---

### 5.3 hooks 매처·타임아웃·if 조건

**매처 패턴 예시**

| 매처 | 대상 |
|------|------|
| `"Bash"` | 모든 Bash 도구 호출 |
| `"Write\|Edit"` | Write 또는 Edit |
| `"mcp__tavily__.*"` | tavily MCP 전체 |
| `"mcp__expect__screenshot"` | expect MCP screenshot만 |
| `"Read\|Grep\|Glob\|Bash\|Edit\|Write"` | 탐색·편집 전체 |

**`if` 조건 필드** (v2.1.85+)

```json
{
  "if": "Bash(git commit *)"
}
```

`if`가 있으면 해당 패턴에 일치할 때만 hook 실행. 프로세스 스폰 오버헤드 감소.

**타임아웃 권장값**

| hook 유형 | 권장 timeout |
|----------|-------------|
| 단순 패턴 검사 | 3,000~5,000ms |
| 외부 모델 호출 포함 | 30,000~60,000ms |
| 배포 검증 | 30,000ms |
| TypeScript hook (node) | 10,000~120,000ms |

---

### 5.4 env · thinking · language · statusLine

**env**: sessions 전체에 환경변수 주입.

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",
    "ENABLE_PROMPT_CACHING_1H": "1",
    "CLAUDE_STREAM_IDLE_TIMEOUT_MS": "180000"
  }
}
```

**thinking**: Extended thinking 예산 설정.

```json
{
  "thinking": {
    "budget_tokens": 10000
  }
}
```

**language**: 응답 언어 고정.

```json
{
  "language": "korean"
}
```

**statusLine**: 커스텀 상태바. `refreshInterval`로 주기적 재실행 (v2.1.97+).

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/awesome-statusline.sh"
  },
  "refreshInterval": 30
}
```

---

## 6. 모델 선택

### 6.1 모델 라인업

| 모델 | 별칭 | 특성 | 5H 소비 |
|------|------|------|---------|
| Claude Opus 4.7 | `opus` | 최고 품질, Extended thinking, xhigh effort | 큼 |
| Claude Sonnet 4.6 | `sonnet` | 도구 접근 완전, 코딩·배포에 최적 | 중간 (Opus보다 느림) |
| Claude Haiku 4.5 | `haiku` | 경량, 빠름 | 적음 |

**5H 롤링 윈도우**: 모든 Claude 모델 공통 (Sonnet 서브에이전트도 포함).
**7D 주간 풀**: Opus / Sonnet **별도** — `Agent(model: sonnet)` 사용 시 Opus 7D 풀 보존에 유효.
**외부 모델** (Codex / GPT-4.1 / Gemma4): 5H + 7D 양쪽 모두 0 소비.

---

### 6.2 /model 모드

| 모드 | 호출 | 특성 |
|------|------|------|
| `opusplan` (권장) | `/model opusplan` | Plan=Opus, 실행=Sonnet 자동 분리. Opus 7D 풀 보존 |
| `opus` | `/model opus` | 모든 것을 Opus 직접. 짧은 대화·판단·커밋에 적합. 5H 소비 큼 |
| `sonnet` | `/model sonnet` | 단순 단일 작업. Opus advisor 없음 |

---

### 6.3 Effort Levels

| 레벨 | 설명 | 적용 모델 |
|------|------|----------|
| `low` | 최소 추론 | 모든 모델 |
| `medium` | 기본 (v2.1.94 이전 기본값) | 모든 모델 |
| `high` | 향상된 추론 (v2.1.94부터 **기본값**) | 모든 모델 |
| `xhigh` | high와 max 사이 신규 레벨 (v2.1.111) | Opus 4.7 전용. 타 모델 → high fallback |
| `max` | 최대 extended thinking | Opus 4.7 |

**설정 방법**

```bash
/effort high         # 직접 설정
/effort              # interactive slider 열기 (v2.1.111+)
claude --effort high # CLI 플래그
```

**Auto mode** (Max 구독자): Opus 4.7 + xhigh 자동 적용. `--enable-auto-mode` 플래그 제거됨 (v2.1.111).

**CLAUDE_CODE_EXTRA_BODY `output_config.effort`**: Vertex AI 및 effort 미지원 모델 서브에이전트 호출 시 400 오류 발생 가능. v2.1.113에서 수정됨.

---

### 6.4 5H / 7D Rate Limits

| 항목 | Pro | Max |
|------|-----|-----|
| 5시간 롤링 한도 | 낮음 | 높음 |
| 7일 주간 한도 | 별도 풀 (Opus/Sonnet) | 별도 풀 (Opus/Sonnet) |
| 확인 방법 | Settings Usage 탭 (v2.1.116: 429 시에도 표시) | 동일 |
| 하네스 확인 | `telegram-notify.sh heartbeat` | 동일 |

**80%+ 비상 모드 (JamesClaw 하네스)**:

1. Opus 응답을 최대 2문장으로 제한
2. 모든 도구 호출을 Sonnet 서브에이전트로 위임
3. 대표님께 "5H 80%+, Sonnet 위임 모드" 고지
4. 필요 시 `/model sonnet`으로 전환

---

## 7. 플랫폼 / 백엔드

### 7.1 기본 Anthropic API

| 항목 | 값 |
|------|---|
| 기본 엔드포인트 | `https://api.anthropic.com` |
| 인증 | `ANTHROPIC_API_KEY` 환경변수 또는 `/login` OAuth |
| 1시간 캐시 TTL | `ENABLE_PROMPT_CACHING_1H=1` (v2.1.108+) |

---

### 7.2 Vertex AI / Bedrock / Foundry

**Vertex AI**

```bash
/setup-vertex  # 대화형 GCP 인증·프로젝트·리전 설정 (v2.1.98+)
```

| 항목 | 설명 |
|------|------|
| 1M 컨텍스트 | `/setup-vertex` 실행 시 "with 1M context" 옵션 |
| 인증 | Application Default Credentials (`gcloud auth application-default login`) |
| 환경변수 | `ANTHROPIC_VERTEX_PROJECT_ID`, `CLOUD_ML_REGION` |
| 주의 | 5xx/529 에러 시 status.claude.com 링크는 Anthropic 전용. Vertex/Bedrock는 별도 확인 |

**Amazon Bedrock**

```bash
/setup-bedrock  # 대화형 AWS 인증·리전·모델 설정 (v2.1.92+)
```

| 환경변수 | 설명 |
|---------|------|
| `AWS_ACCESS_KEY_ID` | AWS 액세스 키 |
| `AWS_SECRET_ACCESS_KEY` | AWS 시크릿 |
| `AWS_REGION` | 리전 |
| `CLAUDE_CODE_USE_MANTLE=1` | Bedrock powered by Mantle 활성화 (v2.1.94+) |
| `AWS_BEARER_TOKEN_BEDROCK` | bearer token 인증 (SigV4 충돌 주의) |

**Azure Foundry**

| 항목 | 설명 |
|------|------|
| 설정 | `/setup-foundry` |
| 환경변수 | `ANTHROPIC_FOUNDRY_BASE_URL` |

---

### 7.3 ANTHROPIC_BASE_URL 프록시 (copilot-api GPT-4.1)

copilot-api 서버가 Anthropic API 호환 인터페이스를 제공하므로 GPT-4.1을 Claude Code 메인 모델로 사용할 수 있습니다.

**전환 절차**

```bash
# 1. 서버 기동
copilot-api start --port 4141 &

# 2. GPT-4.1 메인 세션 시작
ANTHROPIC_BASE_URL=http://localhost:4141 claude

# 3. 단일 API 호출 (검수용)
curl -s --max-time 30 http://localhost:4141/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4.1","messages":[{"role":"user","content":"프롬프트"}]}'
```

**GPT-4.1 프록시 제약**

| 항목 | 내용 |
|------|------|
| 사용 가능 모델 | GPT-4.1, GPT-4o, GPT-5 mini, Claude Haiku 4.5 |
| 미지원 | /model 로 Opus/Sonnet 선택 시 에러 |
| Opus advisor | 반드시 별도 Claude Code 세션 필요 |
| 비용 | GitHub Copilot Pro $10/월 (GPT-4.1/4o 무제한) |
| 오케스트레이터 적합성 | 부적합 (Opus 60~65% 수준). 단순 반복/벌크 작업 전용 |

**HydraTeams 프록시** (`localhost:3456`): Agent Teams teammate를 외부 모델로 라우팅. copilot-api(`localhost:4141`)와 역할이 다름.

| 프록시 | 포트 | 용도 |
|--------|------|------|
| copilot-api | 4141 | 단일 API 호출 (검수, AI냄새) |
| HydraTeams | 3456 | Agent Teams teammate 전용 |

---

### 7.4 Windows PowerShell Tool

| 항목 | 내용 |
|------|------|
| 활성화 | `CLAUDE_CODE_USE_POWERSHELL_TOOL=1` |
| 지원 플랫폼 | Windows (점진 롤아웃), Linux/macOS (pwsh PATH 필요) |
| bash hook | PowerShell tool 활성화 후에도 bash hook은 bash 경유 |
| `/env` | PowerShell tool 명령에도 적용 (v2.1.89+) |
| 보안 강화 (v2.1.90) | trailing `&` background job bypass, `-ErrorAction Break` 디버거 hang, archive TOCTOU 수정 |
| PS 버전 | 5.1 vs 7+ 구문 차이 인지. 5.1에서 외부 명령 인자에 `"` + 공백 포함 시 prompt 강제 (v2.1.89) |

---

## 8. 보안 / 권한

### 8.1 deny / allow 패턴

**우선순위**: deny > allow. PreToolUse hook deny > settings.json deny > allow.

**v2.1.113 확장 매칭**: `env`, `sudo`, `watch`, `ionice`, `setsid` 등 exec wrapper로 감싸도 deny rule 적용됨.

**`Bash(find:*)` 자동 승인 제외** (v2.1.113): `find -exec`, `-delete`는 더 이상 자동 승인 안 됨.

**경로 앵커링 (Windows)**: 드라이브 레터 경로는 올바르게 root-anchored 처리 (v2.1.101+).

---

### 8.2 sandbox (sandbox.network.deniedDomains)

| 설정 키 | 설명 | 버전 |
|---------|------|------|
| `sandbox.network.allowedDomains` | 허용 도메인 패턴 목록 | 구버전 |
| `sandbox.network.deniedDomains` | 허용 와일드카드 아래에서도 차단할 도메인 | v2.1.113+ |
| `sandbox.network.allowMachLookup` | macOS DNS 조회 허용 (v2.1.98+) | v2.1.98+ |

**위험 경로 차단** (v2.1.116): sandbox auto-allow rule이 있어도 `rm`/`rmdir`의 `/`, `$HOME`, 기타 critical 디렉토리는 차단.

**macOS 위험 경로** (v2.1.113): `/private/{etc,var,tmp,home}` — `rm:*` allow rule 있어도 dangerous target으로 분류.

---

### 8.3 dangerouslyDisableSandbox

`dangerouslyDisableSandbox: true` 설정 또는 `--dangerously-skip-permissions` 플래그 사용 시:

- v2.1.113+: 반드시 권한 프롬프트 표시 (bypass 불가)
- v2.1.98 수정: protected 경로 쓰기 승인 후 bypass가 accept-edits로 강등되던 버그 수정됨

---

### 8.4 bypassPermissions 한계 (하네스 hook 독립)

`bypassPermissions` 또는 `defaultMode: "bypassPermissions"`로 설정해도 **하네스 hook은 우회 불가**합니다. (P-026)

이유: hook은 settings.json의 permissions 체계 외부에서 독립적으로 동작하는 사이드카 프로세스입니다.

**실제 적용 예시 (JamesClaw)**:
- `bash-tool-blocker.sh` (PreToolUse) — bypassPermissions 무관하게 금지 패턴 차단
- `verify-memory-write.sh` — `~/.claude/` 직접 쓰기 차단
- `pre-compact-snapshot.sh` — 저장 없이 compact 차단

`permissions.deny` 규칙도 PreToolUse hook의 `permissionDecision: "ask"` 결정보다 우선합니다. (v2.1.101 수정사항)

---

## 9. Remote Control / Scheduling

### 9.1 Remote Trigger (cron)

Claude Code 외부에서 세션을 트리거하는 기능입니다.

| 항목 | 설명 |
|------|------|
| 설정 | `RemoteTrigger` 도구 또는 claude.ai Remote Control |
| `--resume` + `-p` | deferred tool 결과 제공 후 재개 |
| 만료 안 된 scheduled task | `--resume`/`--continue` 시 재활성화 (v2.1.110+) |
| `/remote-control` | SSH 환경에서 `CLAUDE_CODE_ORGANIZATION_UUID`만으로 동작 (v2.1.101 수정) |
| `/extra-usage` | Remote Control에서 동작 (v2.1.113+) |
| `@`-file 자동완성 | Remote Control에서 쿼리 가능 (v2.1.113+) |

**JamesClaw 하네스 Remote Trigger**: `/reset-ping-setup` 커맨드로 5H/7D 리셋 타이밍에 자동 ping 설정.

---

### 9.2 /loop 재귀 실행

| 항목 | 설명 |
|------|------|
| 호출 | `/loop` 또는 `/proactive` |
| 중단 | Esc → pending wakeup 취소 (v2.1.113) |
| wakeup 표시 | "Claude resuming /loop wakeup" (v2.1.113) |
| Timestamp | scheduled task 발동 시 트랜스크립트에 시각 기록 (v2.1.85+) |

**JamesClaw 하네스**: `watchdog-ralph.sh`가 Ralph Loop 상태를 감시하고 stall 시 re-spawn합니다.

---

### 9.3 Push Notification

| 항목 | 설명 |
|------|------|
| 조건 | Remote Control 활성 + "Push when Claude decides" 설정 |
| 트리거 | Claude가 판단하여 모바일 푸시 발송 |
| 도입 | v2.1.110+ |

**JamesClaw 하네스 알림**: Push notification 대신 **Telegram Bot**을 사용합니다. `stop-dispatcher.sh`가 Stop 이벤트에서 `~/.harness-state/last_result.txt` 내용을 텔레그램으로 전송.

---

## 10. 플러그인 (Plugin 네임스페이스)

### 10.1 플러그인 개요

플러그인은 Claude Code에 slash commands, MCP 서버, hooks, 상태바 위젯을 패키지로 추가하는 확장 메커니즘입니다.

| 항목 | 설명 |
|------|------|
| 관리 | `/plugin install\|update\|enable\|disable\|uninstall` |
| 자동 업데이트 | 백그라운드 자동 업데이트 + `/reload-plugins`로 재시작 없이 반영 (v2.1.98+) |
| 의존성 | `plugin install` 시 `plugin.json` 의존성 자동 설치 (v2.1.110+) |
| 버전 충돌 | `range-conflict` 오류로 명시적 보고 (v2.1.113+) |
| 도구 수 영향 | 플러그인 MCP 서버가 도구 수에 포함. 50개 이하 유지 권장 |

**플러그인 스킬 hook** (v2.1.85+): YAML frontmatter `hooks:` 필드가 올바르게 실행됨. (이전엔 silently ignored)

**Agent frontmatter `hooks:` main-thread** (v2.1.116): `--agent` 플래그 실행 시 `agents/*.md`의 hooks 발동.

---

### 10.2 JamesClaw 하네스 활성 플러그인

| 플러그인 | 소스 | 기능 |
|---------|------|------|
| `telegram` | `claude-plugins-official` | Telegram 채널 통합, 알림, 파일 전송 |
| `awesome-statusline` | `awesome-claude-plugins` | 커스텀 상태바 (`~/.claude/awesome-statusline.sh`) |
| `ralph-loop` | `claude-plugins-official` | Ralph Loop 자율 개선 루프 |

---

### 10.3 Managed Settings (Enterprise)

| 항목 | 설명 |
|------|------|
| 파일 | `managed-settings.json` |
| `forceRemoteSettingsRefresh` | 원격 설정 갱신 실패 시 시작 차단 (v2.1.92+) |
| `allowManagedHooksOnly` | 관리자 지정 hook만 실행 허용 |
| 정책 플러그인 | 조직 정책으로 차단된 플러그인은 설치·활성화 불가, 마켓플레이스에서 숨김 (v2.1.85+) |
| allow rules 제거 | 관리자가 제거 후 프로세스 재시작까지 이전 규칙 유지되던 버그 수정 (v2.1.101) |

---

## 11. 트러블슈팅 & 알려진 제약

### 11.1 rate limit 관련

| 증상 | 원인 | 대응 |
|------|------|------|
| 5H limit 도달 | Claude 모델 공통 5H 롤링 소비 | 외부 모델(GPT-4.1) 전환 또는 대기 |
| 5H 수치 N/A | Usage endpoint 429 | Settings Usage 탭 직접 확인 (v2.1.116+) 또는 캐시 삭제 후 재시도 |
| 429 즉각 표시 | Bedrock/Vertex/Foundry에서 raw JSON 덤프 | v2.1.105+에서 수정됨 |
| 긴 Retry-After 대기 | Retry-After가 작을 때 전체 시도를 13초에 소비 | v2.1.97+에서 지수 백오프 최소값 적용으로 수정 |

---

### 11.2 /resume 관련

| 증상 | 원인 | 버전 수정 |
|------|------|----------|
| 빈 대화 표시 | 대형 세션 파일 로드 오류 | v2.1.116 |
| dead-fork로 인한 느림 | 40MB+ 세션 처리 | v2.1.116 (67% 가속) |
| 50MB+ 트랜스크립트 거부 | `/branch` 크기 제한 | v2.1.116 수정 |
| 세션명 손실 | `/clear` 후 `/rename` 이름 초기화 | v2.1.111 수정 |
| 컨텍스트 손실 | 대형 세션에서 dead-end 브랜치 참조 | v2.1.101 수정 |

---

### 11.3 MCP 관련

| 증상 | 원인 | 대응 |
|------|------|------|
| MCP 도구 첫 턴 누락 | 비동기 연결 지연 | v2.1.101 수정됨 |
| concurrent-call timeout | 한 호출이 다른 watchdog disarm | v2.1.113 수정됨 |
| SSE 연결 메모리 누수 | 재연결 시 버퍼 미해제 | v2.1.97 수정됨 |
| stdio 서버 stray JSON | 비-JSON 출력 시 즉시 연결 해제 | v2.1.110 수정됨 |

---

### 11.4 훅 관련

| 증상 | 원인 | 대응 |
|------|------|------|
| hook `if` 조건 미매칭 | 복합 명령 (`ls && git push`)·env-var 접두사 | v2.1.89 수정됨 |
| PreToolUse deny 무효 | `permissionDecision: "ask"` hook이 deny 하강 | v2.1.101 수정됨 |
| Stop hook 실패 (long session) | 프롬프트 타입 Stop hook 오류 | v2.1.98 수정됨 |
| hook 출력 50K+ 컨텍스트 폭발 | 대용량 hook stdout | v2.1.89+: 디스크 저장 후 경로만 주입 |

**디버깅**: `--debug` 플래그로 hook stderr 첫 줄이 트랜스크립트에 표시됩니다 (v2.1.98+).

---

### 11.5 알려진 제약 (JamesClaw 하네스 기준)

| 항목 | 제약 | 우회 |
|------|------|------|
| bypassPermissions + hook | bypassPermissions가 hook을 우회하지 않음 (P-026) | 설계 의도. hook이 최종 관문 |
| gbrain put --content 멀티라인 | 멀티라인 내용 깨짐 | `gbrain put <slug> < file` 방식 사용 |
| Sonnet Vision 정확도 | Opus 대비 디테일 누락 20~30% | 이미지 분석은 Opus 직접 Read 또는 vision-routing-guard.sh |
| 도구 수 50개 초과 | 서브에이전트 실패 위험 | 온디맨드 MCP 사용 후 `claude mcp remove` |
| GLM-5.1:cloud 자동 실행 | cloud 태그 = 과금 리스크 | 수동 호출만 (`ollama run glm-5.1:cloud`) |
| compact 후 저장 | compact 후 저장은 무의미 | 반드시 직전에 `/저장` 실행 (P-007) |

---

### 11.6 Windows 특수 사항

| 항목 | 설명 |
|------|------|
| 경로 구분자 | bash 명령에서 슬래시(`/`) 사용. Windows 경로는 `D:/path` 형식 |
| `Ctrl+Backspace` | 이전 단어 삭제 (v2.1.113+) |
| `CLAUDE_ENV_FILE` | SessionStart hook 환경 파일 적용 (v2.1.111 수정) |
| 드라이브 레터 대소문자 | 대소문자 차이 있는 경로도 동일 경로로 인식 (v2.1.101+) |
| PowerShell tool | `CLAUDE_CODE_USE_POWERSHELL_TOOL=1` opt-in (v2.1.111+, 점진 롤아웃) |
| `/insights` EBUSY | Windows에서 세션 파일 잠금 오류 (v2.1.113 수정) |

---

## 12. 참고 링크

### 공식 문서

| 링크 | 내용 |
|------|------|
| `https://docs.claude.com` | Claude Code 공식 문서 |
| `https://status.claude.com` | Anthropic API 상태 (Vertex/Bedrock는 별도 확인) |

### 하네스 내부 문서

| 경로 | 내용 |
|------|------|
| `harness/docs/index.md` | 하네스 전체 개요 및 문서 구조 |
| `harness/docs/hooks/hooks-reference.md` | 41개 hook 전체 레퍼런스 |
| `harness/docs/skills/skills-reference.md` | 21개 slash command 레퍼런스 |
| `harness/docs/multi-model/routing.md` | 모델 라우팅 전략 |
| `harness/docs/pitfalls/index.md` | PITFALL 50개 (P-001~P-055) |
| `harness/docs/getting-started/quickstart.md` | 5분 설치 튜토리얼 |

### 외부 도구 레퍼런스

| 도구 | 경로 / 명령 |
|------|------------|
| gbrain 지식베이스 | `gbrain query "검색어"` / `gbrain put <slug> < file` |
| NotebookLM (Claude Code 공식 매뉴얼) | `PYTHONUTF8=1 nlm notebook query "f5fcbaf9-1605-4e90-90ef-34a06acde407" "질문"` |
| NotebookLM (하네스 Blueprint) | `PYTHONUTF8=1 nlm notebook query "fc9fcf38-0a88-4e76-b5ec-6e381693a7ae" "질문"` |
| Codex 로테이션 | `bash harness/scripts/codex-rotate.sh "프롬프트"` |
| GPT-4.1 단일 호출 | `curl -s http://localhost:4141/v1/chat/completions` |
| Ollama 로컬 | `http://localhost:11434` (Gemma 4 폴백) |

---

> 이 문서는 `~/.claude/cache/changelog.md` (1차 소스)와 `harness/CLAUDE.md` (v2.1.112~116 섹션)를 기반으로 작성되었습니다.
> 추측으로 기재된 항목은 없습니다. 버전이 명시되지 않은 항목은 "구버전"으로 표기하며 정확한 도입 버전이 changelog에서 확인되지 않은 경우입니다.
> 다음 갱신 시 `~/.claude/cache/changelog.md`의 최신 항목을 확인하여 반영하십시오.
