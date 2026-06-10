# 블로그 자율발행 신뢰성 복구 — 설계 (2026-06-04)

감사(wf_f4b3a564) PARTIAL 판정 + 3영역 현황 실측 기반. 대표님 3건 채택.
인프라 변경 → Codex 교차검토 필수 (CLAUDE.md).

---

## A. G 결함 — critic 이미지 E2E 렌더 hard-gate (P0, 최우선)

### 문제
`openclaw-discord-loop-gate.js`의 `completionAllowed=true` 조건에 이미지 검증 입력이 0개.
텍스트 critic PASS만으로 '발행가능' 선언 → 제습기 v20에서 이미지 4장 깨짐 미감지 (P-194 9번째).

### 변경 1: openclaw-discord-loop-gate.js  [Codex/Sonnet review 반영]
- **의도 기반 opt-in** (정규식 false positive 회피): completion/return **메시지가 발행가능을 단언**할 때만 게이트 발동
  - 발행단언 감지 정규식: `/발행\s*가능|발행해도\s*(됩|좋)|publish[\s-]?ready|PASS\s*GO|배포\s*가능|발행\s*준비\s*완료/i`
  - "글", "draft" 같은 약한 단독 토큰 사용 금지 (false positive — logging/git draft 등)
- 입력: 신규 positional arg 추가 X. **기존 state 객체에 `imageRenderVerified` 필드**(boolean)를 읽음 (criticOk와 동일 경로). blog-review만 이 필드를 씀 → 호출자 변경 범위 = blog-review 1곳
- 규칙 (발행단언 감지된 경우만):
  - `state.imageRenderVerified === true` (엄격 boolean, 문자열 "true" 불인정) → 통과
  - 그 외 (false / undefined / 누락 / 문자열) → blockers.push('image_render_not_verified') + completionAllowed=false
- 발행단언 미감지 (인프라·대화·중간보고 등) → 이 게이트 완전 미적용 (하위호환 100%)

### 변경 2: blog-review.md Phase 4 (이미지 검증)
- 현재: 파일 존재 + HTTP 200 + Vision 주제 매칭
- 추가 (hard-gate): preview URL을 expect MCP로 열어 **DOM naturalWidth>0 실측** + **상대경로 src 잔존 검사** (`src="assets/` 또는 `src="/...` 상대경로면 FAIL — 절대 URL 또는 배포 후 유효 경로여야)
- Phase 0.5 (preview 서버 없음) fallback: 서버 없으면 **imageRenderVerified=false로 기록**(통과 금지)
- 결과를 gate state의 `imageRenderVerified` 필드에 boolean true/false로 기록

### 리스크/완화
- 하위호환: 발행단언 감지된 경우만 게이트 → 비발행 작업 영향 0
- 타입 안전: `=== true` 엄격 비교 (문자열/truthy 우회 차단)
- Phase 0.5 fallback이 차단으로 바뀌므로 preview 서버 기동을 검증 절차에 포함

---

## B. 원클릭 발행 승인 UX (P1)

### 현황
§14-B에 발행 7단계(dialog --accept → navigate → snapshot → type제목 → type본문 → 임시저장검증 → "완료"click) + "발행해" 트리거 이미 완비. 결재① 게이트 유지(보안).

### 변경: 결재 push 포맷 표준화 (ORCHESTRATION.md §14-B + workspace/AGENTS.md §Approval Channel)
결재 도달 시 nyongjong이 #결재-필요(1508626494711140444)에 push할 표준 포맷:
```
[발행 결재] <글 제목> v<N>
✅ 준비완료: 임시저장 / 이미지 렌더 PASS (naturalWidth>0, N장) / critic PASS (블로커 0)
🔗 미리보기: <티스토리 임시저장 preview URL 또는 로컬 preview HTTP URL>
📂 산출물: <절대경로>
➡️ 승인 시 자동 실행: "발행해" 회신 → JARVIS가 §14-B 7단계 자율 발행 (메인세션 개입 0)
   (Firebase 대상이면: deploy는 메인세션 — 별도 안내)
```
- 핵심: **미리보기 URL 필수** + **승인 시 무엇이 실행되는지 명시**
- 승인 문구 파싱: "발행해"/"승인"/"publish" → 즉시 §14-B 실행. 그 외(질문/수정요청)는 실행 X
- A의 이미지 렌더 PASS가 결재 push 전제조건 (미검증이면 결재 push 자체 불가)

### A→B 의존성 강제 [review 반영]
- 결재 push 생성 단계에서 `gate state.imageRenderVerified === true` 확인. false/미검증이면 **결재 push 자체 거부** + "이미지 렌더 미검증 — 발행 결재 불가" 회송. A 미배포 상태에서 B 단독 작동해도 미검증 콘텐츠가 결재 도달 불가.

### 리스크/완화
- 결재 게이트 자체는 유지 (제거 X — 보안 정책)
- Firebase 발행은 deploy가 메인세션 전용(P-222)이라 '발행해' 후에도 메인 호출 필요 — push에 명시

---

## C. P-206 cron 사멸 복구 — watchdog (P1)

### 현황 정정
17개 중 disabled 11개지만 **7개는 at-time one-shot 정상 만료**(rainy day1~7). 실제 error 4개. enabled 6개 RUNNING.
이미 `openclaw-worker-return-self-watchdog.timer`(3분 RUNNING) + WSL-KeepAlive(Running) 존재.

### 변경 1: cron error 자동 재시도 (신규 `openclaw-p206-cron-retry-watchdog.js`, 3분 timer)  [review 반영]
- 3분 주기로 jobs-state.json **읽기 전용 스캔** (직접 편집 X — race 회피)
- `enabled=true && lastRunStatus=error` cron 감지 → 재시도 카운터 +1
- re-enable/재발화는 **OpenClaw CLI 경유** (`openclaw cron run <id>` 또는 enable 명령) — jobs-state.json 직접 쓰기 금지 (atomic 보장은 gateway에 위임)
- 재시도 카운터·debounce는 **파일 영속화**: `~/.harness-state/cron-retry-debounce.json` (write tmp + rename atomic). watchdog 재시작해도 카운터 유지
- **재시도 max 3회** → 그래도 error면 `#결재-필요`에 "cron <id> 3회 실패, 수동 확인 필요" push + enabled 유지 (자동 비활성화 X = P-206 안티패턴 회피)
- 결재 push 실패 시: stderr 로그 + debounce 파일에 `escalation_failed: true` 기록 (다음 사이클 재시도, 무한 재발화는 막되 방치도 막음)
- **one-shot 제외 필터 = 날짜 정규식**: `/\d{8}|\d{4}-\d{2}-\d{2}|day\d/i` 매칭 시 재시도 대상 제외 (정상 만료). `once` 같은 약한 토큰 금지 (oncall 등 false positive)
- debounce: 동일 cron 재시도 간 최소 10분

### 변경 2: gateway 생존 watchdog (WSL-KeepAlive.vbs 확장)
- 기존 keepalive(sleep infinity)에 추가: 3분마다 `systemctl --user is-active openclaw-gateway` 체크
- inactive → `openclaw-gateway-restart.path` 트리거 파일 write (이미 있는 메커니즘 재사용)
- 이미 P-223/P-224에서 만든 keepalive 인프라 확장이라 신규 데몬 최소화

### 리스크/완화
- 3분 watchdog + keepalive 중복 → restart 폭주: debounce 10분 필수
- error 무한 재시도 방지: max 3 + 결재 push (자동 OFF 대신 사람 통지)
- one-shot 오인 재시도: 이름 패턴 필터

---

## 적용 순서 (의존성)
1. **A** (독립, 최우선) — loop-gate + blog-review
2. **B** (A 의존 — 이미지 PASS가 결재 전제) — ORCHESTRATION + AGENTS
3. **C** (독립) — watchdog 확장

각 변경: 백업 → 수정 → 검증(loop-gate는 단위 테스트) → STICKY 등록.
모두 WSL2 절대경로(P-218). blog-review.md만 Windows harness.
