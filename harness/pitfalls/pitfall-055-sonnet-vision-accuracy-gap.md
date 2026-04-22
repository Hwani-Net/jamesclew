# P-055: Sonnet Vision 정확도 부족 — Opus 라우팅 필요

**증상**: Sonnet 서브에이전트 또는 opusplan 실행 중 스크린샷 분석 시 세부 요소(로고 서브타이틀, 배지 종류, 행 개수 등) 20~30% 누락.

**원인**: Sonnet 4.6 Vision은 Opus 4.6 대비 디테일 식별 정확도 낮음. CLAUDE.md에 Vision 라우팅 규칙 부재.

**해결**: Vision이 필요한 모든 작업을 Opus로 라우팅. Sonnet teammate는 스크린샷을 파일에 저장 후 Opus 메인 세션에 SendMessage로 분석 위임.

**재발 방지**:
1. CLAUDE.md Multi-Model Orchestration에 "Vision 라우팅 규칙" 명시 (v2026-04-18 추가)
2. Computer Use / claude-in-chrome 작업은 ARIA snapshot 1차 → Opus Vision 2차 이중 패스 적용
3. `/design-review`, `/qa`는 이미 Opus 고정 유지
