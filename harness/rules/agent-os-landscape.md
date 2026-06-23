# Agent OS 지형 + JamesClaw 매핑 + 채택 로드맵

등록일: 2026-06-22 (뉴스 분석 적용 — "에이전트가 도구→지속 실행 OS로 이동")
출처: deer-flow(bytedance), omnigent(omnigent-ai), OpenMontage(calesthio), gstack(garrytan), eve(Vercel) — 2026 실조사

## 명제

AI 에이전트가 **단일 프롬프트 도구 → 장기작업·역할분담·스킬·메모리·샌드박스를 갖춘 "에이전트 OS"** 로 이동 중. 5개 대표 프로젝트가 같은 구성요소를 수렴 채택.

## 핵심 결론 — JamesClaw는 이미 agent-OS의 ~80%

트렌드가 우리 설계를 **검증**한다(독립 진화 수렴). 아래 매핑에서 대부분 ✅ 보유:

| Agent-OS 구성요소 | 대표 프로젝트 | JamesClaw 현황 | 판정 |
|---|---|---|---|
| **스킬 = 파일(온디맨드 로드)** | eve(dir+manifest), gstack, omnigent(YAML), deer-flow | `commands/`(21) + **글로벌** `~/.claude/skills/`(watch·humanizer·grammar-checker·style-guide·gstack·gpt-image-2 — 실측) + SKILL.md frontmatter. (프로젝트 `.claude/skills/`엔 expect만) | ✅ 보유 |
| **멀티에이전트 역할분담** | deer-flow(supervisor+Researcher/Coder/Reporter), gstack(9역할) | `/agent-team`(6역할) + OpenClaw 봇(JARVIS/TARS/EVE/FRIDAY/Data/TRON…) + Multi-Model Orchestration | ✅ 보유 |
| **3계층 메모리** | eve, EverOS(profile/episode/fact) | agentmemory MCP + Obsidian BASB(Raw→Distilled→Synthesized) + pitfalls(270) + MEMORY.md | ✅ 보유(강점) |
| **샌드박스 격리** | omnigent(Modal/Daytona OS-sandbox), deer-flow(per-task) | codex restricted fs+network(P-168) + Agent `isolation:worktree` | ✅ 보유(로컬형) |
| **메타하네스(하네스 스왑)** | omnigent | Multi-Model Orchestration: Codex/Sonnet/Gemma/HydraTeams 라우팅 | ✅ 보유 |
| **메시지 게이트웨이** | deer-flow | OpenClaw WSL2 gateway + Discord 14채널 | ✅ 보유(강점) |
| **에이전트=오케스트레이터(코드 오케스트레이터 없음)** | OpenMontage | 메인 세션이 직접 오케스트레이션 | ✅ 보유 |
| **지속 실행/체크포인트-재개** | **eve(durable workflow, step checkpoint, crash/resume)**, deer-flow | Ralph Loop·scheduled·stop-dispatcher 자율 + watchdog(P-268/236) — **체크포인트-재개 부재** | ⚠️ **격차** |

## 진짜 격차 + 채택 우선순위

### 1순위 — 지속 실행 / 체크포인트-재개 (가장 큰 실질 격차)
- eve = "모든 대화가 durable workflow, 매 스텝 체크포인트 → crash/deploy 후 재개". deer-flow = 분~시간 작업 sandbox 지속.
- **우리 약점과 정확히 일치**: 장기작업 stall이 우리의 반복 사고 — P-268(JARVIS idle stuck), P-236(자율진행 멈춤), P-224(WSL2 death), P-214(야간 자율). 현재는 **watchdog 땜질**(stuck-watchdog.timer, cron-retry)이지 1급 체크포인트-재개 아님.
- **조치 검토**: 장기작업 상태를 단계별 체크포인트 파일(`~/.harness-state/task-<id>/step-N.json`)로 저장 → 재시작 시 마지막 green 스텝부터 재개. Reins 게이트(P-256)와 결합하면 "PASS 스텝은 불변·재실행 안 함" 자연 정합.

### 2순위 — 브라우저 자동화: gstack `/browse` 채택 (이미 설치됨)
- gstack `/browse` = 영속 Chromium 세션, 명령 100~200ms, **claude-in-chrome MCP 대비 20배 빠르고 컨텍스트 비대화 없음**.
- **우리 브라우저 자동화 통증과 직결**: P-169(CDP 재시작), P-233/234(browser capability), P-242(WSLg paste 불가). 현 우선순위 expect MCP→claude-in-chrome는 느리고 승인 부담.
- **조치 검토**: `gstack` 스킬 이미 `~/.claude/skills/gstack`에 설치 → `/browse`를 `architecture.md` 브라우저 우선순위 1순위 후보로 실측 비교(우리 expect MCP vs gstack /browse 벤치마크) 후 채택.

### 3순위 — 영상 파이프라인: OpenMontage 벤치마크
- OpenMontage = 오픈소스 agentic 영상(12 파이프라인·52 도구·500+ 스킬·web research 1급·no-code-orchestrator).
- **우리 OpenClaw 영상 패턴(P-196~208)의 성숙한 오픈소스 대조군** → 구조 격차(웹리서치 1급화, 스킬 모듈화) 벤치마크 후 선택 흡수(P-220 명목차용 금지 — 실제 구조 대조).

### 부차 (관찰)
- **omnigent 정책/샌드박스 + 디바이스 무관 협업**: 우리 approvals(P-168)·worktree와 유사. "agents build agents"(YAML 자동작성)는 우리 `/skill-creator`·자동스킬생성과 정합.
- **eve agent-as-directory manifest**: 우리 commands/agents 구조를 manifest화(검증 가능)하면 일관성↑ — 저우선.

## 전체 디제스트 추가 신호 (2026-06-22 텔레그램 원문 반영)

같은 날 GitHub 급상승 목록이 우리 설계를 추가 검증 + 격차 1건:

- **shadcn/improve** (고성능 모델이 코드베이스 감사 → 저비용 모델이 실행할 계획 작성) = 우리 **Multi-Model Orchestration**(Opus/Codex 감사·판정, Sonnet/codex 실행) + **Reins(P-256)** 그대로 → 검증.
- **DietrichGebert/ponytail** ("가장 게으른 시니어처럼 — 적게 쓰고 많이 제거") = 방금 추가한 **Karpathy G2 Simplicity First**(quality.md) → 검증.
- **Waishnav/devspace** (ChatGPT를 Codex처럼 + 사용량 별도 관리) = 우리 **codex 별도 quota**(P-262, 이번 재인증) 운영과 직결 → 관리 패턴 참고 후보.
- **DeusData/codebase-memory-mcp** (코드베이스 영속 지식그래프 인덱싱, 158언어, 토큰 절감) = 메모리 3계층 + **Understand-Anything** 그래프와 인접 → 코드베이스 메모리 MCP 흡수 검토(저우선, 토큰절감 강점).
- **BuilderIO/skills** = 코딩 에이전트 스킬 모음 → 스킬 소스 후보.
- ⚠️ **격차 신호 — 보안**: Anthropic-Cybersecurity-Skills + AUR supply-chain 악성탐지 부상. 우리는 `rules/security.md`(짧음)만 보유, **능동 취약점·공급망 감사 스킬 부재** → 향후 검토(현 우선순위 낮음).

## 적용 원칙

1. **추가 도입 전 "우리에 이미 있나?" 확인** — 위 매핑상 대부분 보유. 중복 구축 금지(P-109 표준앱 우선 정합).
2. **격차만 선택 흡수** — 1순위(체크포인트-재개) > 2순위(/browse, 즉시성 높음·이미 설치) > 3순위(영상 벤치마크).
3. **벤치마크는 명목 아닌 구조 대조**(P-220) — 실측 후 채택.

## 관련
- [[architecture]] — 멀티모델 오케스트레이션·브라우저 우선순위(2순위 /browse 반영 대상)
- [[autonomous-evolution]] — 지속 실행/자율 루프(1순위 체크포인트-재개 반영 대상)
- [[quality]] — Reins 게이트(P-256, 체크포인트 불변성과 정합)
- pitfalls: P-268·P-236·P-224(지속 실행 격차), P-169·P-233·P-242(브라우저), P-196~208(영상)
