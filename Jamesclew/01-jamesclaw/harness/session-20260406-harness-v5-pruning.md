# Session 2026-04-06 — Harness v5: Pruning + QA + Pipeline-Run

## 핵심 성과

### 1. 하네스 Pruning (업계 분석 기반)
- CLAUDE.md: 90줄 → 57줄 (업계 권장 60줄 이하 달성)
- Stop hook: 5개 → 1개 디스패처 (stop-dispatcher.sh)
- PostToolUse Write/Edit: 5개 → 1개 디스패처 (post-edit-dispatcher.sh)
- 업계 7개 출처 분석 (Anthropic 공식, HumanLayer, Vercel, Philschmid, ETH Zurich, harn.app, 한국 개발자)

### 2. 감사 스크립트 확장 (10→23항목)
- 추가: 불가선언금지, Multi-Pass, PITFALLS기록, Conventional Commits, 하네스직접수정, 에러재시도, Design Reference, External Model Call, Tool Priority, Cost Logging, Search-Before-Solve, Screenshot Verify, Pipeline Loop
- Stitch 텍스트 매칭 오탐 수정 (P-014)
- step7 증거 파일 100byte 미만 차단 (P-015)

### 3. 새 커맨드
- `/pipeline-run` — 11단계 실행 + FAIL→수정 루프 (일반 20회, 경량 5회)
- `/qa` — 외부 모델 사용자 관점 QA 루프 (로컬 루프 → 배포 1회 → 라이브 비교)
- `/audit` — 23항목 감사 (세션 ID 지정 가능)

### 4. Build Transition Guard 강화
- enforce-build-transition.sh: prd_done + pipeline_done + plan_done 3단계 체크
- user-prompt.ts: 빌드 키워드 감지 → build_detected + 주입
- enforce-execution.sh: 3회 연속 block 후 강제 통과 (데드락 방지)
- PRD 질문 단계 예외 추가

### 5. State 디렉토리 이전
- `~/.claude/hooks/state/` → `~/.harness-state/` (sensitive file 권한 문제 해결)
- 19개 파일 경로 일괄 변경

### 6. MCP 체계 확정
- lazy-mcp: Windows 비호환 확정 (P-021, cargo 빌드 미지원, 하위 서버 spawn pipe 끊김)
- lazy-mcp-win 자체 개발 시도 → MCP 2-way 프로토콜 제약으로 보류
- korean-law: 온디맨드 직접 등록 (-e OPEN_API_KEY=gpt-korea)
- NotebookLM: 직접 등록 (상시)

### 7. 외부 모델 자문
- Codex, Antigravity, Gemini 3모델 합의: mid-pipeline checkpoint BLOCK 찬성
- prescriptive 에러 메시지 + 1-2회 self-correction 허용

### 8. Self-Evolve 감사 연동
- self-evolve.sh에 감사 FAIL 이력 분석 추가
- session-start.ts에 audit_top_fails 경고 주입 (거울→학습 루프)

### 9. 기타
- ralph-loop 플러그인 활성화 + 한글화 복원 (P-017)
- 알림음 chimes.wav 설정
- 시작프로그램 정리 (D:\Agent 관련 VBS 4개 제거)

## PITFALLS 추가
- P-013: PRD/pipeline 무조건 자동 강제 시도
- P-014: 감사 텍스트 매칭 오탐
- P-015: step7 증거 파일 조작
- P-017: 플러그인 한글화로 슬래시 커맨드 문제
- P-018: .claude/settings.json 백슬래시 이스케이프
- P-019: QA 루프 반복 망각
- P-020: 기존 프로젝트 재진입 시 파이프라인 체크 누락
- P-021: lazy-mcp Windows 비호환

## 하네스 3계층 확립
- 울타리 (hook 차단): PRD/pipeline/plan 없이 코딩 차단, step5/7 없이 deploy 차단
- 가이드 (규칙 주입): CLAUDE.md 57줄, rules/ 3파일
- 거울 (감사): 23항목 점수화, self-evolve→session-start 연동

## 다음 세션 할 일
- 대시보드 프로젝트 QA (/qa 적용)
- BiteLog 프로젝트 재개
- 블로그 10→20편 확장
- P-020 해결 (기존 프로젝트 재진입 시 state 자동 생성)
