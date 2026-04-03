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
상시: Tavily(5), Perplexity search(1), persona-mcp(7), stakeholder-mcp(9), Telegram(4)
온디맨드: Stitch(12), Context7, Windows-MCP, Firebase

## Context Management
1M 컨텍스트 시대 — 턴당 예산 제한 없음.
대형 파일은 offset+limit 필수. 500K+ 시 /compact 고려.
Glob > Grep > Agent 순으로 검색.
