# Architecture Rules

## Tool Selection
상세: CLAUDE.md Tool Priority 참조. 요약: Built-in > Bash commands > MCP servers (비용순)
- GitHub: gh CLI (MCP 아님)
- 브라우저: npx playwright CLI (MCP의 4x 저렴, 비용 비교 참조용 — 하네스 내부 브라우저 작업은 **expect MCP 우선**: `mcp__expect__open/screenshot/playwright` 등. allowlist 승인 불필요. claude-in-chrome은 실제 크롬 탭 조작 필요 시에만, 매 호출 승인 요구)
- 웹 콘텐츠: curl r.jina.ai/URL
- OCR: tesseract CLI
- Tavily: 5개 도구. 크롤링/추출에 강점. **토큰 주의: 결과 평균 11KB/회 — 도구 결과 중 최대.**
  - search: 웹 검색. **기본값 강제: `search_depth="basic"`, `max_results=5`**. advanced는 명시 요청 시에만. 6키 로테이션.
  - crawl: 사이트 재귀 크롤링 (깊이/너비 지정). 경쟁사 사이트 전체 수집.
  - extract: URL에서 원문 마크다운 추출 (LinkedIn 등 보호 사이트 가능).
  - map: 사이트맵 구조 탐색 (URL 트리).
  - research (mini/pro): 딥 리서치.
- NotebookLM: 소스 누적 지식 베이스 + 콘텐츠 생성. 무료.
  - notebook_query: 기존 소스에 무제한 질의.
  - research_start: 웹/Drive 검색 → 소스 영구 저장.
  - studio_create: 9종 콘텐츠 생성 (팟캐스트/영상/인포그래픽/슬라이드/보고서/마인드맵/퀴즈).
  - source_add: URL/텍스트/파일 소스 추가.
  - **사용 전략**:
    - 빠른 팩트/웹 검색 → Tavily search
    - 원문 수집/크롤링 → Tavily crawl/extract
    - 심층 조사 + 영구 저장 → NotebookLM research_start (무료)
    - 반복 참조 → NotebookLM notebook_query
    - 콘텐츠 생성 → NotebookLM studio_create

## Tool Budget
Tool 50개 이하 유지 (230+에서 서브에이전트 실패, 50~100이 안전 범위).
상시: Tavily(5) + NotebookLM(~25) + Telegram(4) + desktop-control(1) = ~35개
Stitch: 온디맨드 MCP (`claude mcp add stitch -s user -- npx @_davideast/stitch-mcp proxy`). 작업 완료 후 `claude mcp remove stitch`. reload 필요.
온디맨드: 에이전트가 npm에서 MCP 검색 → user config에 추가 → 즉시 사용
korean-law: 온디맨드 (89도구, 33K토큰 — 상시 로드 금지). 필요 시 `claude mcp add korean-law -s user -- cmd /c npx -y korean-law-mcp`


### agentmemory MCP (Layer 1 자동 기억)
- 등록명: `agentmemory`
- 도구 수: 7 core (full 51로 확장 시 Tool Budget 230+ 임계 주의)
- 모드: standalone shim (iii-engine worker 별도 영구화 필요 시 Windows Task Scheduler/NSSM)
- LLM: noop (synthetic compression). 향후 ANTHROPIC_API_KEY/OPENAI_API_KEY 추가 시 LLM 압축·통합 활성 가능
- Embedding: local Xenova/all-MiniLM-L6-v2 (384-dim, 무료)
- 비용: 월 ₩0 (LLM 키 없으므로)
- 데이터 위치: `~/.agentmemory/` (SQLite + 인덱스) + 자동 export `06-raw/agentmemory/`

## Memory Layer 비교
3개 레이어 역할 분리 — 상세: CLAUDE.md "Memory Layers" 섹션 참조.

| 레이어 | 시스템 | 저장 주체 | 용도 |
|--------|--------|----------|------|
| Layer 1 | agentmemory MCP | 자동 (hook) | 세션 작업 기억, 에러→해결 흐름 |
| Layer 2 | gbrain + Obsidian | 에이전트/수동 | 도메인 지식, PITFALLS, BASB |
| Layer 3 | MEMORY.md | 수동 | 사용자 선호, 프로젝트 메타 |

검색 우선순위: agentmemory (작업 맥락) → gbrain (도메인) → MEMORY.md (메타)

## Hosting & Infrastructure
모든 웹 프로젝트는 Firebase 기반으로 통일.
- Hosting: Firebase Hosting (정적 사이트, SSG)
- Database: Firestore (콘텐츠 저장, CMS)
- Functions: Firebase Functions (필요 시, 동적 API)
- Auth: Firebase Auth (필요 시)
- Storage: Firebase Storage (미디어)
- CLI: `firebase` CLI 사용 (MCP 아님)
- 도메인: Firebase Hosting에 커스텀 도메인 연결
WordPress 사용하지 않음 — Firebase + SSG로 대체.

## 외부 모델 기본 매핑 (자율 변경 허용)
상황에 맞게 변경 가능. 잘못된 선택은 PITFALLS에 기록하여 진화.

| 용도 | 기본 모델 | 이유 |
|------|----------|------|
| AI냄새 검수 | Codex (1순위), gemma4·exaone3.5 (보조) | 톤/문체 비교에 강함 |
| 차별화 분석 | Codex (1순위), gemma4 (보조) | 경쟁 글 대비 분석 |
| 전체 교차 검수 | 3모델 전부 | 다수결 |
| 이미지-제품 매칭 | Opus + Sonnet 서브에이전트 | Vision 정확도 최고 |
| 이미지 자동 검증 (코드 내) | OpenAI gpt-4o-mini + Codex -i | API 호출 가능 |
| 콘텐츠 autoFix | 라운드별 로테이션 | 같은 모델 반복 방지 |
| **Vision (스크린샷 분석)** | **Opus 4.6 직접 Read** | Sonnet Vision 정확도 -20~30% |
| **Stitch ↔ 라이브 비교** | Opus Vision (`/design-review`) | pixel-level 체크 |
| **Computer Use 엘리먼트 식별** | ARIA snapshot 1차 → Opus Vision 2차 | 좌표 추정 오류 예방 |
| **claude-in-chrome 인식률 ↑** | `read_page` → `get_screenshot` → Opus | 텍스트 우선, 애매하면 Vision |

## 에러 유형별 참고 지식 (강제 아님, 판단 재료)
3회 재시도 원칙은 유지. 아래는 재시도 시 참고할 패턴.

| 에러 유형 | 증상 | 효과적 대응 |
|----------|------|-----------|
| 네트워크/타임아웃 | ETIMEDOUT, ECONNREFUSED | 3-5초 대기 후 재시도. 3회 실패 시 보고 |
| 인증/권한 | 401, 403, Access Denied | 재시도 무의미. 즉시 보고 (키/토큰 문제) |
| Rate Limit | 429, Too Many Requests | 지수 백오프 (5→15→45초). Tavily는 키 로테이션 |
| 봇 차단 | Access Denied (쿠팡 등) | 방식 전환 (headless→CDP→og:image). 같은 방식 재시도 무의미 |
| 빌드/문법 | SyntaxError, build fail | 에러 메시지 정독 → 수정 → 재빌드 |
| 외부 모델 실패 | Codex 타임아웃 | Codex 3회 재시도. 실패 시 대표님 보고. 로컬 단독 결정 금지 |

## 비용 추적
API 호출 비용을 누적 로깅. 제한하지 않음, 관찰만.
- 로그 위치: `~/.harness-state/api_cost_log.jsonl`
- 기록 항목: 날짜, 서비스(tavily/openai), 모델, 비용, 용도
- 월말 집계 시 대표님께 보고

## Context Management
1M 컨텍스트 시대 — 턴당 예산 제한 없음.
대형 파일은 offset+limit 필수. 500K+ 시 /compact 고려.
Glob > Grep > Agent 순으로 검색.

## Native Orchestration 활용 (v2.1.139+ — 2026-05-16 채택)

Claude Code 네이티브 커맨드를 우리 하네스 자산과 결합하여 토큰·유지보수 부담을 낮춘다. 기존 자산은 **유지**하되 호출 패턴만 네이티브화.

### `/loop <interval> <slash-command>` — 주기 반복
v2.1.139 신규. cron보다 단순. 세션 안에서 자동 반복.

| 우리 자산 | 권장 호출 |
|----------|-----------|
| `/blog-pipeline` | `/loop 4h /blog-pipeline` — 4시간마다 키워드 1개 처리 |
| `/audit` | `/loop 24h /audit` — 일일 자동 감사 |
| `/feedback-loop` | `/loop 6h /feedback-loop` — 6시간마다 프로덕션 피드백 수집 |
| `/inbox-process` | `/loop 12h /inbox-process` — 옵시디언 inbox 자동 정리 |

⚠️ `/loop redundant wakeups fix (v2.1.140)` — background notify task에는 polling 안 함. R14 watchdog 보완.

### `/goal "<완료 조건>"` — 다중 턴 자율 지속
v2.1.139 신규. completion condition 설정 후 Claude가 turn 넘어 자동 작업. interactive / `-p` / Remote Control 모두 지원.

| 우리 자산 | 권장 호출 |
|----------|-----------|
| `/self-heal` 보강 | `/goal "테스트 100% 통과 + lint 0 warning + 빌드 성공"` |
| `/pipeline-run` 보강 | `/goal "Multi-Pass Review 2라운드 연속 수정 0건"` |
| `/blog-fix` 보강 | `/goal "품질 게이트 7단계 모두 PASS"` |

라이브 elapsed/turns/tokens 오버레이 표시. 자동 진화 루프와 결합 가능.

### `/schedule` — cron 기반 원격 에이전트
v2.1.139 신규. routines 매니징.

| 우리 자산 | 권장 호출 |
|----------|-----------|
| `commands/reset-ping-setup.md` | `/schedule add "0 5,12,19 * * *" /reset-ping-setup` — 5H 리셋 시점 자동 |
| 주간 회고 | `/schedule add "0 9 * * MON" /review-week` |
| codex-keepalive | 이미 Windows Task Scheduler (외부 cron). `/schedule`로 통합 가능 |

⚠️ Remote Control / `/schedule` / claude.ai MCP connectors는 `ANTHROPIC_API_KEY`/`apiKeyHelper`/`ANTHROPIC_AUTH_TOKEN` 설정 시 비활성 (v2.1.139). API key 사용 환경에서는 fallback 필요.

### `claude agents` — Agent View (Research Preview)
v2.1.139 신규. running / blocked-on-you / done 세션 한눈에. Ralph Loop, 장기 background 작업 가시성 ↑.

### 채택 원칙
- 기존 우리 자산은 **유지**. 네이티브는 **호출 인프라**로 활용.
- 우리 commands/skills는 도메인 로직 (블로그/BASB/codex 회전 등) 담당.
- 네이티브는 **스케줄링/반복/완료조건** 담당.
- 이중 운영 시 우리 hook (audit, telegram-notify 등)이 우선 — 네이티브는 보조.
