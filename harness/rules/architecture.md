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
상시: lazy-mcp(4 meta-tools) + Telegram(4) = 8개
lazy-mcp 내부: Perplexity, Tavily — 필요 시 invoke_command로 호출
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
