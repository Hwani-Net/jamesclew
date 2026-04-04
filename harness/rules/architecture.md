# Architecture Rules

## Tool Selection
Built-in > Bash commands > MCP servers (비용순)
- GitHub: gh CLI (MCP 아님)
- 브라우저: npx playwright CLI (MCP의 4x 저렴)
- 웹 콘텐츠: curl r.jina.ai/URL
- OCR: tesseract CLI
- Perplexity: 검색(search)만 사용. 분석/추론은 Opus가 직접 수행.

## Tool Budget
Tool 50개 이하 유지 (230+에서 서브에이전트 실패, 50~100이 안전 범위).
상시: Tavily(5), Perplexity search(1), Telegram(4) = 10개
온디맨드: Stitch MCP (디자인 시만 등록→완료 후 제거), Context7, Windows-MCP
제거됨: persona-mcp(7), stakeholder-mcp(9) — 실사용 대비 도구 점유 과다. 편집장 검토는 OpenCode serve Bash 직접 호출로 대체.

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
