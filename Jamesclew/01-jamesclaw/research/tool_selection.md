---
name: Verified Tool Stack
description: 실제 검증된 도구 목록, 선정 이유, 설치 상태
type: project
---

## MCP 서버 (상시 3개)
1. **Tavily MCP** — 웹 검색, 키 로테이션 6개 (tavily-keys.json + tavily-rotator.mjs)
2. **Perplexity MCP** — 딥 리서치/추론
3. **Windows-MCP** (CursorTouch, 4,986 stars) — `uvx --python 3.13 windows-mcp` (Python 3.13 필수, uv가 자동 해결)

## MCP 온디맨드
- Context7, Stitch, Firecrawl, Firebase MCP

## Bash 도구 (MCP 슬롯 불소모)
- gh CLI, firebase CLI, Playwright CLI (MCP 대비 4x 저렴), FFmpeg 8.0.1, PowerShell, Jina Reader (curl r.jina.ai/), Tesseract OCR

## 검증 결과 (2026-04-03)
- GitHub repos: 전부 실존 확인 (openclaw 345K stars, playwright-mcp 30K, claude-flow 29K)
- npm: @playwright/mcp 0.0.70, screenshot-mcp 0.2.1, mcp-control 0.2.0, short-video-maker 1.3.0
- windows-mcp: pip 직접 불가 (Python 3.13 필수), uvx로 설치 성공
- Jina Reader: 동작 확인
- Remotion: 프로젝트별 설치 필요 (글로벌 미설치)

## 탈락된 도구
- klaude-blog (5 stars, 비활성) → claude-seo (3,791 stars)로 대체
- mcp-windows SecretiveShell (22 stars, 2개월 비활성) → PowerShell로 대체
- windows-system-mcp (4 stars) → PowerShell로 대체
- Vector DB (Chroma/Qdrant) → 파일 기반 메모리로 충분

## 네이버 블로그 판정
- 자동화 ROI: -96% (비추천)
- 5계층 방어 시스템, 평균 2-8주 후 계정 정지
- 애드포스트 RPM 500-1,000원 vs 애드센스 RPM 2,000-8,000원
- 결론: 수동 고품질만, 수익화는 WordPress+애드센스 집중

## Tistory API
- 2024.02 서비스 종료 확인 → Playwright 필요
