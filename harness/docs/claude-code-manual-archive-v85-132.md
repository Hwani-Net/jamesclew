# Claude Code 매뉴얼 — 구버전 히스토리 아카이브 (v2.1.85 ~ v2.1.132)

> 2026-06-11 다이어트로 본 매뉴얼 §2에서 분리. 본 매뉴얼: claude-code-manual.md (v2.1.133+ 유지). raw 원문: ~/.claude/cache/changelog.md

### v2.1.124 ~ v2.1.132 통합 (2026-04-29 ~ 2026-05-07)

> 9개 마이너 통합 — 핵심 변화만. 전체 원문은 `~/.claude/cache/changelog.md` (line 1~50 = v2.1.132).

#### v2.1.132 (2026-05-07, latest)

| 항목 | 내용 |
|------|------|
| **statusline `context_window` 토큰 카운트 fix** | 누적 세션 토큰 → 현재 컨텍스트 사용량으로 수정. 이전엔 statusline이 부정확 표시 |
| `CLAUDE_CODE_SESSION_ID` env var (Bash subprocess) | hook의 `session_id`와 동일 값을 Bash 도구 자식 프로세스에 자동 export |
| `CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1` | fullscreen alternate-screen 렌더러 비활성화 → terminal native scrollback 유지 |
| MCP `tools/list` 실패 처리 | "connected · tools fetch failed" 표시 + 1회 자동 재시도 |
| Bedrock + `ENABLE_PROMPT_CACHING_1H` 400 fix | (Anthropic 직접 사용자 무관) |
| 외부 SIGINT graceful shutdown | IDE stop 버튼/`kill -INT` 시 terminal mode 복구 + `--resume` 힌트 표시 |
| `--resume` low-surrogate 손상 sanitize | tool error truncation으로 emoji split된 세션 복구 |

> **하네스 영향**: statusline fix는 `telegram-notify.sh heartbeat` 정확도 회복 — P-114 freshness와 별개 layer. `CLAUDE_CODE_SESSION_ID` 활용해 Bash hook에서 세션 추적 가능.

#### v2.1.129 (2026-05-04 추정)

| 항목 | 내용 |
|------|------|
| `--plugin-url <url>` flag | .zip 플러그인 archive URL fetch 후 현재 세션 로드 |
| `CLAUDE_CODE_FORCE_SYNC_OUTPUT=1` | sync output 강제 활성 (Emacs `eat` 등) |
| `CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE` | Homebrew/WinGet 환경에서 백그라운드 업그레이드 + 재시작 prompt |
| Plugin manifests `themes`/`monitors` → `experimental` 권장 | 상위 레벨 선언은 동작하나 `claude plugin validate` warn |
| **Gateway `/v1/models` discovery opt-in** | `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1` 필요. 2.1.126~2.1.128에는 자동 |
| Ctrl+R prompts 검색 default | 모든 프로젝트/세션 검색. Ctrl+S로 현재로 좁힘 |
| `skillOverrides` 작동 | `off`/`user-invocable-only`/`name-only` |
| OTel `claude_code.pull_request.count` MCP 포함 | gh CLI 외에도 MCP 도구 PR 카운트 |

> **하네스 영향**: copilot-api(`localhost:4141`)/HydraTeams(`localhost:3456`) 사용 시 `/model` 자동 picker가 opt-in으로 변경됨. 모델 선택 동작이 달라졌다면 `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1` 추가.

#### v2.1.128 (2026-05-03 추정)

| 항목 | 내용 |
|------|------|
| `/mcp` tool count 표시 | 연결된 서버의 도구 개수 + 0 tools 서버 flag |
| `--plugin-dir` .zip archive 수용 | 디렉토리 외에 .zip 플러그인 archive 직접 로드 |
| `--channels` console 인증 작동 | API key 인증 + console org `channelsEnabled: true` |
| `/model` Opus 4.7 entries 통합 | 중복 제거 + 현재 Opus는 단순 "Opus" 표시 |
| Subprocess `OTEL_*` env 차단 | Bash/hooks/MCP/LSP 자식이 CLI OTLP endpoint 상속 안 함 |
| **`workspace`는 reserved MCP server name** | 동일 이름 서버 skip + warning |
| **MCP 재연결 도구 목록 flooding 방지** | 재발견 도구는 server prefix로 요약 |
| SDK `localSettings` 영구화 | "Always allow" Bash 권한 → `.claude/settings.local.json` 기록 |
| `EnterWorktree` local HEAD 사용 | 이전 `origin/<default-branch>` → 로컬 unpushed commits 보존 |
| **1-hour prompt cache TTL silent 5분 downgrade fix** | `ENABLE_PROMPT_CACHING_1H=1` 사용자에 직접 영향 |
| **1M-context + 작은 autocompact window false "Prompt is too long" 차단 fix** | P-115/P-116 영역 native fix |
| `Bash(mkdir *)`, `Bash(touch *)` allow rules in-project paths fix | 이전엔 자동 승인 안 됨 |
| `/context` ASCII 그리드 dump fix | ~1.6k 토큰 낭비 제거 |
| 평행 shell tool 호출 | 한 명령 실패가 형제 호출 cancel 안 함 |

> **하네스 영향**: `ENABLE_PROMPT_CACHING_1H=1` 효과가 이번 버전부터 정상 1시간 (이전엔 silent 5분). P-115/P-116 native fix 후에도 우리 wrapper(`claude-opus.cmd` + `.claude/settings.local.json`) 유효.

#### v2.1.126 (2026-05-01 추정)

| 항목 | 내용 |
|------|------|
| `/model` picker gateway `/v1/models` 자동 (2.1.129에서 opt-in) | `ANTHROPIC_BASE_URL` 게이트웨이 |
| **`claude project purge [path]`** | 프로젝트 state 전체 삭제 (transcripts, tasks, file history, config). `--dry-run`/`-y`/`-i`/`--all` |
| `--dangerously-skip-permissions` 보호 경로 우회 확장 | `.claude/`/`.git/`/`.vscode/`/shell config 우회. catastrophic rm은 차단 유지 |
| `claude auth login` OAuth code paste | WSL2/SSH/container에서 browser callback 실패 시 |
| `claude_code.skill_activated` OTel `invocation_trigger` | `user-slash`/`claude-proactive`/`nested-skill` |
| **PowerShell tool 활성 시 Windows primary shell** | 이전엔 Bash default |
| Read tool: per-file malware-assessment reminder 제거 | legacy 모델 spurious 거부 fix |
| **Security: `allowManagedDomainsOnly`/`allowManagedReadPathsOnly` fix** | 상위 priority managed-settings에 sandbox block 부재 시 무시되던 버그 |
| 2000px+ 이미지 paste auto-downscale | history 내 oversized 이미지도 자동 제거 + 재시도 |
| Windows: 한/중/일 garbled fix in no-flicker mode | |
| `Ctrl+L` prompt input clear → screen redraw | readline 일치 |

> **하네스 영향**: `--dangerously-skip-permissions` 위험성 ↑ — `.claude/` 보호 우회됨. `irreversible-alert.sh` 독립 동작으로 안전망 잔존.

#### v2.1.121 (2026-04-26 추정)

| 항목 | 내용 |
|------|------|
| **MCP `alwaysLoad` option** | 서버 단위 `true` 시 모든 도구 ToolSearch deferral skip + 항상 활성. 적용: `tavily`, `expect`, `perplexity` (2026-05-07) |
| `claude plugin prune` | orphaned 자동 설치 의존성 제거. `plugin uninstall --prune` cascades |
| `/skills` type-to-filter 검색 | |
| **PostToolUse `updatedToolOutput` 모든 도구** | `hookSpecificOutput.updatedToolOutput` — 이전 MCP 전용 |
| `CLAUDE_CODE_FORK_SUBAGENT=1` non-interactive 작동 | SDK + `claude -p` |
| `--dangerously-skip-permissions` `.claude/skills/`/`agents/`/`commands/` 우회 | |
| `/terminal-setup` iTerm2 클립보드 활성 | `/copy` (tmux 포함) |
| **MCP startup 시 transient error 3회 자동 재시도** | |
| 메모리 누수 다수 fix | unbounded RSS 증가, `/usage` 누수, long-running tool 누수, Bash 도구 cwd 삭제 시 영구 사용 불가 |

> **하네스 영향**: `alwaysLoad` 도입으로 자주 쓰는 MCP의 ToolSearch 호출 비용 절감. PostToolUse `updatedToolOutput`로 도구 출력 redact/transform hook 패턴 가능.

#### v2.1.120 (2026-04-25 추정)

| 항목 | 내용 |
|------|------|
| **Windows: Git for Windows 불필요** | 부재 시 PowerShell이 shell tool. 대표님(Git Bash 사용) 영향 없음 |
| **`claude ultrareview [target]` CLI 서브커맨드** | non-interactive. `--json` 원시 출력. `harness/scripts/ultrareview-headless.sh` 래퍼(2026-05-07) |
| Skills `${CLAUDE_EFFORT}` | 현재 effort level 참조 |
| `AI_AGENT` env var 자동 | `gh`가 Claude Code 트래픽 추적 |
| Auto-compact in auto mode `auto` 표시 | 이전엔 misleading token value |
| `DISABLE_TELEMETRY`/`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` API/엔터프라이즈 차단 | |

#### v2.1.119 (2026-04-24)

| 항목 | 내용 |
|------|------|
| `/config` 영구화 | `~/.claude/settings.json` (theme, editor mode, verbose 등) |
| `prUrlTemplate` 설정 | 사용자 정의 코드 리뷰 URL |
| `CLAUDE_CODE_HIDE_CWD` env | 시작 로고에 cwd 숨김 |
| `--from-pr` GitLab/Bitbucket/GHE | |
| `--print` mode agent `tools:`/`disallowedTools:` 존중 | 인터랙티브와 일치 |
| PowerShell tool 자동 승인 in permission mode | Bash와 일치 |
| **Hooks `PostToolUse`/`PostToolUseFailure` 입력 `duration_ms`** | 도구 실행 시간 (권한/PreToolUse hook 제외). `tool-duration-monitor.sh` 신설(2026-05-07) |
| Subagent + SDK MCP 병렬 reconnect | |
| **Status line stdin JSON `effort.level`/`thinking.enabled`** | |
| OTel `tool_result` `tool_use_id` + `tool_input_size_bytes` | |
| **`${ENV_VAR}` MCP HTTP/SSE/WebSocket headers substitution fix** | 이전엔 미substitution |
| **Agent `isolation: "worktree"` stale 재사용 fix** | 이전 세션의 좀비 worktree |
| Tool search Vertex AI default 비활성 | `ENABLE_TOOL_SEARCH=1` opt-in |
| Skills auto-compaction 후 재실행 fix | 다음 user message에 |

> **하네스 영향**: `duration_ms` 활용 hook 신설(`tool-duration-monitor.sh`) — 60초 초과 도구 호출 stderr 경고 + `~/.harness-state/tool_durations.jsonl` 누적.

---

### v2.1.123 (2026-04-29)

#### 버그 수정

| 항목 | 내용 |
|------|------|
| **OAuth 401 retry loop 수정** | `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` 설정 사용자에 한해 OAuth 인증 실패 시 401 무한 재시도 루프 발생하던 문제 수정 |

> **하네스 영향**: 없음. `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1`을 사용하지 않는 일반 환경에서는 해당 없음.

---

### v2.1.122 (2026-04-28)

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

### v2.1.121 (2026-04-27)

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
> 2. **`alwaysLoad`**: `settings.json`의 고정 사용 MCP(agentmemory, telegram 등)에 `"alwaysLoad": true` 추가 시 Tool Budget 절감 가능. ToolSearch 우회로 응답 속도도 향상.
> 3. **`--dangerously-skip-permissions` 확장**: `.claude/skills/`, `.claude/agents/`, `.claude/commands/` 쓰기가 승인 없이 허용됨. `bash-tool-blocker.sh`는 독립 동작 유지 (P-026).
> 4. **`--resume` 크래시 수정**: v2.1.120 회귀(PITFALL pitfall-067) 해결. v2.1.119 다운그레이드 불필요.

---

### v2.1.120 (2026-04-24)

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

### v2.1.119 (2026-04-23)

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

### v2.1.118 (2026-04-23)

#### Hook에서 MCP 도구 직접 호출 (하네스 큰 영향)

| 항목 | 변경 내용 |
|------|----------|
| Hook `type: "mcp_tool"` | bash subprocess 없이 MCP 도구 직접 호출 가능 |

> **활용 후보**: `telegram-notify.sh` → `mcp__plugin_telegram_telegram__reply` 직접 호출, pitfall 저장 → `mcp__agentmemory__memory_save` 직접 호출. 환경변수 보간 지원 여부 확인 필요 (v2.1.63 HTTP hook과 동일 제약 가능성).

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

### v2.1.117 (2026-04-22)

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

### v2.1.116 (2026-04-21)

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

### v2.1.113~v2.1.114 (2026-04-18)

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

### v2.1.111~v2.1.112 (2026-04-17)

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

### v2.1.110

| 항목 | 변경 내용 |
|------|----------|
| `/tui` 커맨드 | `fullscreen` 모드 전환. `tui` settings 키로도 설정 |
| push notification | Remote Control + "Push when Claude decides" 활성 시 Claude가 모바일 푸시 발송 |
| `autoScrollEnabled` | fullscreen 모드에서 자동 스크롤 비활성화 옵션 |
| `--resume`/`--continue` | 만료 안 된 scheduled task 재활성화 |
| `Ctrl+O` | focus view 토글 (이전: verbose transcript 포함. v2.1.110부터 focus 전용) |
| Write tool | IDE diff에서 제안 내용 편집 후 accept 시 모델에게 알림 |

---

### v2.1.108~v2.1.109

| 항목 | 변경 내용 |
|------|----------|
| `ENABLE_PROMPT_CACHING_1H` | 1시간 prompt cache TTL opt-in. `FORCE_PROMPT_CACHING_5M`으로 5분 강제 |
| `/recap` | 세션 복귀 시 요약 제공. `/config`에서 설정, `CLAUDE_CODE_ENABLE_AWAY_SUMMARY`로 강제 |
| `/undo` | `/rewind` 별칭 |
| extended-thinking 인디케이터 | 회전 진행 힌트 표시 (v2.1.109) |
| `/team-onboarding` (v2.1.101) | 로컬 Claude Code 사용 기록 기반 팀원 온보딩 가이드 생성 |

---

### v2.1.105

| 항목 | 변경 내용 |
|------|----------|
| `EnterWorktree` path 파라미터 | 기존 worktree로 재진입 가능 (`path: "existing/worktree"`) |
| PreCompact hook 지원 | `exit 2` 또는 `{"decision":"block"}` 반환으로 compact 차단 가능 |
| `/proactive` | `/loop` 별칭 |
| stall 처리 개선 | 5분 무데이터 스트림 abort → 비스트리밍 재시도 |
| `/doctor` | `f` 키로 Claude가 이슈 자동 수정 |
| 서브에이전트 MCP 도구 상속 | 동적 추가된 MCP 도구도 서브에이전트에 자동 상속 |

---

### v2.1.101

| 항목 | 변경 내용 |
|------|----------|
| OS CA 인증서 자동 신뢰 | 기업 TLS 프록시 추가 설정 없이 동작 (`CLAUDE_CODE_CERT_STORE=bundled`로 번들만 사용) |
| `/ultraplan` 자동 환경 생성 | 별도 웹 설정 없이 클라우드 환경 자동 생성 |
| 서브에이전트 MCP 상속 | `Agent(model: "sonnet")` 호출 시 동적 MCP 도구 자동 상속 (v2.1.101+) |

---

### v2.1.98

| 항목 | 변경 내용 |
|------|----------|
| Monitor tool | 백그라운드 스크립트의 stdout 스트리밍 감시 |
| `/setup-vertex` 개선 | 실제 settings.json 경로 표시, 1M context 옵션 |
| `CLAUDE_CODE_PERFORCE_MODE` | Perforce 환경에서 read-only 파일 쓰기 시 `p4 edit` 힌트 |
| Bash 보안 강화 | 백슬래시 이스케이프 플래그 bypass 수정, 복합 명령 강제 프롬프트 수정 |

---

### v2.1.94

| 항목 | 변경 내용 |
|------|----------|
| 기본 effort 레벨 변경 | medium → **high** (API key, Bedrock/Vertex/Foundry, Team, Enterprise 사용자) |
| `hookSpecificOutput.sessionTitle` | `UserPromptSubmit` hook에서 세션 제목 설정 가능 |
| Amazon Bedrock Mantle 지원 | `CLAUDE_CODE_USE_MANTLE=1` |

---

### v2.1.92

| 항목 | 변경 내용 |
|------|----------|
| Vertex AI setup wizard | 로그인 화면에서 GCP 인증·프로젝트·리전 설정 대화형 안내 |
| `/cost` 개선 | 구독 사용자용 모델별·캐시 히트별 세분화 표시 |
| `forceRemoteSettingsRefresh` | 원격 설정 갱신 실패 시 시작 차단 (fail-closed) |

---

### v2.1.91

| 항목 | 변경 내용 |
|------|----------|
| MCP tool result 크기 override | `_meta["anthropic/maxResultSizeChars"]` (최대 500K)로 DB 스키마 등 대용량 결과 통과 |
| `disableSkillShellExecution` | 스킬·슬래시 커맨드·플러그인의 인라인 쉘 실행 비활성화 |

---

### v2.1.90

| 항목 | 변경 내용 |
|------|----------|
| `/powerup` | Claude Code 기능 interactive 학습 (애니메이션 데모 포함) |
| `.husky` 보호 디렉토리 | acceptEdits 모드에서 보호 |
| `CLAUDE_CODE_PLUGIN_KEEP_MARKETPLACE_ON_FAILURE` | git pull 실패 시 기존 마켓플레이스 캐시 유지 |

---

### v2.1.89

| 항목 | 변경 내용 |
|------|----------|
| `defer` permission decision | `PreToolUse` hook에서 `"permissionDecision": "defer"` 반환 → 실행 일시정지 + 사용자 확인 요청 |
| `CLAUDE_CODE_NO_FLICKER=1` | flicker-free alt-screen 렌더링 + 가상 scrollback (opt-in) |
| `PermissionDenied` hook | auto mode classifier 거부 후 발동. `{retry: true}` 반환 시 재시도 허용 |
| autocompact thrash 루프 차단 | 3회 연속 compact 직후 컨텍스트 리필 감지 시 API 소비 방지 |

하네스 `irreversible-alert.sh`는 이 `defer` 결정을 활용합니다. v2.1.89+ 기능.

---

### v2.1.85

| 항목 | 변경 내용 |
|------|----------|
| hook `if` 조건 필드 | permission rule 문법으로 hook 실행 조건 필터링 (`Bash(git *)`) |
| hook 출력 50K+ 차단 | 50K 초과 hook 출력을 디스크에 저장 후 경로+미리보기만 컨텍스트에 주입 |
| PreToolUse `AskUserQuestion` 응답 | `updatedInput` + `permissionDecision: "allow"` 반환으로 headless에서 질문 응답 가능 |

---

