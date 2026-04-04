# Architecture Rules

## Tool Selection
Built-in > Bash commands > MCP servers (비용순)
- GitHub: gh CLI (MCP 아님)
- 브라우저: npx playwright CLI (MCP의 4x 저렴)
- 웹 콘텐츠: curl r.jina.ai/URL
- OCR: tesseract CLI
- Perplexity: 4개 도구 모두 사용 가능. 비용 인식하고 용도에 맞게 선택.
  - search (~$0.006/회): URL/목록 검색. 기본 선택. 5개 출처.
  - ask (~$0.03/회): 빠른 팩트 답변. search로 부족할 때.
  - reason (~$0.02/회): 단계별 추론. 복잡한 판단 필요 시.
  - research (~$0.80/회): 딥 리서치. 50회 검색+38출처+163K reasoning 토큰. search 대비 133배 비용.
  - **사용 전략**: search로 기본 목록 → 스펙 불확실하면 ask → 새 카테고리/경쟁분석에만 research
  - Perplexity API 비용은 Claude 요금과 별도 과금.

## Tool Budget
Tool 50개 이하 유지 (230+에서 서브에이전트 실패, 50~100이 안전 범위).
상시: lazy-mcp(4 meta-tools) + Telegram(4) + desktop-control(1) = 9개
lazy-mcp 내부: Perplexity(4도구), Tavily(5도구, 6키 로테이션), korean-law — invoke_command로 호출
Stitch: 온디맨드 MCP (`claude mcp add stitch -s user -- npx @_davideast/stitch-mcp proxy`). lazy-mcp·CLI 모두 Windows 비호환. 작업 완료 후 `claude mcp remove stitch`. reload 필요.
온디맨드: 에이전트가 npm에서 MCP 검색 → servers.json에 추가 → 즉시 사용
제거됨: persona-mcp(7), stakeholder-mcp(9) — 실사용 대비 도구 점유 과다.
설정 위치: ~/.config/lazy-mcp/servers.json

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

## Context Management
1M 컨텍스트 시대 — 턴당 예산 제한 없음.
대형 파일은 offset+limit 필수. 500K+ 시 /compact 고려.
Glob > Grep > Agent 순으로 검색.
