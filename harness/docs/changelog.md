# 하네스 변경 로그

> What's New | 최신 변경이 상단에 위치 | 최종 업데이트: 2026-04-22

---

## 2026-04-22 — Claude Code v2.1.117 반영

| 항목 | 내용 | 영향 파일 |
|------|------|----------|
| Opus 4.7 1M 컨텍스트 버그 수정 반영 | 기존 200K 기준 계산 → 1M 네이티브. `/compact 45%` 규칙 실효 공간 여유 확보 | `CLAUDE.md` v2.1.117 섹션 |
| 기본 effort `high` 상승 | Pro/Max + Opus 4.6/Sonnet 4.6. effortLevel 고정 금지 정책과 정합 | `CLAUDE.md` |
| Agent frontmatter `mcpServers` main-thread | `agents/*.md`에 agent별 MCP 스코프 지정 가능 (Tool Budget 최적화) | `CLAUDE.md`, `docs/claude-code-manual.md` |
| `/model` 영구 지속 | 재시작해도 유지. opusplan 고정 운용 개선 | — |
| 로컬 매뉴얼 v2.1.117 갱신 | 버전 히스토리 섹션 2.0 신설. frontmatter + 목차 갱신 | `docs/claude-code-manual.md` |

---

## 2026-04-21 (저녁) — /deep-plan deprecated 정리

| 항목 | 내용 | 영향 파일 |
|------|------|----------|
| `/deep-plan` 참조 제거 | 하네스·Claude Code 내장 모두 실체 없음 확인 (Glob/Grep/changelog 검증). Build Transition Rule에서 deprecated 명시 | `CLAUDE.md`, `docs/configure/claude-md.md`, `docs/skills/skills-reference.md` |
| `/ultraplan` 자동 환경 생성 명시 | v2.1.101+ Claude Code on the web 자동 클라우드 환경 생성. GitHub repo 필수 문구 제거 | `CLAUDE.md` |
| 오프라인 fallback 경로 | `/ultraplan` 네트워크 차단 시 `/plan`(로컬 내장)으로 fallback | `CLAUDE.md` |
| 대체 경로 | Research/Interview/External LLM Review/TDD는 `/pipeline-install` + `/annotate-plan` + `/qa` 조합으로 대체 | — |

---

## 2026-04-21 (저녁) — Claude Code 로컬 매뉴얼 재구축 (Path B)

| 항목 | 내용 | 영향 파일 |
|------|------|----------|
| claude-code-manual.md 신설 | v2.1.116 기반 로컬 신뢰 소스 (1240줄). NLM stale(v2.1.101) 대체 | `harness/docs/claude-code-manual.md` |
| CLAUDE.md 기능 참조 규칙 재설계 | 우선순위 1(로컬)→2(changelog)→3(NLM) 명시 | `CLAUDE.md` |
| Build Transition Rule 0단계 신설 | 프로젝트 시작 시 매뉴얼·index·gbrain 사전 조회 강제 | `CLAUDE.md` |
| 소스 | ~/.claude/cache/changelog.md + 05-wiki/entities/claude-code-runtime.md + 기존 docs | — |
| 근거 | 2026-04-21 조사 결과 NLM 노트북이 v2.1.101에 멈춘 상태 확인. 옵시디언 원본 `.md`는 존재하지 않음(Smart Connections 인덱스만 잔존) | — |

---

## 2026-04-21 (오후) — drift-guard 통합 (P-054 대응)

| 항목 | 내용 | 영향 파일 |
|------|------|----------|
| drift-guard 모듈 등록 | Hwani-Net/drift-guard(@stayicon/drift-guard) 설치 옵션 추가 | `modules.yaml` |
| `verify-deploy.sh` 확장 | `.drift-guard.json` 감지 시 배포 전 `npx drift-guard check` 강제. 실패 exit 2 차단 | `hooks/verify-deploy.sh` |
| `/pipeline-run` Step 3-0 추가 | 시각 검수 전 drift-guard 토큰 검사. 실패 시 Step 1 강제 복귀 | `commands/pipeline-run.md` |
| `stitch-drift-guard.sh` 신규 hook | `mcp__stitch__*` 호출 후 init/check 유도. 10분 debounce | `hooks/stitch-drift-guard.sh` |
| settings.json matcher 등록 | PostToolUse `mcp__stitch__fetch_screen_code\|generate_screen_from_text\|edit_screens\|apply_design_system` | `settings.json` |
| CLAUDE.md Quality Gates 섹션 보강 | drift-guard 통합 원칙 명시 + Vision과의 레이어 구분 | `CLAUDE.md` |
| 근거 | P-054 재발 검토 + drift-guard README(ADR-008 Design Dictatorship). CLI zero-token이 MCP 대비 10k-50k 절감 | — |

---

## 2026-04-21 — v2.1.116 반영

| 항목 | 내용 | 근거 | 영향 파일 |
|------|------|------|----------|
| /resume 성능 67% 개선 | 40MB+ 세션, dead-fork 처리 효율화 | v2.1.116 릴리즈 | — |
| MCP 시작 속도 향상 | stdio 서버 다수 시 가속. resources/templates/list는 @-mention 전 지연 로드 | v2.1.116 | — |
| Agent frontmatter hooks main-thread 동작 | `--agent` 플래그로 main-thread 에이전트 실행 시 agents/*.md의 hooks 필드 작동. 기존엔 subagent에서만 발동 | v2.1.116 | agents/*.md 활용 가능성 |
| Settings Usage 탭 즉시 표시 | 5H/7D endpoint 429 시에도 값 노출. telegram-notify.sh heartbeat와 중복 레이어 | v2.1.116 | — |
| Bash gh rate-limit 힌트 | GitHub API rate limit 히트 시 back-off 힌트 주입. loop-detector.sh와 보완 | v2.1.116 | — |
| sandbox rm/rmdir 위험 경로 차단 | auto-allow rule 있어도 /, $HOME 등은 차단. irreversible-alert.sh와 중복 없음 | v2.1.116 보안 | — |
| Thinking 스피너 inline 진행 표시 | "still thinking", "almost done thinking" inline | v2.1.116 UI | — |
| /doctor 실행 중 가능 | 응답 중에도 호출 가능 | v2.1.116 | — |
| /config 검색 값 매칭 | "vim" → Editor mode 옵션 발견 | v2.1.116 | — |

---

## 2026-04-18 (오후) — 문서화 추가

| 항목 | 내용 | 영향 파일 |
|------|------|----------|
| docs/ 디렉토리 신설 | hooks-guide, skills-guide, routing, pitfalls/index, changelog 5개 문서 최초 작성 | `harness/docs/` 전체 |

---

## 2026-04-18 (오전) — v2.1.113~v2.1.114 반영

| 항목 | 내용 | 근거 | 영향 파일 |
|------|------|------|----------|
| Subagent stall 자동 실패 | 10분간 stream 없으면 clear error로 실패. 기존 silent hang 해소. R14 watchdog(10분 re-spawn)와 중복 아님 — 두 레이어 모두 유지 | v2.1.113 릴리즈 | CLAUDE.md |
| Agent Teams permission crash fix | teammate가 도구 권한 요청 시 crash 해결됨 | v2.1.114 릴리즈 | — |
| Bash deny rules 확장 | `env`, `sudo`, `watch` 등 exec wrapper로 감싸도 deny rule 적용됨 | v2.1.113 보안 강화 | `settings.json` 참조 |
| `find -exec / -delete` 자동 승인 제외 | 기존 auto-allow에서 제거. bash-tool-blocker.sh와 이중 차단 | v2.1.113 | `bash-tool-blocker.sh` |
| no-op cd 권한 완화 | `cd <현재경로> && git ...` 형태는 permission prompt 없이 즉시 실행 | v2.1.113 | `settings.json` |
| P-055 추가 | Sonnet Vision 정확도 격차 공식 기록. Vision 라우팅 규칙 CLAUDE.md에 추가 | 실측 확인 | `pitfalls/pitfall-055-*` |

---

## 2026-04-17 — v2.1.112 반영 + 스킬 추가

| 항목 | 내용 | 근거 | 영향 파일 |
|------|------|------|----------|
| /less-permission-prompts 반영 | 트랜스크립트 스캔 → read-only 커맨드 allowlist 자동 제안. `settings.json`에 8개 rule 적용 완료 | v2.1.112 신규 커맨드 | `settings.json` |
| /ultrareview 반영 | 클라우드 병렬 멀티에이전트 PR 리뷰. 체험권 3회 후 과금. 기본 파이프라인은 무료 외부 모델 유지 | v2.1.112 신규 커맨드 | CLAUDE.md |
| xhigh effort level | Opus 4.7 전용 신규 레벨. Sonnet에서는 high로 자동 fallback | v2.1.112 Effort Level | CLAUDE.md |
| /annotate-plan 스킬 추가 | Boris Tane 방식 플랜 주석 루프. 최대 6회 수렴. enforce-build-transition.sh가 ANNOTATE-APPROVED 헤더 검증 | 품질 게이트 강화 | `commands/annotate-plan.md` |
| pipeline-run 11→7단계 | 불필요한 중간 단계 제거, 핵심 7단계로 압축 | 효율화 | `commands/pipeline-run.md` |
| P-053, P-054 추가 | Next.js 정적 빌드 HTML 스테일, Stitch 디자인-코드 간 괴리 | 실운영 발견 | `pitfalls/` |

---

## 2026-04-18 (자율성 완화) — bash-tool-blocker 조정

| 항목 | 내용 | 근거 | 영향 파일 |
|------|------|------|----------|
| explore-router.sh 임계값 상향 | 5회 → 15/30/50 단계적 경고로 완화. 과도한 차단으로 자율 탐색 방해 해소 | 운영 피드백 | `hooks/explore-router.sh` |
| read-once 5분 윈도우 | 동일 파일 재읽기 차단 → 5분 윈도우 내 1회로 완화 | 운영 피드백 | `hooks/read-once.sh` |
| SCRUB env 제거 | 환경변수 스크러빙 훅이 정상 값도 제거하는 문제 해소 | P-확인 후 제거 | `hooks/`, `settings.json` |

---

## 이후 변경 시 추가 규칙

1. 이 파일 상단에 새 블록을 추가합니다 (최신이 위).
2. 표 형식 유지: 날짜 / 항목 / 내용 / 근거 / 영향 파일.
3. 하네스 파일 수정 시 반드시 이 파일도 동시에 업데이트합니다 (`rules/quality.md` Design Doc Sync 참조).
4. 옵시디언 설계 문서도 동기화합니다: `$OBSIDIAN_VAULT/01-jamesclaw/harness/harness_design.md`

변경 이력 없이 하네스를 수정하면 다음 세션에서 맥락을 잃어 재조사 비용이 발생합니다.
