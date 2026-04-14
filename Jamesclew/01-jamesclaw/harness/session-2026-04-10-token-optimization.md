# Session: 토큰 최적화 + 외부 모델 도입 (2026-04-10)

## 주요 성과

### 1. Ultraplan 통합
- CLAUDE.md Build Transition Rule에 `/ultraplan` 추가
- 새 프로젝트: `/prd` → `/pipeline-install` → `/ultraplan` (Deep Plan)
- 중간 복잡도: `/ultraplan` (Simple/Visual)
- fallback: 로컬 `/plan`

### 2. expect MCP 통합
- `.mcp.json`에 expect MCP 서버 등록
- `.claude/skills/expect/SKILL.md` 생성
- quality.md Post-Deploy, 코드 Pass 4, 디자인 Pass 5에 `/expect` 삽입

### 3. GSD-2 평가 (보류)
- 3모델 교차검증 (Antigravity + Perplexity + Codex)
- 결론: pipeline-install/cost → COEXIST, pipeline-run → 마이그레이션 후 전환
- /prd, /qa, /저장 → KEEP

### 4. 토큰 절감 (A~D 완료)
- A: Hook 28→22개 병합 + 출력 50자 축소 (9개 스크립트)
- B: /compact 65%→45% + 옵시디언 백업 선행
- C': Subagent model: sonnet
- D: Multi-Pass 포화 가속 (수정 0건→1라운드 완료)

### 5. 외부 모델 인프라
- Codex 6계정 등록 + 멀티계정 로테이션 구현
- Antigravity 4계정 (stayicon, hwanizero01, hwanizero07 + 신규)
- evaluator.sh 5단계 로테이션: codex → opencode → ollama 31b cloud → glm flash → backoff
- Gemma 4 26B/31B cloud/E4B 실측 테스트 완료

### 6. Gemma 4 테스트 결과
- 26B MoE 로컬: 216초 (12GB VRAM 부족, CPU offload) → 비실용적
- 31B Cloud: 48초 + 품질 우수 → 실용적
- E4B 로컬: 107초 → 느림

### 7. Claude Advisor 전략 도입
- settings.json에 `advisorModel: "claude-opus-4-6"` 추가
- Sonnet(executor) + Opus(advisor) 패턴으로 토큰 절감 예정

### 8. 기타
- P-012: Sonnet 전환 시 context 차이 간과
- P-013: "다음 세션" 발언 시 컨텍스트 미확인 → hook 추가
- P-014: 새 기술 리서치 시 학습 데이터 의존
- keybindings.json 형식 오류 수정
- 줄바꿈: `\` + Enter 사용 (Shift+Enter VS Code에서 불안정)

## 후속 세션 성과 (compact 이후)

### 9. Nyongjong 하네스 비교 분석
- C:\Nyongjong (Antigravity 하네스) 전체 탐색
- 채택: 하향 나선 금지, advisor 게이트, cost warning 임계값
- 기각: PITFALLS JSON화 (15건에 과잉), 5단계 evaluator (3단계로 축소)
- 핵심: Nyongjong 95% confidence = JamesClaw에서 행동 규칙으로 번역

### 10. GLM-4.7-Flash 평가 → 폐기
- Z.AI 가입 + API 키 발급 완료
- Free tier: concurrency 1, 즉각 rate limit → evaluator fallback 비실용적
- evaluator.sh에서 제거: 5→3+1→3단계 (codex→opencode→backoff)

### 11. Advisor 패턴 검증
- Sonnet 전환 + advisor() 호출 → Opus 응답 확인 (동작 검증)
- P-013: 128K context에서 45% compact = 57K → 하네스 엔지니어링에 부적합
- 최종: Opus 메인 유지, Sonnet은 코딩 전용 (compact 제한 없음)

### 12. Dual Model Strategy 확정
- Opus (기본): 하네스 엔지니어링, 긴 분석. 1M, 45% compact
- Sonnet + Advisor: 코딩/배포/수정. 128K, auto compact

### 13. MCP 수정
- expect: npx → cmd/c → npx.cmd → node direct → expect init (최종 동작)
- stitch: cmd /c 래퍼 추가 → Connected
- expect /mcp UI 재연결은 여전히 실패 (claude mcp list에서는 Connected)

### 14. 커밋 8건
- 9478b33: multi-model rotation + expect MCP
- d811a8e: downward spiral block + cost warning + evaluator 3+1
- bb86df8: PITFALLS dedup + enforce-execution false positive
- bcd622f: GLM free tier 제거
- c47e3e6: 3가지 토큰 최적화 반영
- f3c6dd7: dual model strategy
- 814ba3d: .mcp.json cmd /c wrapper
- b42e5ba: project-level expect config 제거

## 미비 작업
- [ ] expect MCP `/mcp` UI 재연결 문제 (CLI에서는 동작)
- [ ] Sonnet 코딩 세션 실전 테스트
- [ ] `/cost` 측정으로 토큰 절감 효과 확인
- [ ] Persona 확장 루프 연결 (enhance-personas.mjs)
- [ ] Ollama Pro 재검토 (배포 빈도 증가 시)
