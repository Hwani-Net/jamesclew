# Architecture Rules

## Tool Selection
Built-in > Bash commands > MCP servers (비용순)
- GitHub: gh CLI (MCP 아님)
- 브라우저: npx playwright CLI (MCP의 4x 저렴)
- 웹 콘텐츠: curl r.jina.ai/URL
- OCR: tesseract CLI
- Perplexity: 4개 도구. 비용 인식하고 용도에 맞게 선택.
  - search (~$0.006/회): URL/목록 검색. 기본 선택.
  - ask (~$0.03/회): 빠른 팩트 답변.
  - reason (~$0.02/회): 단계별 추론.
  - research (~$0.80/회): 딥 리서치. search 대비 133배 비용.
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
    - 빠른 팩트 → Perplexity search
    - 원문 수집/크롤링 → Tavily crawl/extract
    - 심층 조사 + 영구 저장 → NotebookLM research_start (무료)
    - 반복 참조 → NotebookLM notebook_query
    - 콘텐츠 생성 → NotebookLM studio_create

## Tool Budget
Tool 50개 이하 유지 (230+에서 서브에이전트 실패, 50~100이 안전 범위).
상시: Perplexity(4) + Tavily(5) + NotebookLM(~25) + Telegram(4) + desktop-control(1) = ~39개
Stitch: 온디맨드 MCP (`claude mcp add stitch -s user -- npx @_davideast/stitch-mcp proxy`). 작업 완료 후 `claude mcp remove stitch`. reload 필요.
온디맨드: 에이전트가 npm에서 MCP 검색 → user config에 추가 → 즉시 사용
korean-law: 온디맨드 (89도구, 33K토큰 — 상시 로드 금지). 필요 시 `claude mcp add korean-law -s user -- cmd /c npx -y korean-law-mcp`

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
| AI냄새 검수 | GPT-4.1 + Codex | 톤/문체 비교에 강함 |
| 차별화 분석 | GPT-4.1 + Gemini | 경쟁 글 대비 분석 |
| 전체 교차 검수 | 3모델 전부 | 다수결 |
| 이미지-제품 매칭 | Opus + Sonnet 서브에이전트 | Vision 정확도 최고 |
| 이미지 자동 검증 (코드 내) | OpenAI gpt-4o-mini + Codex -i | API 호출 가능 |
| 콘텐츠 autoFix | 라운드별 로테이션 | 같은 모델 반복 방지 |

## 에러 유형별 참고 지식 (강제 아님, 판단 재료)
3회 재시도 원칙은 유지. 아래는 재시도 시 참고할 패턴.

| 에러 유형 | 증상 | 효과적 대응 |
|----------|------|-----------|
| 네트워크/타임아웃 | ETIMEDOUT, ECONNREFUSED | 3-5초 대기 후 재시도. 3회 실패 시 보고 |
| 인증/권한 | 401, 403, Access Denied | 재시도 무의미. 즉시 보고 (키/토큰 문제) |
| Rate Limit | 429, Too Many Requests | 지수 백오프 (5→15→45초). Tavily는 키 로테이션 |
| 봇 차단 | Access Denied (쿠팡 등) | 방식 전환 (headless→CDP→og:image). 같은 방식 재시도 무의미 |
| 빌드/문법 | SyntaxError, build fail | 에러 메시지 정독 → 수정 → 재빌드 |
| 외부 모델 실패 | Codex/Gemini timeout | 다른 모델로 대체. 3모델 중 2개 성공이면 진행 |

## 비용 추적
API 호출 비용을 누적 로깅. 제한하지 않음, 관찰만.
- 로그 위치: `~/.harness-state/api_cost_log.jsonl`
- 기록 항목: 날짜, 서비스(perplexity/openai), 모델, 비용, 용도
- 월말 집계 시 대표님께 보고

## Context Management
1M 컨텍스트 시대 — 턴당 예산 제한 없음.
대형 파일은 offset+limit 필수. 500K+ 시 /compact 고려.
Glob > Grep > Agent 순으로 검색.
