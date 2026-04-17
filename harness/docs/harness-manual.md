# JamesClaw Agent Harness — 사용 매뉴얼

> 버전: 2026-04-15 | Claude Code v2.1.110 | 하네스 위치: `D:/jamesclew/harness/`

---

## 목차

1. [개요](#1-개요)
2. [아키텍처 다이어그램](#2-아키텍처-다이어그램)
3. [슬래시 커맨드 (Skills)](#3-슬래시-커맨드-skills)
4. [Hook 시스템](#4-hook-시스템)
5. [Rules (품질 규칙)](#5-rules-품질-규칙)
6. [멀티모델 오케스트레이션](#6-멀티모델-오케스트레이션)
6-1. [Agent Teams](#6-1-agent-teams-v21107)
7. [스크립트](#7-스크립트)
8. [MCP 서버](#8-mcp-서버)
9. [외부 도구 연동](#9-외부-도구-연동)
10. [블로그 파이프라인](#10-블로그-파이프라인)
11. [디자인 파이프라인](#11-디자인-파이프라인)
12. [환경변수 & 설정](#12-환경변수--설정)
13. [트러블슈팅](#13-트러블슈팅)
14. [버전 히스토리](#14-버전-히스토리)

---

## 1. 개요

### 하네스란?

JamesClaw Agent Harness는 Claude Code 위에서 동작하는 **자율 실행 에이전트 프레임워크**다. Claude Code의 Hook 시스템을 활용하여 에이전트의 모든 행동에 품질 게이트, 비용 추적, 외부 모델 교차검수를 자동으로 적용한다.

4개 레이어로 구성된다:

- **hooks/**: 에이전트 행동 전후에 자동 실행되는 감시·강제 스크립트 (28개)
- **rules/**: 에이전트가 따르는 품질·아키텍처·보안·디자인 규칙 (4개)
- **commands/**: `/blog-pipeline`, `/qa` 등 슬래시 커맨드로 호출하는 자동화 워크플로우 (12개)
- **scripts/**: 재사용 가능한 자동화 유틸리티 (11개)

Anthropic Harness Ablation 연구(2026-04) 기반의 **Planner-Generator-Evaluator 3-에이전트 구조**를 구현한다.

### 핵심 철학 3줄

1. **Ghost Mode**: "할까요?" 금지. 즉시 실행. 선언 후 미실행 패턴은 Hook이 자동 차단.
2. **Evidence-First**: 도구 출력 증거 없이 "확인했습니다" 보고 금지. Hook이 강제.
3. **Generator ≠ Evaluator**: 자기 검수 편향 차단. 생성한 모델이 직접 검수하지 않고 외부 모델(Codex/GPT-4.1)이 평가.

부가 철학: **Build to Delete** — 모델이 강해지면 하네스 요소를 ablation 테스트로 제거한다. 불필요한 훈련바퀴는 없다.

### 설치

```bash
# 새 머신 최초 설치
bash harness/install.sh

# 편집 후 ~/.claude/ 반영 (일상적인 배포)
bash harness/deploy.sh

# 완전 초기화 (기존 설정 백업 후 재설치)
bash harness/scripts/reset-and-install.sh
```

`deploy.sh`가 배포하는 항목: `CLAUDE.md`, `settings.json`, `rules/`, `hooks/`, `scripts/`, `agents/`, `commands/`, `PITFALLS.md`

---

## 2. 아키텍처 다이어그램

### 전체 구조

```
┌─────────────────────────────────────────────────────────────┐
│                        대표님                                │
│               (터미널 또는 텔레그램 채널)                     │
└───────────────────────┬─────────────────────────────────────┘
                        │ 요청
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                   Claude Code (Opus / opusplan)              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ SessionStart │  │UserPromptHook│  │  Stop Hook       │   │
│  │ session-start│  │user-prompt.ts│  │  stop-dispatcher │   │
│  │ .ts          │  │              │  │  .sh             │   │
│  └──────────────┘  └──────────────┘  └──────────────────┘   │
└───────┬─────────────────────┬──────────────────────┬────────┘
        │ PreToolUse           │ 도구 실행             │ PostToolUse
        ▼                     ▼                      ▼
┌───────────────┐    ┌─────────────────┐    ┌───────────────────┐
│ Pre-Hooks     │    │   도구 실행      │    │ Post-Hooks        │
│ ·시크릿보호   │    │ Read/Write/Edit  │    │ ·변경추적          │
│ ·빌드전환강제 │    │ Bash/Grep/Glob   │    │ ·회귀감지          │
│ ·Tavily기본값 │    │ MCP 도구들       │    │ ·비용추적          │
│ ·배포전증거   │    │                  │    │ ·루프감지          │
│ ·비가역경보   │    └─────────────────┘    │ ·교차검수강제      │
└───────────────┘                           └───────────────────┘
                                                     │
                        ┌────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                  외부 모델 교차검수                           │
│  ┌───────────────┐  ┌───────────────┐  ┌─────────────────┐  │
│  │  Codex CLI    │  │  GPT-4.1      │  │  Gemma 4 로컬   │  │
│  │  (6계정 로테) │  │  (copilot-api)│  │  Ollama:11434   │  │
│  └───────────────┘  └───────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                                │
                        ┌───────┘
                        ▼
          텔레그램 알림 (완료/에러/비가역명령)
```

### MCP 서버 구분

```
상시 연결 (settings.json 등록)
├── perplexity      — 웹 리서치 (4개 도구)
├── tavily          — 크롤링/검색 (5개 도구, 6키 로테이션)
└── telegram        — 채널 수신/발신

온디맨드 (작업 후 remove 필수)
├── stitch          — Google AI UI 디자인 생성
├── stitch-design-audit — 디자인 Tailwind 일관성 검사
└── korean-law      — 한국 법령 조회 (89도구, 상시 금지)
```

### 파일 구조 트리

```
D:/jamesclew/harness/
├── CLAUDE.md              # 글로벌 에이전트 규칙
├── settings.json          # Claude Code 설정 (hooks, MCP, 권한)
├── PITFALLS.md            # 반복 실수 기록 (P-001 ~ P-012)
├── deploy.sh              # ~/.claude/ 배포
├── install.sh             # 새 머신 1-command 설치
│
├── rules/                 # 상세 규칙 (4개)
│   ├── quality.md
│   ├── architecture.md
│   ├── security.md
│   └── design_rubric.md
│
├── hooks/                 # Hook 스크립트 (28개)
│   ├── *.sh               # 25개 bash 스크립트
│   └── *.ts               # 3개 TypeScript (curation, session-start, user-prompt)
│
├── commands/              # 슬래시 커맨드 정의 (12개)
│   ├── blog-pipeline.md
│   ├── qa.md
│   └── ...
│
├── scripts/               # 자동화 유틸리티 (11개)
│   ├── codex-rotate.sh
│   ├── evaluator.sh
│   └── ...
│
├── agents/                # 서브에이전트 정의 (3개)
│   ├── code-reviewer.md
│   ├── content-writer.md
│   └── researcher.md
│
├── mcp/                   # MCP 서버
│   └── stitch-design-audit/
│
└── docs/                  # 매뉴얼 문서
    ├── harness-manual.md  # 이 파일
    ├── gbrain-manual.md
    ├── managed-agent-manual.md
    └── ralph-loop-manual.md
```

---

## 3. 슬래시 커맨드 (Skills)

커맨드는 `~/.claude/commands/`에 위치한 Markdown 파일로 정의된다. Claude Code에서 `/커맨드명`으로 호출.

### 블로그 카테고리

| 커맨드 | 설명 | 핵심 동작 |
|--------|------|----------|
| `/blog-generate` | 키워드 → SEO 초안 자동 생성 | Perplexity/Tavily 리서치 → 초안 작성 → 팩트 검증 → 이미지 선택 |
| `/blog-review` | 생성된 초안 품질 게이트 검증 | expect MCP 7단계 + 외부 모델 AI냄새 검사 + SEO 점수 |
| `/blog-fix` | 품질 실패 초안 자동 수정 | 최대 3회 자동 수정, 매회 다른 모델 사용, 3회 실패 시 텔레그램 에스컬레이션 |
| `/blog-publish` | 검증된 초안 Firebase 발행 | `scripts/blog-publish.sh` 호출 → `firebase deploy` → HTTP 200 확인 |
| `/blog-pipeline` | 위 4단계 전체 파이프라인 | `/blog-generate` → `/blog-review` → `/blog-fix`(필요 시) → `/blog-publish` |

**자동화 예시:**
```bash
# 6시간마다 자동 발행
/loop 6h /blog-pipeline "무선 이어폰 추천 2026"
```

### 품질 카테고리

| 커맨드 | 설명 | 핵심 동작 |
|--------|------|----------|
| `/pipeline-install` | 현재 프로젝트에 11단계 품질 파이프라인 설치 | 프로젝트 유형 자동 감지 후 맞춤 구성 |
| `/pipeline-run` | 설치된 파이프라인 실행 (루프) | FAIL 시 자동 수정 → 재실행 반복 |
| `/qa` | 배포 결과물 외부 모델 QA 루프 | Codex/GPT-4.1/Gemini 사용자 관점 평가 → 수정 → 재평가 반복 |
| `/audit` | 세션 하네스 준수 감사 | `audit-session.sh` 실행, 33개 항목 리포트 |

**사전 조건:** `/pipeline-run` 실행 전 반드시 `/pipeline-install` 먼저 실행.

### 디자인 카테고리

| 커맨드 | 설명 | 핵심 동작 |
|--------|------|----------|
| `/design-review` | Vision 기반 디자인 리뷰 | Stitch 생성 스크린샷을 Opus Vision으로 분석 → 색상/레이아웃/UX/타이포그래피 개선안 도출 → Stitch `edit_screens` 자동 반영 |

### 인프라/기타 카테고리

| 커맨드 | 설명 | 핵심 동작 |
|--------|------|----------|
| `/prd` | PRD 생성 | 아이디어 한 줄 → 완성된 Product Requirements Document |
| `/cost` | API 비용 요약 | `~/.harness-state/api_cost_log.jsonl` 집계 |
| `/저장` | 세션 저장 + compact | Obsidian Vault 저장 → `/compact` (compact 전 반드시 실행) |

---

## 4. Hook 시스템

Hook은 Claude Code의 특정 이벤트 시점에 자동 실행되는 스크립트다. `settings.json`에 등록된다.

### Hook 종류 및 실행 시점

| Hook 타입 | 실행 시점 | 주요 용도 |
|-----------|----------|----------|
| `PreToolUse` | 도구 실행 직전 | 차단, 경고 주입 |
| `PostToolUse` | 도구 실행 직후 | 검증, 추적, 알림 |
| `PreCompact` | compact 실행 직전 | 스냅샷 저장, 감사 |
| `PostCompact` | compact 완료 직후 | 알림, 세션 재초기화 |
| `Stop` | Claude 응답 완료 후 | 패턴 감지, 최종 검증 |
| `SessionStart` | 세션 시작/재개 시 | 맥락 주입, 알림 |
| `UserPromptSubmit` | 사용자 입력 수신 시 | 기억 주입, 규칙 리마인더 |
| `SubagentStop` | 서브에이전트 종료 시 | 결과물 URL/링크 검증 |

### PreToolUse 훅 목록

| 매처(Matcher) | 스크립트 | 동작 |
|---------------|---------|------|
| `Write\|Edit` | 인라인 시크릿 보호 | `.env`/`.pem`/`.key` 파일 수정 차단 |
| `Write\|Edit` | `verify-memory-write.sh` | 메모리 파일 내 URL 환각 방지 검증 |
| `Write\|Edit` | `enforce-build-transition.sh` | `prd_done` + `pipeline_installed` 증거 없으면 빌드 차단 |
| `mcp__tavily__.*` | `tavily-guardrail.sh` | `search_depth=basic`, `max_results≤5` 기본값 강제 |
| `Bash` (git commit) | `quality-gate.sh pre-commit` | 커밋 전 테스트 실행 여부 확인 |
| `Bash` (git commit) | `pre-commit-conventional.sh` | Conventional Commits 형식 위반 시 커밋 차단 (한국어 scope 허용) |
| `Bash` | `irreversible-alert.sh` | 비가역 명령어 감지 → 텔레그램 알림 (차단 아님) |
| `Bash` | `bash-tool-blocker.sh` | `find`→Glob, `grep`→Grep, `cat`→Read 강제 |
| `Bash` (firebase deploy) | `verify-deploy.sh` | Step5/Step7 증거 파일 없으면 배포 차단 |

### PostToolUse 훅 목록

| 매처(Matcher) | 스크립트 | 동작 |
|---------------|---------|------|
| `Bash` (firebase deploy) | `verify-deploy.sh` | 배포 후 HTTP 200 응답 확인 |
| `Bash` (firebase deploy) | `enforce-review.sh` | 외부 모델(GPT-4.1+Codex) 검수 리마인더 주입 |
| `Bash` | `error-telegram.sh` | non-zero exit 시 텔레그램 에러 알림 |
| `Bash` | `loop-detector.sh` | 동일 도구+파라미터 3회+ 반복 감지 → 알림 |
| `Bash` | `log-filter.sh` | 로그 50줄+ 시 error/warn/fail 줄만 필터링 |
| `Bash` | `cost-tracker.sh` | API 비용 `api_cost_log.jsonl`에 로깅 |
| `Bash` | `quality-gate.sh post-test` | 테스트 후 품질 체크 |
| `Write\|Edit` | `post-edit-dispatcher.sh` | change-tracker + regression-guard + test-manipulation-guard 통합 실행 |
| `Write\|Edit` | `enforce-cross-review.sh` | 블로그 초안(`drafts/`) 저장 시 교차검수 리마인더 |
| `Read` | `read-once.sh` | 동일 파일 재읽기 경고 (차단 아님) |
| `Read\|Grep\|Glob\|Bash\|Edit\|Write` | `explore-router.sh` | 직접 작업 25회+ 누적 시 서브에이전트 위임 권고 |
| `mcp__perplexity__.*\|mcp__tavily__.*` | `cost-tracker.sh` | 외부 API 비용 추적 |
| `WebFetch\|WebSearch` | `loop-detector.sh` | 반복 루프 감지 |

### 기타 훅 목록

| Hook 타입 | 스크립트 | 동작 |
|-----------|---------|------|
| `PreCompact` | `pre-compact-snapshot.sh` | git state + 작업 상태 Markdown 스냅샷 저장 |
| `PreCompact` | `audit-session.sh --compact` | 세션 감사 요약 생성 |
| `PreCompact` | `self-evolve.sh --apply` | 피드백 분석 → 규칙 자동 업데이트 |
| `PreCompact` | `curation.ts` | 메모리 큐레이션 트리거 |
| `PreCompact` | `gbrain sync` | 레포 gbrain 동기화 |
| `PostCompact` | `telegram-notify.sh compact` | compact 완료 텔레그램 알림 |
| `PostCompact` | `session-start.ts` | 세션 프라이머 재주입 |
| `Stop` | `stop-dispatcher.sh` | `enforce-execution` + `evidence-first` + `check_declare_execute_ratio` + `check_review_evidence` + `check_skill_candidate` 등 8개 검증 통합 |
| `SessionStart` | `telegram-notify.sh start` | 세션 시작 텔레그램 알림 |
| `SessionStart` | `session-start.ts` | 과거 맥락 검색 + 핵심 규칙 주입 |
| `UserPromptSubmit` | `user-prompt.ts` | 관련 기억 주입 + 10턴마다 규칙 리마인더 |
| `UserPromptSubmit` | `user-prompt-declare-warn.sh` | 직전 턴 선언-미실행 패턴 감지 시 경고 주입 |
| `SubagentStop` | `verify-subagent.sh` | 서브에이전트 출력의 URL/GitHub 링크 존재 검증 |

### stop-dispatcher.sh 내장 검증 함수

`stop-dispatcher.sh`는 단일 Stop 훅으로 여러 검증을 순차 실행하는 디스패처다. 현재 8단계를 실행한다.

| 순서 | 함수/스크립트 | 유형 | 동작 |
|------|--------------|------|------|
| 1 | `enforce-execution.sh` | 차단 가능 | 실행 의도 없는 응답 차단 |
| 2 | `evidence-first.sh` | 차단 가능 | 증거 없는 완료 보고 차단 |
| 3 | `self-evolve.sh --apply` | 비차단 (백그라운드) | 피드백 분석 → 규칙 자동 업데이트 |
| 4 | `curation.ts` | 비차단 (백그라운드) | 메모리 큐레이션 |
| 5 | `telegram-notify.sh done` | 비차단 (백그라운드) | `last_result.txt` 내용 텔레그램 전송 |
| 6 | `check_declare_execute_ratio` | systemMessage | 선언만 하고 도구 호출 없는 패턴(P-declare_no_execute) 감지 |
| 7 | `check_review_evidence` | systemMessage | 검수 완료 선언 후 수치/근거 없는 패턴(skip_review) 감지 |
| 8 | `check_skill_candidate` | systemMessage | 20회+ 도구 호출 세션에 스킬 저장 권고 |

**check_declare_execute_ratio:** "반영합니다", "구현합니다" 등 선언 패턴이 있는데 도구 호출이 0건이면 `[DECLARE-NO-EXEC]` 경고를 주입하고 `declare_no_exec_flag` 파일을 생성한다. 다음 턴 `user-prompt-declare-warn.sh`가 이 플래그를 감지하여 "[DECLARE-RECUR] 즉시 도구 호출로 시작하세요" 메시지를 주입한다. 플래그는 5분 후 자동 만료.

**check_review_evidence:** "검수 완료", "PASS", "통과" 등 검수 선언 패턴이 있는데 수치 점수(`N/10`, `N점`), 항목별 PASS/FAIL 목록, 200자 이상 근거 중 하나도 없으면 `[SKIP-REVIEW]` 경고를 주입한다.

### v2.1.105 PreCompact Blocking

`pre-compact-snapshot.sh`가 Obsidian Vault 저장에 실패하면 `exit 2`를 반환하여 compact 자체를 차단한다. 저장 없이 compact가 진행되어 컨텍스트가 소실되는 사고(P-007)를 방지한다.

**compact 전 체크리스트:**
1. `/저장` 커맨드 실행 → Obsidian 저장 확인
2. `OBSIDIAN_VAULT` 환경변수 설정 확인
3. PreCompact hook 성공 확인 → compact 진행

---

## 5. Rules (품질 규칙)

규칙 파일은 `~/.claude/rules/`에 위치하며 에이전트가 항상 참조한다.

### quality.md — 품질 검증 규칙

**코드 변경 순서:** 코드 변경 → 테스트 실행 → 빌드 성공 → 커밋. 이 순서를 건너뛰면 Hook이 경고를 주입한다.

**Multi-Pass Review:** 결과물이 대표님께 보고되기 전 다단계 검토를 강제한다.

콘텐츠(블로그) 검토 6개 패스:

| Pass | 관점 | 통과 기준 |
|------|------|----------|
| 1 | 구조 | H2/H3 계층, 도입-본문-결론 흐름 정상 |
| 2 | SEO | 핵심 키워드 3회+, FAQ 2개+ |
| 3 | 독자 관점 | AI냄새 0 |
| 4 | 사실 검증 | 가격/스펙/링크 오류 0건 |
| 5 | 이미지/미디어 | 모든 제품에 이미지 존재 |
| 6 | 경쟁 대비 | 차별 포인트 1개+ |

최소 2라운드 반복 필수. 2라운드 연속 수정 0건이면 완료.

**가드 훅 3종:**

| 가드 | 감지 패턴 | 동작 |
|------|----------|------|
| Test Manipulation Guard | 테스트 파일만 수정, 소스 파일 미수정 | "테스트 조작 ALERT" 경고 주입 |
| Change Tracker | 50개+ 파일 수정 | 스코프 크리프 경고 |
| Regression Guard | 삭제 > 추가 2배 AND 삭제 10줄+ | 회귀 위험 경고 |

### architecture.md — 도구 및 아키텍처 규칙

**도구 우선순위 (비용 효율순):**
```
외부 모델(Codex/GPT-4.1/Gemma4, 5H=0) > 서브에이전트(Sonnet) > Built-in > Bash > MCP
```

**Perplexity 도구 선택 가이드:**

| 도구 | 단가 | 사용 시점 |
|------|-----|----------|
| `perplexity_search` | ~$0.006/회 | URL/목록 검색. 기본 선택 |
| `perplexity_ask` | ~$0.03/회 | 빠른 팩트 답변 |
| `perplexity_reason` | ~$0.02/회 | 단계별 추론 필요 시 |
| `perplexity_research` | ~$0.80/회 | 딥 리서치. `search` 대비 133배 비용 — 명시 요청 시만 |

**Tavily 강제 기본값:** `search_depth="basic"`, `max_results=5`. 평균 11.6KB/회로 도구 중 최대 토큰 소비.

**Tool Budget:** MCP 도구 50개 이하 유지. 230개+에서 서브에이전트 실패 발생.

### security.md — 보안 규칙

- 소스 코드에 시크릿 직접 작성 금지. 반드시 환경변수(`$VAR`) 사용.
- `.env`, `credentials`, `*.pem`, `*.key` 파일 수정 시 Hook이 자동 차단.
- `rm -rf`, `format`, `del /s/q` — deny list 등록, 실행 차단.

### design_rubric.md — 디자인 평가 기준

출처: Anthropic Harness Ablation 연구 (Opus 4.6, 2026-04). `/qa` Evaluator가 참조하는 채점 기준.

**4대 평가축 (각 0-10점):**

| 축 | 이름 | 핵심 질문 | Claude 약점 |
|----|------|----------|------------|
| 1 | Consistency (일관성) | CSS 토큰 체계가 통일되는가? | 약점 |
| 2 | Originality (독창성) | AI 클리셰에서 벗어났는가? | 가장 큰 약점 |
| 3 | Polish (완성도) | Typography/대비/간격 리듬이 완벽한가? | 약점 |
| 4 | Functionality (기능성) | 모든 인터랙션이 목적이 있는가? | 강점 |

**AI 클리셰 블랙리스트 (발견 즉시 -3점):**
- `bg-gradient-to-r from-purple-500 to-pink-500` 계열
- 대형 blur circle 배경 장식
- "Get Started" + 이메일 입력 히어로 섹션 템플릿
- 3-column feature grid with generic icons
- Lucide/Heroicons만 사용 (커스텀 일러스트 0)

**통과 기준:** 4개 축 모두 8점 이상. 한 축이라도 5점 이하면 FAIL.

자동 평가: `bash harness/scripts/evaluator.sh <URL>`

---

## 6. 멀티모델 오케스트레이션

### 모델 풀

| 모델 | 호출 방법 | 강점 | 주요 용도 |
|------|----------|------|----------|
| Sonnet 서브에이전트 | `Agent(model: "sonnet")` | 풀 도구 접근, 파일 편집 | 코딩, 탐색, 배포 |
| Codex CLI | `bash harness/scripts/codex-rotate.sh "프롬프트"` | 독립적 코드 관점 | 코드 리뷰, 설계 평가 |
| GPT-4.1 | `curl http://localhost:4141/v1/chat/completions` | 콘텐츠 톤, AI냄새 감지 | 콘텐츠 리뷰, 차별화 분석 |
| Gemma 4 로컬 | Ollama API (`localhost:11434`) | 무제한, 오프라인 | 벌크 작업, 최종 폴백 |
| GLM-5.1 클라우드 | `ollama run glm-5.1:cloud` | 무료, 고성능 | 수동 호출만 (cloud=과금 리스크) |

**주의:** GPT-4.1은 copilot-api 프록시(`localhost:4141`) 경유. copilot-api 서버 실행 필수 (`copilot-api start --port 4141 &`).

### 작업→모델 라우팅 표

| 작업 유형 | 1순위 모델 | 교차 검증 |
|-----------|-----------|----------|
| 코드 작성/수정 | Sonnet 서브에이전트 | Codex 리뷰 |
| 코드 리뷰 | Codex + GPT-4.1 병렬 | 의견 불일치 시 Opus 판단 |
| 콘텐츠(블로그) 리뷰 | GPT-4.1 | Codex 보조 |
| AI냄새 검사 | GPT-4.1 | — |
| 웹 리서치 | Sonnet (researcher 에이전트) | — |
| 탐색/검색 | Sonnet (Explore 모드) | — |
| 배포/빌드 | Sonnet (general-purpose) | — |
| 설계 평가 | Codex + GPT-4.1 | 다수결 |
| 벌크/반복 작업 | Gemma 4 로컬 | — |

### 5H 비용 최적화 전략

**5H 롤링 윈도우는 모든 Claude 모델에서 공통 소비된다.**

| 모델 | 5H 소비 | 7D 소비 | 추천 용도 |
|------|---------|---------|----------|
| Codex / GPT-4.1 / Gemma4 | **0** | **0** | 코드 리뷰, 외부 검수 — 최우선 |
| Sonnet 서브에이전트 | 소비 (느림) | Sonnet 풀 | 도구 필요한 코딩/배포 |
| Opus 직접 | 소비 (빠름) | Opus 풀 | 판단, 커밋, 짧은 대화만 |

**권장 모드:** `/model opusplan` — Plan(설계)=Opus, 실행=Sonnet 자동 분리. Opus 7D 풀 보존.

**위임 기준:**
- 파일 읽기 2개+, 코드 수정, 검색 3회+, 리서치 → 서브에이전트 또는 외부 모델
- Opus 직접 수행: 단일 파일 읽기/수정, 대화, 최종 판단, 커밋

### 80%+ 비상 모드

5H 사용량 80%+ 감지 시 자동 전환:

1. Opus 응답을 최대 2문장으로 제한
2. 모든 도구 호출을 Sonnet 서브에이전트로 위임 (Opus 직접 호출 금지)
3. 대표님께 "5H 80%+, Sonnet 위임 모드" 고지
4. 리밋 해제 후 `/model opus`로 복귀

현재 5H 사용량 확인: `telegram-notify.sh heartbeat`

---

## 6-1. Agent Teams (v2.1.107+)

### 개요

Agent Teams는 teammate 간 메시지 교환과 태스크 조율이 필요한 복잡한 병렬 작업에 사용한다. 단순히 결과를 반환하는 서브에이전트와 달리, teammate끼리 `SendMessage`로 소통하며 작업을 나눈다.

**서브에이전트 vs Agent Teams 판단 기준:**

| 상황 | 선택 |
|------|------|
| 결과값만 반환하면 충분 | 서브에이전트 (`Agent(model: "sonnet")`) |
| teammate 간 대화/태스크 조율 필요 | Agent Teams |
| 리뷰어-작성자-검증자 역할 분리 | Agent Teams |
| 멀티 프로젝트 병렬 처리 | Agent Teams |

### 핵심 도구

| 도구 | 용도 |
|------|------|
| `TaskCreate` | 작업 항목 생성 (subject, description) |
| `TaskUpdate` | 작업 상태 변경 (pending→in_progress→completed), 소유자 지정 |
| `TaskList` | 전체 작업 목록 조회. 낮은 ID 우선 처리 |
| `TaskGet` | 특정 작업 상세 조회 |
| `SendMessage` | teammate에게 메시지 전송. `to: "이름"` 또는 `to: "*"` (전체) |

**작업 클레임 패턴:**
```
1. TaskList로 pending 작업 확인
2. TaskUpdate(taskId, owner="내이름", status="in_progress")로 클레임
3. 작업 완료 후 TaskUpdate(taskId, status="completed")
4. SendMessage로 다음 teammate에게 통보
```

### 모델 구성

| 역할 | 모델 | 비용 |
|------|------|------|
| 팀 리드 (오케스트레이터) | Opus | 5H 소비 |
| 구현 teammate | Sonnet (`model: sonnet`) | Sonnet 풀 |
| 리뷰 teammate (GPT 경유) | HydraTeams 프록시 (`localhost:3456`) | 5H 0 |

### HydraTeams 프록시

Agent Teams teammate를 GPT-4o-mini 등 외부 모델로 라우팅하는 프록시 서버.

```bash
# 시작 (HydraTeams 디렉토리에서)
node dist/index.js --model gpt-4o-mini --provider openai --port 3456 --passthrough lead
```

- **위치:** `/tmp/HydraTeams/`
- **포트:** 3456 (copilot-api `4141`과 구분)
- **역할 분리:** copilot-api(`4141`) = 단일 API 검수 호출 / HydraTeams(`3456`) = Agent Teams teammate 전용

### in-process 모드

tmux 없이 Windows Terminal에서 바로 동작한다.
- `Shift+Down`: teammate 전환
- 팀 설정 파일: `~/.claude/teams/{팀명}/config.json`

### gbrain 자율 저장 규칙

gbrain은 단순 조회용이 아니라 **지식이 발생하는 즉시 저장**하는 것이 원칙이다.

**자동 저장 트리거 (조건 충족 시 즉시 `gbrain put` 실행):**

| 조건 | 저장 내용 |
|------|----------|
| 새로운 도구/기법 발견 | 설치법, 사용법, 주의사항 |
| 디버깅 핵심 원인 발견 | 증상 → 원인 → 해결 3줄 |
| 외부 API/서비스 연동 확인 | 엔드포인트, 인증, 제약조건 |
| 대표님 "기억해" / "저장해" 요청 | 즉시 저장 |

**저장 방법:**
```bash
# CLI
gbrain put <slug> < file.md

# MCP
mcp__gbrain__put_page(slug="...", content="...")
```

**Search-Before-Solve 순서:** 막히면 gbrain query → PITFALLS → Obsidian → 이전 세션 순서로 검색 후 해결 시도.

---

## 7. 스크립트

스크립트 위치: `harness/scripts/` → 배포 후 `~/.claude/scripts/`

| 스크립트 | 용도 | 사용법 |
|---------|------|--------|
| `audit-session.sh` | 세션 하네스 준수 33개 항목 감사 | `bash audit-session.sh --full` / `--compact` |
| `blog-publish.sh` | 초안 → HTML 빌드 → Firebase 배포 | `bash blog-publish.sh MultiBlog/drafts/{slug}/` |
| `codex-rotate.sh` | Codex 멀티계정 자동 로테이션 (최대 6개), Gemma4 폴백 | `bash codex-rotate.sh "프롬프트"` |
| `evaluator.sh` | expect MCP/node 스크린샷 + 외부 모델 디자인 등급 평가 (Generator와 분리) | `bash evaluator.sh <URL>` |
| `fix-statusline.sh` | Windows에서 awesome-statusline 5H/7D N/A 수정 | `bash fix-statusline.sh` |
| `log-api-cost.sh` | 외부 API 비용 수동 로깅 | `bash log-api-cost.sh perplexity sonar 0.80 "리서치 목적"` |
| `ollama-accounts-setup.sh` | Ollama 계정 로테이션 디렉토리 초기화 | `bash ollama-accounts-setup.sh` |
| `ollama-cloud-rotate.sh` | Ollama 클라우드 계정 키 로테이션 래퍼 | `bash ollama-cloud-rotate.sh "프롬프트"` |
| `reset-and-install.sh` | 전체 초기화 (기존 설정 백업 → 재설치) | `bash reset-and-install.sh` |
| `self-evolve.sh` | 피드백 로그 분석 → 하네스 규칙 자동 업데이트 | `bash self-evolve.sh` (dry run) / `--apply` (적용) |
| `tavily-rotator.mjs` | Tavily MCP 키 자동 로테이션 (6키, 429 시 전환) | MCP 서버로 자동 호출 (직접 실행 불필요) |
| `managed-blog-agent.py` | Managed Agent 블로그 파이프라인 비동기 실행 | `python managed-blog-agent.py setup` / `run "키워드"` |

**Managed Agent 비용 참고:** 블로그 1건 ≈ $0.37 (세션 런타임 $0.08/시간 + 토큰 비용)

### Monitor 도구 (v2.1.98+)
백그라운드 스크립트의 stdout 이벤트를 실시간 스트리밍하는 도구. `Bash(run_in_background: true)`로 시작한 프로세스의 출력을 `Monitor(id)`로 수신.

활용 시나리오:
- Ralph Loop 진행 상태 모니터링
- Firebase deploy 완료 감지
- 장시간 빌드/테스트 실시간 추적

---

## 8. MCP 서버

### 상시 연결 MCP

| 서버 | 등록 명령 | 도구 수 | 주요 용도 |
|------|----------|---------|----------|
| perplexity | `claude mcp add perplexity -s user -- npx -y server-perplexity-ask` | 4개 | 웹 리서치, 팩트 확인 |
| tavily | `claude mcp add tavily -s user -- node ~/.claude/scripts/tavily-rotator.mjs` | 5개 | 크롤링, 원문 추출 (6키 로테이션) |
| telegram | `enabledPlugins`에 등록 | 4개 | 채널 메시지 수신/발신 |

### 온디맨드 MCP (작업 후 반드시 remove)

| 서버 | 등록 명령 | 도구 수 | 사용 후 제거 |
|------|----------|---------|------------|
| stitch | `claude mcp add stitch -s user -- npx -y @_davideast/stitch-mcp proxy` | 12개+ | `claude mcp remove stitch` |
| stitch-design-audit | `claude mcp add stitch-design-audit -s user -- node harness/mcp/stitch-design-audit/audit.js` | 2개 | `claude mcp remove stitch-design-audit` |
| korean-law | `claude mcp add korean-law -s user -- cmd /c npx -y korean-law-mcp` | 89개 | `claude mcp remove korean-law` (상시 금지) |

**온디맨드 원칙:** Tool Budget 50개 이하 유지. `korean-law`는 89개 도구로 단독으로도 상한 초과 — 반드시 작업 후 즉시 remove.

### stitch-design-audit MCP 상세

- **목적:** ADR-008 "Design Dictatorship Protocol" 준수 검사기. Stitch로 생성한 디자인의 Tailwind 일관성 자동 검사.
- **위치:** `harness/mcp/stitch-design-audit/audit.js`
- **Tailwind v4** 컬러/radius/spacing 매핑 내장.

제공 도구 2개:

| 도구 | 설명 |
|------|------|
| `audit_design` | URL 기반 라이브 페이지 디자인 감사 |
| `audit_design_files` | 로컬 HTML/CSS 파일 직접 감사 |

---

## 9. 외부 도구 연동

### Obsidian Vault (세션 저장)

- **경로:** `C:/Users/AIcreator/Obsidian-Vault/`
- **용도:** 세션 상태 영구 저장, compact 전 스냅샷
- **설정:** 환경변수 `OBSIDIAN_VAULT=C:/Users/AIcreator/Obsidian-Vault`
- **저장 위치:**
  - `01-jamesclaw/harness/` — 하네스 설계, Phase 계획
  - `01-jamesclaw/research/` — 도구 선정, 리서치 결과
  - `02-projects/` — 프로젝트별 문서
  - `03-knowledge/` — 영구 지식
- **주의:** `OBSIDIAN_VAULT` 미설정 시 PreCompact hook이 실패하여 compact 차단됨.

#### 03-knowledge/ — 영구 지식 큐레이션

`03-knowledge/`는 프로젝트와 무관한 **범용·재사용 가능 지식**을 보관하는 공간이다.

**규칙:**
- 저장 대상: 도구 사용법, 디버깅 패턴, API 연동 방법, 외부 서비스 제약조건 등 어느 프로젝트에서도 쓸 수 있는 것
- 저장 제외: 특정 프로젝트(블로그, 위키 등) 전용 내용 → `02-projects/`에 저장
- **주 입력 경로:** `/wiki-sync` 커맨드로 gbrain에서 Obsidian으로 동기화 (`gbrain query` → 결과를 `03-knowledge/`에 저장)
- **수동 큐레이션도 허용:** gbrain에 저장하기 애매한 판단·설계 철학은 직접 마크다운으로 작성
- 파일명 컨벤션: `{YYYY-MM-DD}-{slug}.md` (날짜 + 슬러그)

**현재 비어있는 이유:** 자동 인제스트 파이프라인(wiki-sync)이 점진적으로 채운다. 억지로 채우지 않는다 — 반드시 판단이 필요한 수동 큐레이션이므로 일괄 자동 마이그레이션은 하지 않는다.

### Telegram (알림 채널)

- **알림 이벤트:** 세션 시작, Stop, compact, Bash 에러, 비가역 명령 실행
- **작업 완료 알림:** `echo "결과 요약" > ~/.harness-state/last_result.txt` → Stop hook 자동 전송
- **설정:**
  - `TELEGRAM_BOT_TOKEN=<봇 토큰>`
  - `TELEGRAM_CHAT_ID=<채팅 ID>`
- **텔레그램에서 요청 시:** reply 도구로 응답. 터미널 트랜스크립트는 텔레그램에 전달되지 않음.

### Firebase (호스팅)

모든 웹 프로젝트는 Firebase 기반으로 통일. WordPress 사용 금지.

| 서비스 | 용도 |
|--------|------|
| Firebase Hosting | 정적 사이트, SSG |
| Firestore | 콘텐츠 저장, CMS |
| Firebase Functions | 동적 API (필요 시) |
| Firebase Auth | 사용자 인증 (필요 시) |
| Firebase Storage | 미디어 파일 |

**배포 후 검증 필수:** 라이브 URL에 HTTP 200 응답 확인 후에만 대표님께 보고. Hook이 자동 강제.

### gbrain (영구 지식 베이스)

- **정의:** AI 에이전트용 PGLite(WASM 기반 Postgres) 로컬 지식 베이스
- **검색:** 하이브리드 (벡터 + 키워드 + RRF)
- **도구:** 30개+ MCP 도구
- **설치:** `bun add -g github:garrytan/gbrain`
- **MCP 연결:** `gbrain serve` → Claude Code에서 `claude mcp add gbrain ...`
- **확장 권장:** 1000개+ 파일 시 Supabase/Postgres 전환

---

## 10. 블로그 파이프라인

### 전체 흐름

```
키워드 입력
    │
    ▼
[/blog-generate] ──── Perplexity/Tavily 리서치
    │                  SEO 경쟁 분석
    │                  초안 생성 (Sonnet)
    │                  팩트 검증
    │                  쿠팡 이미지 캡처
    ▼
초안 (MultiBlog/drafts/{slug}/draft.md)
    │
    ▼
[/blog-review] ──────── expect MCP 7단계 검증
    │                    외부 모델 AI냄새 검사
    │                    SEO 점수 산출
    │
    ├── PASS ──────────────────────────────┐
    │                                      │
    └── FAIL ──► [/blog-fix] (최대 3회)   │
                  Round 1: Codex 수정      │
                  Round 2: GPT-4.1 수정   │
                  Round 3: Gemma4 수정     │
                  3회 실패: 텔레그램 에스컬레이션
                  PASS 시 ─────────────────┘
                                           │
                                           ▼
                                    [/blog-publish]
                                    draft.md → index.html 빌드
                                    firebase deploy
                                    HTTP 200 검증
                                    GPT-4.1 + Codex 검수
                                           │
                                           ▼
                                    텔레그램 발행 완료 알림
```

### 단계별 커맨드 매핑

| 단계 | 커맨드 | 출력 결과 |
|------|--------|---------|
| 1. 생성 | `/blog-generate "키워드"` | `MultiBlog/drafts/{slug}/draft.md` |
| 2. 검증 | `/blog-review` | PASS/FAIL + 개선 제안 |
| 3. 수정 | `/blog-fix` (자동, FAIL 시) | 수정된 `draft.md` |
| 4. 발행 | `/blog-publish` | `MultiBlog/public/{slug}/index.html` → Firebase |
| 전체 | `/blog-pipeline "키워드"` | 1-4 단계 자동 실행 |

### 이미지 수집 우선순위

1. og:image CDN URL → 800x800 직접 다운로드 (1순위)
2. expect MCP(mcp__expect__screenshot) persistent context (2순위)
3. agent-browser CDP (쿠팡 봇 차단 우회, 3순위)

**금지:** `loading="lazy"` 사용 금지 (P-001). 제조사 공식 이미지 사용 금지 (쿠팡 썸네일만).

---

## 11. 디자인 파이프라인

### 전체 흐름

```
디자인 요청
    │
    ▼
[MCP: stitch] ──── Stitch에서 UI 디자인 생성
(온디맨드 추가)     Google AI 기반, 무료 월 350회
    │
    ▼
스크린샷 캡처
    │
    ▼
[/design-review] ── Opus Vision으로 스크린샷 직접 분석
                     색상/레이아웃/UX/타이포그래피 개선안
                     Stitch edit_screens로 자동 반영
    │
    ▼
React 컴포넌트 생성 (Sonnet 서브에이전트)
    │
    ▼
[MCP: stitch-design-audit] ── Tailwind 일관성 감사
(온디맨드 추가)                audit_design_files 도구
    │
    ├── PASS: 배포 진행
    └── FAIL: 수정 → 재감사
    │
    ▼
[/qa] ── evaluator.sh로 design_rubric.md 4축 평가
         Codex + GPT-4.1 병렬 채점
         PASS: 4축 모두 8점 이상
```

### 작업 후 반드시 MCP 정리

```bash
claude mcp remove stitch
claude mcp remove stitch-design-audit
```

---

## 12. 환경변수 & 설정

### 필수/선택 환경변수

| 변수 | 필수 | 용도 |
|------|------|------|
| `PERPLEXITY_API_KEY` | 필수 | Perplexity MCP (4개 도구) |
| `TAVILY_API_KEY` | 필수 | Tavily MCP (6키 로테이션 시 `TAVILY_API_KEY_1`~`_6`) |
| `OBSIDIAN_VAULT` | 필수 | 세션 저장, PreCompact hook |
| `TELEGRAM_BOT_TOKEN` | 권장 | 텔레그램 알림 |
| `TELEGRAM_CHAT_ID` | 권장 | 텔레그램 알림 |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | 선택 | gh CLI |

환경변수 설정 위치: `~/.harness.env` (install.sh가 생성)

### settings.local.json — 민감 환경변수 관리

민감한 API 키는 `settings.json`(공유/커밋 가능)에 넣지 않고 `~/.claude/settings.local.json`에 분리 저장한다. Claude Code가 두 파일을 자동 병합하여 적용한다.

**위치:** `~/.claude/settings.local.json` (gitignore 대상)

**현재 관리 항목:**

| 변수 | 용도 |
|------|------|
| `OPENAI_API_KEY` | copilot-api(GPT-4.1) 호출 |
| `PERPLEXITY_API_KEY` | Perplexity MCP |
| `TAVILY_API_KEY` | Tavily MCP |
| `OBSIDIAN_VAULT` | 세션 저장 경로 (`C:/Users/AIcreator/Obsidian-Vault`) |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | gh CLI |

**형식 예시:**
```json
{
  "env": {
    "OPENAI_API_KEY": "sk-proj-...",
    "OBSIDIAN_VAULT": "C:/Users/AIcreator/Obsidian-Vault"
  }
}
```

**주의:** `settings.local.json`은 절대 git commit하지 않는다. `settings.json`에는 변수명만 참조하고 값은 넣지 않는다.

### State 파일 위치

모든 상태 파일은 `~/.harness-state/`에 저장된다.

| 파일 | 용도 |
|------|------|
| `session_changes.log` | 세션 내 변경 파일 추적 (change-tracker.sh) |
| `api_cost_log.jsonl` | API 비용 누적 로그 (/cost 커맨드 소스) |
| `pre-compact-snapshot.md` | compact 전 git state 스냅샷 |
| `step5_quality_done` | 품질루프 완료 증거 파일 (verify-deploy.sh 확인) |
| `step7_review_done` | 교차검수 완료 증거 파일 (verify-deploy.sh 확인) |
| `last_result.txt` | Stop hook 텔레그램 전송용 결과 요약 |

### settings.json 핵심 설정

```json
{
  "thinking": { "budget_tokens": 10000 },
  "permissions": { "defaultMode": "bypassPermissions" },
  "language": "korean",
  "skipDangerousModePermissionPrompt": true,
  "enabledPlugins": {
    "telegram@claude-plugins-official": true,
    "awesome-statusline@awesome-claude-plugins": true,
    "ralph-loop@claude-plugins-official": true
  },
  "statusLine": {
    "type": "command",
    "command": "~/.claude/awesome-statusline.sh"
  }
}
```

**awesome-statusline:** 5H/7D 사용량 + 비용 실시간 표시. Windows에서 N/A 표시 시 `bash fix-statusline.sh` 실행.

---

## 13. 트러블슈팅

### PITFALLS 주요 항목

| 코드 | 증상 | 해결법 |
|------|------|--------|
| P-001 | headless 브라우저에서 이미지 미로드 | `loading="lazy"` 전체 제거 |
| P-002 | 쿠팡 이미지에 UI 오버레이 캡처됨 | og:image CDN URL로 800x800 직접 다운로드 |
| P-003 | 쿠팡 제품 ID가 다른 모델을 가리킴 | Opus+Sonnet 교차 Vision 검증 |
| P-004 | Firestore ↔ 로컬 JSON 불일치 | JSON 수정 후 `createPost()`로 Firestore 동기화 필수 |
| P-005 | enforce-execution.sh 완료 보고 오탐 | 패턴을 미래형("~하겠습니다")만 감지하도록 변경 |
| P-006 | agent-browser 기본 모드로 쿠팡 접근 불가 | `launchPersistentContext` + `--disable-blink-features=AutomationControlled` |
| P-007 | compact 후 세션 저장하면 의미 없음 | compact 전(60-65%)에 `/저장` 먼저 실행 |
| P-008 | Context % 확인 불가라고 오보고 | `user-prompt.ts`의 `context_pct` 파일 참조 |
| P-009 | 5H/7D Usage 캐시 stale 미감지 | usage 보고 시 `resets_at` 현재 시각 비교 필수 |
| P-010 | MCP 끊김 시 재연결 없이 우회 | ① remove+add 재연결 ② invoke 재시도 ③ curl 직접 (최후) |
| P-011 | crossReview 텍스트 3000자 제한으로 글 잘림 | 5000자로 확대 |
| P-012 | 외부 모델 로테이션 규칙만 존재, 구현 없음 | `evaluator.sh`에 5단계 자동 로테이션 (codex→copilot_gpt→openrouter_free→gemma4_local→codex_backoff) |

### 에러 유형별 대응

| 에러 유형 | 증상 | 대응 |
|----------|------|------|
| 네트워크/타임아웃 | ETIMEDOUT, ECONNREFUSED | 3-5초 대기 후 재시도. 3회 실패 시 보고 |
| 인증/권한 | 401, 403, Access Denied | 재시도 무의미. 즉시 보고 (키/토큰 문제) |
| Rate Limit | 429, Too Many Requests | 지수 백오프 (5→15→45초). Tavily는 키 로테이션 |
| 쿠팡 봇 차단 | Access Denied | 방식 전환 (headless→CDP→og:image). 같은 방식 재시도 무의미 |
| 빌드/문법 에러 | SyntaxError, build fail | 에러 메시지 정독 → 수정 → 재빌드 |
| 외부 모델 실패 | Codex/Gemini timeout | 다른 모델로 대체. 3모델 중 2개 성공이면 진행 |

### 재시도 원칙

1. 에러 발생 → 최대 3회 재시도
2. 4번째 시도 = 같은 접근법 변형 금지 → 대표님께 보고
3. 재시도 후 상태 악화 → 즉시 중단 + 재설계 (하향 나선 금지)

### awesome-statusline N/A 해결

5H/7D가 N/A로 표시될 경우:
1. `bash ~/.claude/scripts/fix-statusline.sh` 실행
2. `~/.claude/cache/token_usage.json` 삭제 후 재시작
3. `telegram-notify.sh heartbeat`로 직접 확인

---

## 14. 버전 히스토리

### v2.1.110 (현재) — 2026-04-15

- Push notification tool: Remote Control 연동 모바일 푸시 알림 (`PushNotification` 도구)
- /tui fullscreen: 플리커 없는 전체화면 렌더링 (`/tui fullscreen` 또는 `tui` 설정)
- PreToolUse additionalContext 버그 수정: 도구 호출 실패 시 additionalContext 소실 방지
- MCP SSE 안정성: SSE/HTTP 전송 중 연결 끊김 시 무한 대기 버그 수정
- /focus 커맨드 추가: Ctrl+O는 verbose 토글 전용, focus 뷰는 /focus로 분리
- stdio MCP stray non-JSON line 연결 해제 버그 수정 (2.1.105 회귀)
- PermissionRequest updatedInput deny rule 재검사 버그 수정

### v2.1.108 (이전) — 2026-04-15

- 1시간 프롬프트 캐싱: `ENABLE_PROMPT_CACHING_1H` env var (BEDROCK 구버전 대체), `FORCE_PROMPT_CACHING_5M` 5분 TTL
- /recap 세션 복귀 요약: 세션 복귀 시 컨텍스트 요약 자동 표시. `/config`에서 설정, `CLAUDE_CODE_ENABLE_AWAY_SUMMARY`로 강제
- Skill 도구가 빌트인 슬래시 커맨드 호출 가능: `/init`, `/review`, `/security-review`
- `/undo` = `/rewind` 별칭. `/model` 전환 시 캐시 재읽기 경고
- `/resume` 기본값: 현재 디렉토리 세션. Ctrl+A로 전체 표시
- rate limit vs plan limit 에러 메시지 구분. 5xx 오류 시 status.claude.com 링크 표시
- 언어 문법 온디맨드 로딩으로 메모리 풋프린트 감소
- 각종 버그 수정 (paste /login, 텔레메트리 캐시, --resume 세션명, diacritical marks 등)

### v2.1.107 — 2026-04-15 (하네스 업데이트)

**Agent Teams 지원 (v2.1.107+)**
- TeamCreate/SendMessage/TaskList/TaskUpdate 도구로 teammate 간 태스크 조율
- HydraTeams 프록시(`localhost:3456`)로 GPT 모델을 teammate로 활용
- in-process 모드 기본: tmux 불필요, Windows Terminal에서 바로 동작

**stop-dispatcher.sh 강화**
- `check_declare_execute_ratio` 추가: 선언-미실행 패턴(P-declare_no_execute) 자동 감지
- `check_review_evidence` 추가: 검수 근거 없는 완료 선언(skip_review) 자동 감지
- `check_skill_candidate` 추가: 복합 세션 스킬 저장 권고

**신규 훅 2개**
- `user-prompt-declare-warn.sh`: 직전 턴 선언-미실행 플래그 감지 → 다음 턴 경고 주입 (5분 만료)
- `pre-commit-conventional.sh`: Conventional Commits 위반 커밋 차단 (한국어 scope 허용)

**audit-session.sh 확장**
- 27개 체크 항목 (기존 26개 + `check_rule_impl_gap` 추가)
- `check_rule_impl_gap`: 규칙 파일이 참조하는 hook/script 실제 존재 여부 검증 (P-012)

**settings.local.json 분리**
- 민감 API 키(OPENAI_API_KEY, PERPLEXITY_API_KEY, TAVILY_API_KEY, OBSIDIAN_VAULT)를 settings.local.json에 분리 관리

---

### v2.1.107 — 2026-04-14

**Thinking Hints 조기 표시**
- 긴 작업 중 thinking hint가 더 빨리 표시됨 (UI 개선)

### v2.1.105 — 2026-04-13

**PreCompact Hook Blocking**
- `pre-compact-snapshot.sh`가 Obsidian Vault 저장 실패 시 `exit 2` 반환
- compact 자동 차단 → P-007 재발 방지
- `OBSIDIAN_VAULT` 환경변수 미설정 시 compact 불가

**EnterWorktree 신규 파라미터**
- `EnterWorktree(path: "existing/worktree")` — 기존 worktree로 재진입 가능
- 에이전트 재시작 시 작업 연속성 유지

**WebFetch 개선**
- `<style>` / `<script>` 태그 자동 제거 → 토큰 효율 향상

**커맨드 별칭 추가**
- `/proactive` = `/loop` 별칭

### v2.1.101 — 2026-04-10 (하네스 핵심)

**[버그수정] 서브에이전트 MCP 도구 상속 수정**
- 온디맨드 MCP 서버(`claude mcp add`) 도구가 서브에이전트에 정상 상속됨
- Stitch, korean-law 등 온디맨드 MCP + Sonnet 서브에이전트 패턴 재활성화 가능

**[버그수정] Isolated Worktree 서브에이전트 파일 접근 수정**
- `isolation: "worktree"` 서브에이전트가 자신의 worktree 파일 Read/Edit 가능
- Parallel Agent Safety (#14) 패턴 안정화

**[보안] `permissions.deny` 우선순위 수정**
- PreToolUse hook의 `"ask"` 결정이 deny 규칙을 우회하던 버그 수정
- enforce-review.sh, verify-deploy.sh 등 deny 기반 hook 보안 강화

**신규 커맨드**
- `/team-onboarding` — 로컬 사용 패턴 기반 팀 온보딩 가이드 자동 생성

**`/ultraplan` 개선**
- 클라우드 환경 자동 생성 (사전 웹 설정 불필요)

### v2.1.98 — 2026-04-09

**Monitor 도구 추가**
- 백그라운드 스크립트 이벤트 실시간 스트리밍 수신 가능
- 향후 ralph-loop, evaluator.sh 모니터링에 활용 검토

**Bash 권한 보안 대폭 강화**
- backslash-escaped 플래그 bypass, 복합 명령 bypass, `/dev/tcp` 리다이렉트 등 다수 수정
- 기존 auto-allow 되던 일부 명령이 이제 프롬프트 요청할 수 있음

### 이전 주요 변경사항

| 버전/날짜 | 변경사항 |
|----------|---------|
| 2026-04-15 | Agent Teams 섹션 추가, stop-dispatcher 3함수 추가, 신규 훅 2개, audit 33체크(+6 추가), settings.local.json 분리 |
| 2026-04-13 | stitch-design-audit MCP 서버 추가 (ADR-008) |
| 2026-04-12 | enforce-cross-review 훅 추가 (블로그 초안 교차검수 강제) |
| 2026-04-11 | managed-agent-manual.md P-016/P-017 실수 학습 반영 |
| 2026-04-10 | opusplan 모드 권장 기본으로 승격 |
| 2026-04-08 | evaluator.sh 3단계 자동 로테이션 구현 (P-012 해결) |
| 2026-04-05 | design_rubric.md 추가 (Anthropic Harness Ablation 연구 기반) |

---

## 부록: 서브에이전트 정의

`harness/agents/`에 3개 서브에이전트가 정의되어 있다.

| 에이전트 | 모델 | 허용 도구 | 용도 |
|---------|------|----------|------|
| `code-reviewer` | sonnet | Read, Glob, Grep, Bash | 코드 품질/보안/성능 5축 검토. 출력 200단어 이내 |
| `content-writer` | opus | Read, Write, Edit, Bash, Tavily | 블로그/YouTube/SEO 콘텐츠 생성 (한국 시장) |
| `researcher` | sonnet | Read, Grep, Bash, Tavily, Perplexity | 웹 리서치. 학습 데이터 의존 금지, 출처 URL 필수 |

**호출 원칙:** `Agent(model: "sonnet")` 시 반드시 `model` 명시. 생략 시 Opus 풀 차감.

---

*이 매뉴얼은 하네스 변경 시 동시에 업데이트한다. 최신 소스는 `D:/jamesclew/harness/docs/.manual-data.md` 참조.*
