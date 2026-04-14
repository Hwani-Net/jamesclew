---
name: Harness Design Decisions
description: 하네스 설계 근거, 아키텍처 결정, 구현 상태 — settings.json 기준 진실의 원천
type: project
---

## 설계 원칙

### 핵심 원칙
- Built-in > Bash > MCP (비용순 도구 선택)
- Tool 50개 이하 유지 (230+에서 서브에이전트 실패)
- Perplexity는 검색(search)만, 분석/추론은 Opus가 직접
- effortLevel 자율 선택 (난이도에 따라 자동)
- 학습데이터 의존 금지 — 항상 현재시각 기준 최신 데이터 확인
- 품질 최우선 — 시간/컨텍스트 핑계로 타협 금지
- CLAUDE.md는 의도와 맥락, hooks는 반사신경 — 규칙은 hook으로 강제, CLAUDE.md는 한 줄 참조
- 컨텍스트 추측 금지 — 실제 수치(heartbeat) 확인 후 판단

---

## Tool 수 관리 (50개 제한)

| 소스 | Tool 수 | 비고 |
|------|---------|------|
| Built-in | 24 | Read, Write, Edit, Glob, Grep, Bash, Agent 등 |
| lazy-mcp | 4 | list_commands, describe_commands, invoke_command, list_servers |
| Telegram | 4 | 플러그인 (reply, react, edit_message, download_attachment) |
| desktop-control | 1 | computer-use-mcp (스크린샷, 마우스, 키보드) |
| **합계** | **33** | |

### lazy-mcp 내부 서버
| 서버 | 용도 |
|------|------|
| perplexity | 웹 검색 (search만) |
| tavily | 딥 리서치, 콘텐츠 추출 (6키 로테이션) |
| korean-law | 국가법령정보센터 API 법령 조회 |

### 온디맨드 MCP (필요 시 lazy-mcp servers.json에 추가)
- stitch-mcp — 디자인 작업 시에만
- 기타: npm search로 발견 → servers.json 추가 → invoke_command로 즉시 사용
- hook 강제: enforce-execution.sh가 "안 됩니다" 전에 npm search 요구, user-prompt.ts가 도메인 키워드 감지 시 힌트 주입

### Bash CLI 도구 (MCP 외)
| 도구 | 용도 |
|------|------|
| agent-browser | 브라우저 제어 (~7K 토큰/10스텝). 쿠팡: Chrome CDP |
| codex exec | OpenAI Codex CLI. 검수 + Vision (-i 이미지) |
| opencode run -m | Antigravity CLI. 외부 모델 검수 |
| gemini -p | Gemini CLI. 제3 모델 검수 |
| gh | GitHub CLI |
| firebase | Firebase 배포/관리 |

### 제거된 MCP
| MCP | 제거일 | 사유 |
|-----|--------|------|
| persona-mcp (7도구) | 2026-04-04 | 실사용 1.5/5, 도구 점유 과다 |
| stakeholder-mcp (9도구) | 2026-04-04 | 실사용 2/5, 편집장 검토는 Antigravity CLI로 대체 |
| windows-mcp (darbot) | 2026-04-05 | 연결 실패, computer-use-mcp로 대체 |

---

## Hooks 구조 (harness v3, 2026-04-05)

설정 파일: `D:/jamesclew/harness/settings.json`
스크립트: `D:/jamesclew/harness/hooks/` (13개 파일)

**규칙: hook 추가/수정 시 이 설계 문서도 반드시 동시 업데이트.**

### Stop Hooks (세션 종료 시)

| # | hook | 파일 | 설명 | 강제 방식 |
|---|------|------|------|----------|
| 1 | 선언-미실행 감지 | enforce-execution.sh | "하겠습니다" + 도구 0건 → block | decision:block |
| 2 | "할까요?" 감지 | enforce-execution.sh | "할까요/진행할까" + 도구 0건 → block | decision:block |
| 3 | 섣부른 불가 감지 | enforce-execution.sh | "안 됩니다" + 검색 0건 → block + npm search MCP 안내 | decision:block |
| 4 | Evidence-First | evidence-first.sh | "확인했습니다" + 도구 0건 → block | decision:block |
| 5 | 종료 알림 | telegram-notify.sh stop | 텔레그램 종료 알림 | 알림 |
| 6 | Self-Evolve | self-evolve.sh --apply | 피드백 패턴 분석 → 메모리 생성 | 자동 |
| 7 | 큐레이션 | curation.ts | 맥락 큐레이션 | 자동 |

### PreToolUse Hooks

| # | matcher | hook | 파일 | 설명 |
|---|---------|------|------|------|
| 8 | Write\|Edit | 시크릿 보호 | 인라인 | .env/.pem/.key → deny |
| 9 | Write\|Edit | 메모리 쓰기 검증 | verify-memory-write.sh | URL/repo 존재 확인 |
| 10 | Bash | 커밋 전 검증 | quality-gate.sh pre-commit | git commit 매칭 |
| 11 | Bash | 비가역 작업 알림 | irreversible-alert.sh | rm -rf, git push --force 등 감지 |
| 11b | Stitch MCP | 승인 대기 차단 | stitch-approval.sh | pending 시 생성/수정 차단 |
| 11c | Stitch MCP | 도구 가이드 주입 | tool-guide-inject.sh | 첫 호출 시 Obsidian 가이드 자동 로드 |

### PostToolUse Hooks

| # | matcher | hook | 파일 | 설명 |
|---|---------|------|------|------|
| 12 | Bash (deploy) | 배포 후 검증 | verify-deploy.sh | HTTP 200 + Playwright 스크린샷 |
| 13 | Bash (deploy) | 검수 강제 주입 | enforce-review.sh | 외부 모델 검수 안내 컨텍스트 주입 |
| 14 | Bash | 에러 텔레그램 | error-telegram.sh | exit≥2 시 자동 텔레그램 알림 |
| 15 | Bash | 루프 감지 | loop-detector.sh | 동일 명령 3회 반복 감지 (Read/Agent/Glob/Grep 제외) |
| 16 | Write\|Edit | 자동 포맷 | 인라인 | Prettier/Black |
| 17 | Write\|Edit | 편집 후 검증 | quality-gate.sh post-edit | 품질 게이트 |
| 18 | Bash | 테스트 후 검증 | quality-gate.sh post-test | 테스트 결과 검증 |
| 19 | WebFetch\|WebSearch | 루프 감지 | loop-detector.sh | 웹 요청 반복 감지 |

### SubagentStop Hooks

| # | hook | 파일 | 설명 |
|---|------|------|------|
| 20 | Hallucination 검증 | verify-subagent.sh | 서브에이전트 URL/repo 존재 확인 |

### UserPromptSubmit Hooks

| # | hook | 파일 | 설명 |
|---|------|------|------|
| 21 | 메모리 주입 + 피드백 감지 + 컨텍스트 마일스톤 + 온디맨드 MCP 힌트 | user-prompt.ts | 20% 단위 규칙 재주입, 60% compact 체크리스트, 도메인 키워드 감지 시 npm search MCP 안내 |

### Lifecycle Hooks

| # | event | hook | 설명 |
|---|-------|------|------|
| 22 | SessionStart | telegram + session-start.ts | 핵심 규칙 주입 + 진화 경고 |
| 23 | PreCompact | self-evolve.sh + curation.ts | 자동 진화 + 큐레이션 |
| 24 | PostCompact | telegram + session-start.ts | 규칙 재주입 |

---

## CLAUDE.md 구조 (v3, 52줄)

| 섹션 | 줄 수 | 내용 | hook 강제 |
|------|:---:|------|:---:|
| Identity/Language | 4 | 정체성, 언어 규칙 | - |
| Ghost Mode | 3 | 즉시실행, 안됩니다 금지 | enforce-execution.sh |
| Auditability | 4 | Evidence-First, Search-Before-Solve | evidence-first.sh |
| Autonomous Operation | 7 | TodoWrite, Multi-Pass, 스킬 검색 | - |
| Tool Priority | 14 | 비용순 도구, 온디맨드 MCP, 외부 검수 | enforce-review.sh, user-prompt.ts |
| Context & Session | 5 | compact, 세션 관리 | user-prompt.ts |
| Hallucination | 2 | 추측 금지 | verify-subagent.sh |
| File/Hosting/Quality | 5 | 위치, Firebase, 품질 | quality-gate.sh, verify-deploy.sh |

---

## 검증 체계

### 코드/배포 검증
```
코드 변경 → [post-edit quality-gate] → 테스트 → [post-test quality-gate]
  → 빌드 → [pre-commit quality-gate] → 커밋
  → firebase deploy → [verify-deploy HTTP 200 + 스크린샷]
                     → [enforce-review 외부 모델 검수 강제]
  → 전체 통과 후 보고 [evidence-first.sh가 증거 없는 보고 차단]
```

### 블로그 콘텐츠 검증
```
JSON 작성 → quality-checker.mjs 6패스 (구조/SEO/AI냄새/팩트/이미지/차별화)
  → runQualityLoop() 최소 2라운드 saturation
  → Pass 5b: Opus+Sonnet 서브에이전트 이미지-제품 매칭 검증
  → crossReview(): Antigravity+Codex+Gemini 3모델 교차 검수
  → 배포 → verify-deploy.sh → agent-browser 브라우저 렌더링 확인
  → 전체 이미지 naturalWidth>0 확인 → 보고
```

### 이미지 캡처
- 1순위: og:image CDN 직접 다운로드 (UI 오버레이 없음, 800x800)
- 2순위: Playwright launchPersistentContext + --disable-blink-features (쿠팡 봇 우회)
- 3순위: agent-browser CDP (Chrome --remote-debugging-port=9222)
- 검증: Opus+Sonnet 서브에이전트 교차 (브랜드/모델/소모품 구분)
- fallback: OpenAI Vision API (gpt-4o-mini) + Codex CLI vision
- loading="lazy" 사용 금지

---

## 컨텍스트 관리 (1M 기준)
- 시스템 오버헤드: ~24K (빌트인 도구 정의 + MCP)
- 현재 tool 수: 33개 (안전 범위)
- compact 타이밍: 65% 수동 (자동 75%보다 유리)
- compact 전 저장: ① 옵시디언 세션 요약 ② harness_design.md ③ git ④ TodoWrite
- 컨텍스트 추측 금지 → heartbeat로 실제 수치 확인

## 인프라 정책
- Firebase 전용 (Hosting, Firestore, Functions, Storage). WordPress 금지.
- 하네스: D:/jamesclew/harness/ → `bash harness/deploy.sh`. ~/.claude/ 직접 수정 금지.

## 알려진 제한사항
- Usage API: Claude Max OAuth 토큰에 대해 persistent 429 (#30930)
- Explore 서브에이전트: 230+ tools 시 실패 (Haiku 200K 한계)
- Windows Git Bash: grep -oP의 \K 미지원 → sed 사용
- 쿠팡: agent-browser 기본 모드 Access Denied → CDP 또는 Playwright 필수
- ainic iSA7: 쿠팡 판매 종료, 제품ID가 듀얼바스켓 모델

---

## 변경 이력

| 날짜 | 변경 | 근거 |
|------|------|------|
| 2026-04-03 | Phase 2 착수, Firebase 통일 | 대표님 결정 |
| 2026-04-03 | verify-deploy.sh 추가 | 복원력 2/10 해소 |
| 2026-04-03 | quality.md Multi-Pass + 멀티라운드 루프 | Self-Refine 논문, 10회+ 반복 품질 향상 |
| 2026-04-04 | enforce-execution.sh (Stop) | 선언-미실행 3회 연속 위반 |
| 2026-04-04 | session-start.ts 핵심 규칙 직접 주입 | CLAUDE.md "may or may not" 격하 우회 |
| 2026-04-04 | user-prompt.ts 10턴 리마인더 + 20% 마일스톤 | compact 후 규칙 소멸 방지 |
| 2026-04-04 | loop-detector.sh | 동일 도구 3회 반복 감지 |
| 2026-04-04 | lazy-mcp 도입 | 도구 10→4개, 자율 MCP 탐색 가능 |
| 2026-04-04 | persona-mcp + stakeholder-mcp 제거 | 실사용 대비 도구 점유 과다 |
| 2026-04-04 | Self-Evolving Loop (self-evolve.sh) | 피드백 패턴 자동 분석 → 메모리 생성 |
| 2026-04-04 | compact pre-save checklist (60% 트리거) | compact 후 저장은 무의미, 직전에 실행 |
| 2026-04-04 | 외부 모델 이중 검수 강제 (Antigravity + Codex) | Claude 자기 검수 5회 PASS → Antigravity 4개 이슈 발견 |
| 2026-04-05 | agent-browser 도입 | Playwright MCP 대비 16x 토큰 절약 (7K vs 114K) |
| 2026-04-05 | desktop-control (computer-use-mcp) 등록 | 데스크톱 UI 제어 (스크린샷, 마우스, 키보드) |
| 2026-04-05 | llm-judge.mjs 3모델 다양화 + Vision | Antigravity+Codex+Gemini 교차, OpenAI Vision+Codex Vision |
| 2026-04-05 | Opus+Sonnet 서브에이전트 이미지 검증 | 36개 이미지 교차 검증, FAIL 4건 + WARN 7건 발견 |
| 2026-04-05 | og:image CDN 캡처 방식 발견 | 쿠팡 UI 오버레이 없는 순수 제품 이미지 800x800 |
| 2026-04-05 | loading="lazy" 전체 제거 | headless 환경에서 이미지 로드 실패 근본 원인 |
| 2026-04-05 | evidence-first.sh (Stop) | 증거 없이 "확인했습니다" 보고 차단 |
| 2026-04-05 | enforce-review.sh (PostToolUse/deploy) | 배포 후 외부 모델 검수 강제 주입 |
| 2026-04-05 | error-telegram.sh (PostToolUse/Bash) | Bash 에러 시 텔레그램 자동 알림 |
| 2026-04-05 | enforce-execution.sh "할까요?" 패턴 추가 | Ghost Mode 구조적 강제 |
| 2026-04-05 | user-prompt.ts 온디맨드 MCP 도메인 감지 | 법령/특허/주식 등 키워드 감지 → npm search MCP 힌트 |
| 2026-04-05 | loop-detector.sh Read/Agent/Glob/Grep 제외 | 이미지 검증 등 정상 반복을 오탐 방지 |
| 2026-04-05 | CLAUDE.md 102줄 → 52줄 압축 | hook으로 강제되는 규칙은 한 줄 참조. 지시 150개 초과 시 준수율 가속 저하 (Jaroslawicz 2025) |
| 2026-04-05 | korean-law-mcp lazy-mcp 등록 | 국가법령정보센터 API |
| 2026-04-07 | stitch-approval.sh (PreToolUse/Stitch) | Stitch 디자인 승인 대기 시 추가 생성 차단 (P-017) |
| 2026-04-07 | tool-guide-inject.sh (PreToolUse/MCP) | MCP 도구 첫 호출 시 Obsidian 가이드 자동 주입. 시행착오 방지 |
| 2026-04-07 | user-prompt.ts 리마인더 간격 조정 (8→15턴, 20→30턴) + 초반5턴 부스트 | 피드백 33% 초반 집중 대응 + 36% 토큰 절감 (17K→11K/세션) |
| 2026-04-07 | CLAUDE.md Subagent Model Selection 가이드 추가 | 단순 탐색에 Opus 낭비 방지. haiku/sonnet/opus 작업별 매핑 |
| 2026-04-08 | rules/design_rubric.md 추가 + /qa 통합 | Anthropic Harness Ablation 연구 (Tech Bridge 영상 2026-04-05) 반영. Evaluator가 4축(일관성·독창성·완성도·기능성) 점수로 등급 평가. "보라색 그라데이션" AI 클리셰 블랙리스트로 Claude 디자인 약점 자동 감지 |
| 2026-04-08 | /prd Planner 고수준화 | 기술 태스크 분해 (T1-T15) → 제품 마일스톤 (M1-M5, 사용자 결과) 전환. Opus 4.6에서 마이크로 분할이 오히려 에이전트 자율 수정 방해 (Anthropic 연구) |
| 2026-04-08 | scripts/evaluator.sh 추가 + /pipeline-run Step 7 통합 | Generator-Evaluator 분리 자동화. Playwright 캡처 + Codex 등급 평가 (rubric 기반) 원샷 스크립트. /qa Phase 2와 /pipeline-run Step 7에서 호출 |
| 2026-04-08 | post-edit-dispatcher.sh + user-prompt.ts 자동 세션 rename hook 추가 | PRD.md/PLAN.md 작성 감지 → 디렉토리 슬러그 자동 추출 → `~/.harness-state/session_rename_pending.txt` → 다음 user prompt 시 "/rename <slug> 안내" systemMessage 주입. Multi Blog 프로젝트에서 "blou-auto" 세션명 혼동 이슈 해결 |
| 2026-04-08 | PITFALLS P-012 기록 (declare_no_execute 반복) | "진행합니다" 선언 후 응답 종료 패턴. 보고를 사용자 승인 대기 신호로 오해. 재발 방지: 매 응답 종료 전 "방금 선언한 다음 작업의 도구 호출이 이 응답 안에 있는가?" 자체 점검 룰 확립 |
| 2026-04-10 | CLAUDE.md 하향 나선 금지 + 4번째 시도 보고 규칙 | Nyongjong 95% confidence-first 패턴 → 행동 규칙 번역. declare_no_execute 9회 재발 방지 |
| 2026-04-10 | CLAUDE.md 하네스 수정 전 advisor() 필수 | 하네스 변경 시 충돌/회귀 사전 검토 게이트 |
| 2026-04-10 | cost-tracker.sh 시간당 경고 임계값 ($4/hr) | Nyongjong cost-guard 참조. PostToolUse라 차단 불가 → 경고만 |
| 2026-04-10 | evaluator.sh 5→3단계 축소 | GLM free tier 비실용 + ollama cloud 미검증 제거. codex(6)→opencode(4)→backoff |
| 2026-04-10 | user-prompt.ts PITFALLS 중복 검출 | 신규 기록 전 grep 유사 항목 확인 → 재발이면 기존 항목에 날짜 추가 |
| 2026-04-10 | enforce-execution.sh 분석 컨텍스트 예외 | 비교/분석/검토 문맥에서 "하겠습니다" 오탐 방지. 윈도우 2K→4K 확대 |
| 2026-04-10 | CLAUDE.md compact 65%→45% | 조기 정리로 낭비 감소. Opus 세션 전용, Sonnet은 auto |
| 2026-04-10 | CLAUDE.md Multi-Pass 가속 | "최소 2라운드" → "수정 0건이면 1라운드 완료" |
| 2026-04-10 | CLAUDE.md Dual Model Strategy | Opus(분석/1M) + Sonnet+Advisor(코딩/128K) 세션별 선택 |
| 2026-04-10 | expect MCP expect init으로 재설정 | npx/cmd 래퍼 실패 → node 직접 실행 (user config) |
| 2026-04-10 | P-013 Sonnet 컨텍스트 반복 간과 | 128K에서 45% compact = 57K. 하네스 엔지니어링에 부적합 |
| 2026-04-12 | Multi-Model Orchestration + 5H 전략 전면 개편 | Opus 오케스트레이터 + 4모델 풀, 5H 모든 모델 공통 발견, 외부 모델 우선 위임, Copilot GPT-4.1 통합, ralph-loop 도입, 토큰 52팁 8개 적용, Managed Agents 검증, evidence-first 오탐 수정, expect MCP 통합, 다른 프로젝트 호환성 확보 |
| 2026-04-12 | managed-blog-agent.py (Managed Agent blog pipeline) | 블로그 생성을 Managed Agent(별도 API 크레딧)로 분리. 5H 0 소비, $0.40/건. Agent v3까지 진화 |
| 2026-04-12 | blog-review.md 벤치마크 비교 평가 도입 | Codex 단독 AI냄새 평가(78~86 고정)의 한계 발견 → 인간 블로그 추출 비교 방식으로 전환. 58→65 추적 가능 |
| 2026-04-12 | codex-rotate.sh (6계정 로테이션 + gemma4 폴백) | 단일 계정 리밋 시 자동 전환. CLAUDE.md Codex CLI 레퍼런스 업데이트 |
| 2026-04-12 | P-015 로컬 서비스 미실행 시 직접 시작 | P-010 동일 패턴 재발. "안 되면 되게 하라" 원칙 |
