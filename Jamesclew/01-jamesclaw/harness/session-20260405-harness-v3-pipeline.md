---
name: Session 2026-04-05 Harness v3 + Pipeline Automation
description: 하네스 구조적 강제, 블로그 품질 검수 자동화, 파이프라인 엔드투엔드 완성
type: project
---

## 완료 작업

### 도구 스택 구축
- agent-browser 0.23→0.24.1 업그레이드 (좀비 프로세스 수정)
- desktop-control (computer-use-mcp) 등록 + 동작 확인 (스크린샷/마우스/키보드)
- 외부 모델 다양화: llm-judge.mjs에 Antigravity+Codex+Gemini 3모델 + Vision API
- Opus+Sonnet 서브에이전트 이미지 교차 검증 체계 (36개 전수 검증)
- korean-law-mcp lazy-mcp 등록
- Perplexity 4도구 해제 (search/ask/research/reason) + 비용 벤치마크 ($0.006 vs $0.80)

### 블로그 품질 검수
- 9개 글 6패스 정적 검사 2라운드 saturation
- loading="lazy" 전체 제거 (PITFALLS P-001)
- og:image CDN 방식 발견 → 800x800 순수 제품 이미지
- 이미지 크기 통일 CSS 500px center
- H3 페인포인트 패턴, 가격 유연화, 글자수 보강, 내부링크 삽입
- ainic iSA7: 쿠팡 ID 수정 (8261559131→6149115912)

### 하네스 v3 — 구조적 강제
- 새 hook 4건: evidence-first.sh, enforce-review.sh, error-telegram.sh, "할까요?" 패턴
- 온디맨드 MCP: user-prompt.ts 도메인 감지 + enforce-execution.sh npm search 강제
- loop-detector: Read/Agent/Glob/Grep 제외 (오탐 방지)
- CLAUDE.md 102줄→52줄 압축 (hook 태그 참조)
- 규칙 관리 원칙: rules/에 상세, CLAUDE.md는 참조만
- PITFALLS.md P-001~P-009 구조화
- ADR 도입 (docs/adr/ADR-001)
- Pre-Compact Snapshot hook (자동 git 상태 기록)
- 피드백 감지 패턴 5→10개 확장 + 텔레그램 채널 감지 추가

### 파이프라인 자동화
- pipeline.mjs 11단계 엔드투엔드: Generate→SEO→Quality Loop→Image Capture→Cross Review→Firestore→Build(CSS+SSG)→Deploy→Browser Verify
- Step 11: Playwright direct (daemon 대신 lifecycle 제어)
- capture-images.mjs: og:image CDN→Playwright→agent-browser 3단계 cascade
- Tailwind CDN→static build (300KB runtime→35KB CSS)

### 플러그인 도입
- skill-creator, code-simplifier, hookify, ralph-loop 활성화

### 추가 도입
- 외부 모델 기본 매핑 (자율 변경 허용)
- 에러 유형별 참고 지식
- API 비용 추적 (log-api-cost.sh)
- context_pct 파일 기록 (user-prompt.ts)

## 다음 세션 TODO
1. 블로그 글 추가 발행 (9편→20-30편, 생활용품/뷰티 카테고리)
2. 파이프라인 실전 테스트 (새 글을 처음부터 끝까지)
3. 텔레그램 피드백 감지 실전 검증 (reload 후)
4. context_pct 파일 기록 검증 (reload 후)
5. harness_design.md 최종 업데이트 확인

## GitHub 커밋
- jamesclew: 624b91b → 0d42cfd → ... → 175b184 (harness v3)
- smartreview-blog: ee1f9c2 → ... → 1865693 (pipeline + image fixes)
