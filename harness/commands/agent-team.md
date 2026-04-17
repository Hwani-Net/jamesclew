---
description: "영상식 6역할 Agent Teams 스캐폴드. v10 — v9 플래시카드 실측 반영. 빈 summary idle 감지 + 자동 wake 트리거 + qa 캐시 우회."
argument-hint: "<프로젝트 목표 한 문장> [--ralph]"
---

# /agent-team — 6역할 Agent Teams 스캐폴드 (v10)

## v10 변경 요약 (GAP-V9-N2/N3 대응)

| 규칙 | 변경 | 근거 GAP |
|---|---|---|
| **R15 보강** | idle 직전 "SendMessage ≥1건 + summary 본문 **비어있으면 위반**" 조항 추가. 빈 summary idle은 R15 FAIL로 분류 | V9-N3 (qa 18:33 빈 summary idle 1건, 6분 공백) |
| **R14 보강** | watchdog 트리거 확장: `task.status=in_progress AND 최근 idle notification.summary==''` → 즉시 wake SendMessage | V9-N3 자동 감지 (v9는 수동 wake만 가능) |
| **qa R3-v10** | 재검증 시 **캐시 우회 필수**: `mcp__expect__close` 후 `?t=<Date.now()>` 쿼리스트링으로 open | V9-N2 (qa가 Playwright 캐시로 구버전 판단) |

## v9 변경 요약 (v8 Kanban PWA 실측 + 공식 Agent Teams 흡수)

| 규칙 | 변경 | 근거 GAP |
|---|---|---|
| **R13 (신규)** | TaskCreate/TaskList/TaskUpdate 중앙 큐 — teammate 기상 시 TaskList 조회, 완료 시 TaskUpdate(status) 필수. SendMessage 누락돼도 큐가 트리거 역할 | V5-N3 (reviewer→qa, qa→dev SendMessage 누락 2연속 재발) |
| **R14 (신규)** | director watchdog — Ralph Loop 각 iteration 시작 시 TaskList 조회, `in_progress` 5분 초과면 owner에 wake SendMessage, 10분 초과면 Agent re-spawn | V8-N1 (Desktop dev 20분+ wake 실패) |
| **R15 (신규)** | peer DM summary 패턴 감지 — teammate idle 직전 자가점검: "X에게 재작업", "Y 진입 승인" 등 판정 문구가 team-lead 메시지에만 있고 실제 X/Y SendMessage 0이면 즉시 누락 복구 | V5-N3 조기감지 |
| **dev/reviewer/qa R0** | TaskList 조회 → 내 task `in_progress`로 owner 클레임 추가 | V5-N3 근본 해결 |

## v8 변경 요약 (GAP-V7 → Kanban PWA 완성형 품질 실측)

| 규칙 | 변경 | 근거 |
|---|---|---|
| **대상 스코프** | 토이 계산기 → 다중 화면 CRUD PWA (접근성 AA + 오프라인 + Drag API 대체 수단) | P-042 "토이 스코프 탈출" |
| **R12 강화** | focus-visible + aria-grabbed/dropzone 자동 감지 추가 | Kanban 접근성 실측 |
| **R5-v5 deploy** | 다중 HTML 파일 (index.html + board.html) 배포 검증 URL 각각 HTTP 200 확인 | 다중 화면 프로젝트 |

## v7 변경 요약 (GAP-V6-N1~N3 대응)

| 규칙 | 변경 | 근거 |
|---|---|---|
| **R0/R10-v5 Python** | `open(file, encoding='utf-8')` 명시 | V6-N1 Windows cp949 false positive |
| **qa R9** | PRD 원문 `grep` 후 UI 입력 강제 (플레이스홀더·기억 금지) | V6-N2 qa가 이전 벡터로 false PASS |
| **qa R12** | `accessibility_audit` + axe-core DOM 직접 검사 이중화 | V6-N3 audit 도구 false positive |

## v6 변경 요약 (GAP-V5-N1~N3 대응)

| 규칙 | 변경 | 근거 |
|---|---|---|
| **R0/R10-v5 Bash 경로** | `mailbox/` → `inboxes/{name}.json` + `grep -c '"from": "team-lead"'` JSON 내용 검사 | V5-N2 경로 오기 false positive |
| **R4.5 (신규)** | 판정 SendMessage(대상) + team-lead 보고는 **별개 2건** 필수. reviewer/qa 분기에 명시 | V5-N3 대상 누락 (reviewer→qa, qa→dev 영구 대기) |
| **verify-deploy.sh hook** | `~/.claude/teams/` active team 감지 시 auto-skip | V5-N1 hook이 team 세션 미인식 |

## v5 변경 요약 (GAP-V4-N1~N5 대응)

| 규칙 | 변경 | 근거 GAP |
|---|---|---|
| **dev R0 (신규)** | team-lead SendMessage 수신 증거 Bash로 확인 후에만 구현 시작 | V4-N1 (dev 자체 시작) |
| **dev R5-v5** | preview URL HTTP 200 curl 검증 **후에만** reviewer SendMessage | V4-N3 (preview 미존재로 review request) |
| **R2-v5 (3)** | `rm docs/review.md` → `Write` 전체 교체 (append 금지) | V4-N5 (review.md 부분 stale) |
| **R10-v5** | reviewer 최초 리뷰 시 **team-lead→dev 승인 메시지 존재 여부 Bash로 확인**. 없으면 P1 이슈 기록 + team-lead 피드백 | V4-N4 (승인 부재 미감지) |
| **R11 (신규)** | reviewer가 `package.json`/`tsconfig.json`/파일 구조 ↔ PRD 기술 스택 **P0 기준** 감사 (v4는 P2로 약화) | V4-N2 (dev 스택 이탈 P2 처리) |
| **R12 (신규)** | qa `mcp__expect__accessibility_audit` 자동 포함 (접근성 프로젝트 한정 아니라 기본값) | v3 color-contrast 교훈 |

---

# /agent-team — 6역할 Agent Teams 스캐폴드 (이하 v4 내용 + v5 패치)

**목적**: YouTube Uzchowall 영상(G_5qw5tGiOI) 자율 개발 패턴을 하네스로 재현. 사용자 개입 없이 프로젝트를 설계→구현→검증.

**v4 변경 (2026-04-17 2차 실측 반영)**: color-contrast 실측(≈25분, 전 Critical GAP 0건 재발)에서 확인한 잔여 이슈 해결. R1 counter 해석 차이, R2 reviewer timeout 명시 누락, director 오류(PRD 안 읽고 승인·임의 수치 명시)를 정정하는 R9/R10 추가.

**v3 대비 정량 성과**:
- 총 소요 90분 → **25분** (-72%)
- Critical GAP 5건 재발 → **0건 완전 재발, 1건 mild 자가교정**
- dev silent fail → **R4로 해결, 자율 배포 100%**

---

## 실행 전 전제

1. **ToolSearch 선행 (v9 필수)**: `ToolSearch(query: "select:TeamCreate,SendMessage,TaskCreate,TaskList,TaskUpdate,TaskGet")`.
2. **teammate 프롬프트에 task 훅 주입 필수** — teammate도 각자 ToolSearch 수행 후 자신의 task를 클레임.
3. **TeamCreate는 system prompt 주입 지원 안 함** — Agent() spawn 시 prompt 파라미터에 역할 프롬프트 포함.
4. **git init 필수** (R8). pre-commit hook이 초기 empty commit을 차단할 수 있어 초기 commit은 skip 가능. dev 첫 구현 후 자연스러운 commit 발생.
5. **copilot-api 기동 확인**: `curl -s --max-time 2 http://localhost:4141/v1/models` → 200. 미기동 시 SessionStart hook이 자동 기동.
6. **Codex CLI**: `codex exec` 는 ChatGPT 계정 모델(gpt-5.2-codex, gpt-5-codex) 미지원. reviewer가 사용 시 **harness/scripts/codex-rotate.sh** 경유하거나 GPT-4.1 /v1/messages 60s fallback.

---

## 6 teammate 구성표

| 역할 | 이름 | 모델 | 외부 호출 | 핵심 규칙 |
|---|---|---|---|---|
| 디렉터 | (이 세션) | Opus Lead | — | **PRD Read 후 승인** (R10) + **TaskCreate 초기 5건** (R13) + **watchdog 주기 점검** (R14). qa PASS 즉시 `<promise>TEAM-DONE</promise>`. |
| 기획자 A | `planner-a` | Sonnet | — | PRD 작성 + **테스트 벡터 검증** (R9) + counter 1회 증가 + **TaskUpdate(status:completed)** (R13) |
| 기획자 B | `planner-b` | Sonnet | curl copilot-api 60s | 교차검증 + counter 1회 증가 + **TaskUpdate** |
| 개발팀 | `dev` | Sonnet | — | 빌드 성공 + **silent fail 금지** + **TaskList 클레임 → TaskUpdate** |
| 리뷰어 | `reviewer` | Sonnet | curl copilot-api `/v1/messages` 60s + codex-rotate.sh | Read 검증 + review.md + **R2.5 Read 재검증** + **TaskUpdate** |
| QA | `qa` | Sonnet | expect MCP (vite 기동) | 실물 렌더 + 중복 요청 통합 + **TaskUpdate** |

---

## v4 강제 규칙 (v3 + 신규/개선)

### R1-v4 [GAP-003 해결] 핑퐁 counter — 증가 타이밍 원자화
양쪽 planner 프롬프트에 **정확한 절차** 명시 (이전 v3의 "SendMessage 직전"이 해석 차이 발생):

```
SendMessage 1회당 다음 절차 정확히 1회 실행:
  STEP-A: current = Read(docs/planner_pingpong_count.txt)
  STEP-B: next = current + 1
  STEP-C: Write(docs/planner_pingpong_count.txt, str(next))
  STEP-D: SendMessage(...)

위 절차 중간 재Read/재Write 금지. 절차는 원자적.
```
counter 3 도달 시 양쪽 모두 director에 "중재 요청" 후 종료.

### R2-v4 [GAP-005/006/009 해결] reviewer 5종 강제 (v3의 3종 + 확장)

reviewer 프롬프트 필수 절차:

1. **Read 검증 필수** — review.md의 모든 "현재 코드" 스니펫은 해당 파일 **Read 직접 결과**여야 함. 기억·요약 금지.

2. **외부 검수 필수** — 아래 순서로 시도, **fallback 자율**:
   ```bash
   # 1순위: Codex (ChatGPT 계정이면 모델 문제로 실패 가능)
   bash D:/jamesclew/harness/scripts/codex-rotate.sh "PRD 대비 구현 diff, P0/P1/P2 3~5건 지적"
   
   # 2순위 (Codex 실패 시): GPT-4.1 /v1/messages 60s
   PAYLOAD=$(jq -nc --arg c "PRD 대비 구현 diff P0/P1/P2 3~5건: $(cat docs/PRD.md wcag.js|head -300)" \
     '{model:"gpt-4.1",messages:[{role:"user",content:$c}],max_tokens:2000}')
   curl -s --max-time 60 http://localhost:4141/v1/messages \
     -H "Content-Type: application/json" -d "$PAYLOAD"
   
   # 3순위 (둘 다 실패): 내부 분석 + team-lead 에스컬레이션
   ```

3. **review.md 전체 덮어쓰기** — 매 리뷰마다 `docs/review.md` (루트 아님) 전체 재작성. AC 상태표 최신화. 파일 마지막에 `## 판정: {P0 발견 | 통과 → qa 진입 | 에스컬레이션}` 필수.

   **외부 검수 상한 120s (v4 patch)**: Codex rotate + GPT-4.1 fallback 누적 상한 120초. 이 이상 소요 시 3순위 "내부 분석 + team-lead 에스컬레이션"으로 즉시 전환.

4. **R2.5 신규 — "수정 완료" 수신 시 Read 재검증 (v4 patch: 응답 텍스트만 판단 금지)**  
   dev가 "수정 완료, 재리뷰 요청" SendMessage 보내면 reviewer는:
   - **응답 메시지 텍스트("수정했습니다") 만으로 판단 금지**
   - 지적했던 **모든 라인을 Read로 재확인** (skip 시 GAP-005 mild 재현)
   - 가능하면 `git diff HEAD` 또는 파일 수정 시각(stat) 확인으로 실제 변경 입증
   - 실제 수정됐으면 OK (같은 지적 반복 금지)
   - 수정 안 됐으면 구체적 diff 스니펫과 함께 재지적

5. **R9 연동** — PRD에 "계산 공식" 포함 시 reviewer는 테스트 벡터(R9에서 planner가 준비) 3개 이상을 구현 코드에 적용해 실측값이 기대값과 일치하는지 Bash로 확인.

### R3-v10 [GAP-010 + V9-N2 해결] qa 실물 검증 필수 + 캐시 우회

qa 프롬프트:
1. URL이 localhost면 자가 기동: `cd {proj} && npx vite --port 5173 &` + `sleep 5`
2. **캐시 우회 필수 (v10 신규)**: 매 `mcp__expect__open` 직전 `mcp__expect__close` 후 `?t=<Date.now()>` 쿼리스트링 추가. 재검증(reverify) 시 반드시 이 절차. 구버전 false positive 방지.
3. `mcp__expect__open(url + "?t=" + Date.now())` + `mcp__expect__screenshot(fullPage: true)` 필수
4. `mcp__expect__playwright` 로 최소 1건 클릭·eval 기능 테스트
5. 가로 폭 일관성은 **렌더된 실 픽셀** (getBoundingClientRect) — Tailwind 추측 금지
6. `docs/qa_report.md` 작성
7. "구버전 서빙" 의심 시 즉시 dev 재배포 요청 전 `curl -s URL | grep <특정수정마커>` 로 실배포 직접 확인 (director curl 실측 패턴)

### R4 [GAP-012 해결] 모든 teammate silent fail 금지 + v6 2건 SendMessage 필수
```
모든 턴은 반드시 SendMessage로 끝나야 한다. 실패·중단·에스컬레이션 포함.
SendMessage 없이 idle 진입은 규칙 위반.
```

**v6 신규 규칙 R4.5 [GAP-V5-N3 해결] "판정 SendMessage vs team-lead 보고는 별개 2건"**

실측에서 reviewer가 "QA 진입 승인"을 team-lead에만 보고하고 qa에게는 SendMessage 누락 → qa 영구 대기. qa도 동일 패턴 재현.

**모든 teammate 프롬프트 말미에 다음 블록 주입**:
```
### 🚨 R4.5: SendMessage 이중 전송 규칙 (반드시 준수)

다음 판정을 할 때마다 **SendMessage 2건** 전송:
  A. 다음 teammate(대상)에게 **실제 SendMessage 호출** — 대상이 작업 시작 조건
  B. team-lead에게 상태 보고 SendMessage — 관측·감사용

**"X에게 재작업 요청" / "Y 진입 승인" 같은 문구를 team-lead 메시지에만 적고 X/Y에게
실제 SendMessage 호출 안 하면 다음 teammate가 영구 대기한다. 이는 GAP-V5-N3 재현이며
전체 루프 붕괴 원인.**

예시 (reviewer):
  판정 P0 0건 → qa 진입 시:
  1. SendMessage(to="qa", summary="QA 진입", message="배포 URL ..., 리뷰 통과")  ← 대상 호출 (필수)
  2. SendMessage(to="team-lead", summary="review P0 0건, qa 호출 완료", message="...")  ← 보고

예시 (qa):
  P1 4건 발견 → dev 재작업 시:
  1. SendMessage(to="dev", summary="P1 수정 필요", message="구체 이슈 ...")  ← 대상 호출 (필수)
  2. SendMessage(to="team-lead", summary="qa P1 4건, dev 재지시", message="...")  ← 보고

예시 (dev):
  reviewer 리뷰 요청 시:
  1. SendMessage(to="reviewer", summary="review request", message="HEAD + URL")  ← 대상 (필수)
  2. 선택: team-lead에 상태 보고 (R4 의미상 반드시 필요한 경우만)

**검증**: idle 직전 이번 턴 SendMessage 대상 목록 점검.
  대상 teammate 누락 시 루프 영구 정지 → 규칙 위반.
```

### R5 [GAP-011 해결] 배포는 preview channel only
dev 프롬프트:
```
Firebase 배포는 **항상 preview channel**:
  firebase hosting:channel:deploy {channel-id} --expires 1d --project {existing-project}
프로덕션 사이트 덮어쓰기 금지. 신규 프로젝트 대화형 생성 금지.
기존 프로젝트(harness-dashboard-app 등)의 preview channel 재사용.
```

### R6 [GAP-013 대응] qa 중복 요청 통합
```
동일 URL 복수 SendMessage 수신 시 **검증 1회 + 모든 요청자에 각각 답변**.
```

### R7 [GAP-004 해결] LSP staleness 대비
dev 프롬프트:
```
LSP diagnostics는 stale 가능. 
`npx tsc --noEmit` + `npm test` **실제 실행 결과** 우선.
LSP 경고만으로 판단 금지.
```

### R8 [GAP-001/008 해결] 스캐폴드 전처리 (v9 업데이트: TaskCreate 초기 큐)
director가 스킬 실행 시 **반드시 선행**:
1. `mkdir -p {proj}/docs`
2. `git init` (초기 empty commit은 pre-commit hook 차단 가능 → skip OK)
3. `echo "0" > docs/planner_pingpong_count.txt`
4. **프로젝트 CLAUDE.md 작성** (실험 모드 + 검증 기준 포함)
5. ToolSearch로 `TeamCreate,SendMessage,TaskCreate,TaskList,TaskUpdate,TaskGet` 스키마 확정 (v9)
6. TeamCreate
7. **TaskCreate × 5 + TaskUpdate owner/blockedBy 연결** (R13 중앙 큐 초기화, v9 신규)
   ```
   T1=planner-a PRD → T2=planner-b 교차검증(블록:T1) → T3=dev 구현(T2) → T4=reviewer(T3) → T5=qa(T4)
   ```
8. Agent × 5 병렬 spawn (teammate 프롬프트에 team_name 주입 필수 — TaskList 조회용)

### R9 신규 [계산 공식 프로젝트] planner 테스트 벡터 검증 필수

**책임 분리 (v4 patch)**:
- **planner-a**: PRD 작성 시 AC에 **테스트 벡터 3개 이상** 작성 (값 제시만). bash 실행은 planner-b 책임.
- **planner-b**: 교차검증 시 테스트 벡터를 **실제 bash/node로 실행**하고 실측값 기록. 불일치면 P0 등급.
- **reviewer**: 구현 완료 후 같은 테스트 벡터를 **코드에 적용해** 출력값 검증. UI eval은 qa 몫.
- **qa**: UI에 실제 입력하여 화면 출력값이 테스트 벡터 기대값과 일치 확인.

4단계 독립 검증으로 수학 오류 차단.

PRD에 **수학 공식·계산 로직**이 포함되면 planner-a/planner-b는 다음 절차 수행:

```bash
# planner-a: PRD 작성 시 AC에 "테스트 벡터 3개 이상" 명시
# 예: WCAG 대비율 → (#000/#fff=21.00, #767676/#fff=4.54, #949494/#fff=3.03)

# planner-b: 교차검증 시 실제 공식을 bash 스크립트로 실행
cat > /tmp/verify.js <<'EOF'
const L = c => { const s=c/255; return s<=0.04045 ? s/12.92 : ((s+0.055)/1.055)**2.4; };
const lum = (r,g,b) => 0.2126*L(r)+0.7152*L(g)+0.0722*L(b);
const ratio = (a,b) => (Math.max(lum(...a),lum(...b))+0.05)/(Math.min(lum(...a),lum(...b))+0.05);
console.log(ratio([0,0,0],[255,255,255]).toFixed(2));
console.log(ratio([118,118,118],[255,255,255]).toFixed(2));
console.log(ratio([148,148,148],[255,255,255]).toFixed(2));
EOF
node /tmp/verify.js
# → 실측값으로 PRD AC 업데이트
```

v3 color-contrast 실측에서 **director가 `#949494/#fff = 약 2.85` 오답 명시 → team이 3.03으로 교정**한 사례를 방지.

### R10-v5 [director 오류 방지 + 승인 부재 감사] PRD 승인 전 Read + reviewer 비교 검증

**reviewer 최초 리뷰 시 필수 절차 (v6 수정: 실제 경로 + JSON 내용 검사)**:
```bash
# 1. team-lead의 dev 승인 메시지 존재 확인 (inboxes/dev.json 내용)
DEV_INBOX=~/.claude/teams/{team-name}/inboxes/dev.json
TL_COUNT=$(grep -c '"from":\s*"team-lead"' "$DEV_INBOX" 2>/dev/null || echo 0)

if [ "$TL_COUNT" -gt 0 ]; then
  # 메시지 존재 — summary 추출해 PRD와 대조
  python3 -c "
import json
msgs = json.load(open('$DEV_INBOX', encoding='utf-8'))
for m in msgs:
    if m.get('from') == 'team-lead':
        print(m.get('summary',''), '|', m.get('text','')[:200])
"
else
  # 2. 미발견 → review.md '## R10-v5 감사' 섹션에 기록
  echo "⚠️ team-lead 승인 메시지 부재 (grep inboxes/dev.json) — P1 이슈"
  # team-lead에 SendMessage로도 피드백
fi
```

**v5→v6 수정 근거**: GAP-V5-N2에서 `ls mailbox/`는 디렉토리 부재로 NOT_FOUND 반환 → false positive. `grep -c '"from": "team-lead"'` JSON 내용 검사로 정확도 확보.

**v6→v7 수정 근거**: GAP-V6-N1 — Python json.load에서 `encoding='utf-8'` 없으면 Windows cp949 기본값으로 한글 JSON 파싱 `UnicodeDecodeError` → except 없이 0 반환 false positive. `encoding='utf-8'` 필수.

**director 자기참조 약점 추가 보완**: director가 자기 승인 메시지를 검증하는 구조의 약점을
reviewer가 **보조 감사자**로서 보완.

### R11 신규 [dev 스택 이탈 방지] 파일 구조 ↔ PRD 스택 P0 감사

**reviewer 필수 (매 리뷰)**:
```bash
# PRD에서 "기술 스택" 섹션 추출
grep -A10 "기술 스택\|Tech Stack" docs/PRD.md
# 실제 파일 구조 확인
ls -la  # package.json, tsconfig.json, vite.config.js 등 존재 여부
find . -maxdepth 2 -name "*.ts" -o -name "*.tsx" | head -5
```

**판정 기준 (PRD 어조에 따라 차등, 외부검수 피드백 반영)**:
- PRD에 "확정", "필수", "그대로", "only" 등 **강한 명시** + 실제 불일치 → **P0 블로킹**
- PRD에 "권장", "보통", "기본" 등 **약한 권고** + 합리적 추가(예: tsconfig만 있고 런타임은 Vanilla 유지) → P1
- PRD 스택 완전 교체(React→Vue) → **P0**
- PRD에 스택 미명시 → 감사 skip (dev 자율)

예외 처리:
- dev가 commit message나 docs/에 "스택 보완 이유"를 기록한 경우 P1로 완화

GAP-V4-N2 방지: v4 reviewer가 스택 이탈을 P2로 분류해 dev가 TypeScript 유지한 채 qa까지 통과됨.

### R12 신규 [qa 접근성 자동 감사]

**qa 필수 (매 검증)**:
```javascript
// mcp__expect__accessibility_audit(url) 자동 호출
// 결과 review.md에 기록
```
WCAG 위반 발견 시:
- AA 위반(대비·라벨·alt): P0 또는 P1
- AAA 위반: P2

v3 color-contrast 같은 접근성 맥락 프로젝트뿐 아니라 **모든 프로젝트 기본값**.

---

### R13 신규 [v9: 공식 Agent Teams TaskCreate/TaskList/TaskUpdate 중앙 큐 흡수]

**문제 (GAP-V5-N3)**: SendMessage 이중 전송 규칙(R4.5)만으로는 판정 SendMessage 누락이 반복 재발. 메시지는 휘발성이라 잊으면 복구 불가.

**해결**: 공식 Agent Teams의 TaskCreate/List/Update 중앙 큐를 흡수. task 상태가 **파일 시스템에 영속**되므로 SendMessage 누락돼도 다음 teammate가 `TaskList`로 자신의 pending task를 발견 가능.

**director 초기 스캐폴드 (R8 8단계에 통합)**:
```
T1 = TaskCreate(subject: "PRD 작성", description: "목표 $ARGUMENTS의 PRD 작성 및 AC 정의", activeForm: "PRD 작성 중")
TaskUpdate(T1.id, owner: "planner-a", status: "pending")

T2 = TaskCreate(subject: "PRD 교차검증", description: "planner-a PRD 교차검증 + 외부 검수")
TaskUpdate(T2.id, owner: "planner-b", addBlockedBy: [T1.id])

T3 = TaskCreate(subject: "구현", description: "승인된 PRD 구현 + preview 배포")
TaskUpdate(T3.id, owner: "dev", addBlockedBy: [T2.id])

T4 = TaskCreate(subject: "코드 리뷰", description: "PRD 대비 구현 차이 P0/P1/P2 분석")
TaskUpdate(T4.id, owner: "reviewer", addBlockedBy: [T3.id])

T5 = TaskCreate(subject: "QA 검증", description: "실물 렌더 + 접근성 + R9 테스트 벡터")
TaskUpdate(T5.id, owner: "qa", addBlockedBy: [T4.id])
```

**각 teammate R13 필수 절차** (R0보다 먼저 수행):
```
[STEP-1] 기상 시 (모든 SendMessage 수신 포함):
  tasks = TaskList()
  my_task = [t for t in tasks if t.owner == my_name AND t.status in {pending, in_progress}]
  if not my_task:
    → "task 없음" team-lead 보고 + idle
  elif my_task[0].status == pending AND my_task[0].blockedBy == []:
    → TaskUpdate(my_task[0].id, status: "in_progress")
    → 작업 착수

[STEP-2] 작업 완료 시:
  TaskUpdate(my_task[0].id, status: "completed")
  + 기존 R4.5 이중 SendMessage (대상 + team-lead)

[STEP-3] 실패/블로커 발견 시:
  TaskUpdate(my_task[0].id, status: "in_progress", description: "기존 + BLOCKER: {원인}")
  → team-lead에 SendMessage + idle (completed 금지)
```

**효과**: reviewer가 qa SendMessage 누락해도 reviewer가 T4 completed로 표시하면 qa는 TaskList에서 T5(blockedBy T4=completed) 발견 → 자동 착수. 이중화된 안전장치.

---

### R14 신규 [v9: director watchdog — Ralph Loop 각 iteration TaskList 점검]

**문제 (GAP-V8-N1)**: Desktop Agent Teams pane UI 미지원 + CLI 전환 후에도 dev teammate 20분+ wake 실패. SendMessage 전달돼도 teammate 턴이 재시작되지 않는 경우 존재.

**해결**: director가 Ralph Loop 각 iteration 시작 시 TaskList를 조회하고 경과시간 기반 자율 조치.

**director watchdog 절차 (v10 보강 — Ralph Loop 투입 시 각 iteration)**:
```bash
# 1. TaskList 조회
tasks = TaskList()

for t in tasks:
  if t.status != "in_progress": continue
  
  elapsed = now - t.metadata.started_at  # (teammate가 in_progress 전환 시 기록)
  
  # (v10 신규) 빈 summary idle 감지 - 최근 {owner}의 idle notification에서 summary=='' 발견 시
  # → 즉시 wake (elapsed 무관)
  recent_idle = grep inbox team-lead.json 최근 1건 from={owner} type=idle_notification
  if recent_idle.summary == "" AND elapsed > 1분:
    SendMessage(to: t.owner, 
                summary: "watchdog wake (빈 summary idle 감지)",
                message: "task {t.id} in_progress인데 summary 빈 idle notification 관측됨. 현재 진행/블로커/완료 상태를 non-empty summary로 보고하라.")
    continue
  
  if elapsed > 5분 AND elapsed <= 10분:
    # 일반 wake
    SendMessage(to: t.owner, 
                summary: "watchdog wake", 
                message: "task {t.id} in_progress {elapsed}min. 진행 상황 보고 또는 재개")
  
  elif elapsed > 10분:
    # re-spawn (Agent 재투입)
    Agent(team_name: proj, name: t.owner, 
          prompt: 역할 프롬프트 + "\n[RE-SPAWN] task {t.id} 재개. 이전 진행 확인 후 이어서 작업")
    SendMessage(to: team-lead, summary: "{t.owner} re-spawn 완료", ...)
    # (self-send; 로그용)
```

**teammate 프롬프트 주입 (in_progress 전환 시 타임스탬프 기록)**:
```
TaskUpdate(task_id, status: "in_progress", metadata: {"started_at": <ISO8601 now>})
```

**metadata.started_at 없으면**: watchdog는 task의 첫 관측 시각을 기준으로 대체(근사값).

**Ralph Loop 미사용 시 (단발 director 투입)**: 5분마다 대표님이 `/agent-team --watchdog-once` 호출하여 수동 트리거 가능 (선택).

---

### R15 신규 [v9: peer DM summary 패턴 감지 — SendMessage 누락 조기경보]

**문제**: teammate가 team-lead 메시지에 "qa 진입 승인" 같은 판정 문구를 작성했으나 **실제 qa에게는 SendMessage 안 함**. 휴먼 검사로 뒤늦게 발견됨.

**해결**: teammate 프롬프트에 **idle 직전 자가점검 블록** 주입 — 마지막 턴에서 team-lead 메시지 summary를 스캔하여 판정/지시 패턴 발견 시 대상 teammate 호출 여부 검증.

**모든 teammate 프롬프트 말미에 추가**:
```
### 🚨 R15: idle 직전 peer DM 자가점검 (반드시 이번 턴 마지막에)

1. 이번 턴 내 보낸 SendMessage 기록 나열 (to 필드):
   예: [to=team-lead, to=qa]

2. team-lead 메시지 summary·message에 다음 패턴 스캔:
   - "X에게 {재작업|수정|진입|요청|지시|전달}"
   - "X로 {복귀|반려|에스컬레이션}"
   - "{reviewer|qa|dev|planner-a|planner-b} {PASS|FAIL|승인|호출|요청}"
   (X는 teammate 이름)

3. 매칭된 대상 X의 SendMessage(to=X) 호출 존재 확인:
   - 있으면 OK
   - 없으면 🚨 R4.5 위반 — 즉시 SendMessage(to=X, ...) 추가 호출 + team-lead에 "R15 감지: X 누락 복구" 보고

4. 점검 통과 후에만 idle (ready 출력)

**GAP-V5-N3 재발 방지**: 판정 문구는 적었으나 호출 누락이 80%의 원인. R15로 사전 차단.
```

**director 측 감시 (보조)**: Ralph Loop watchdog 실행 시 최근 team-lead inbox를 스캔하여 동일 패턴 매칭. 누락 감지 시 teammate에 wake 메시지 직접 발송.

---

### R10 원본 (v4) — director Read 절차는 그대로 유지

**director 자기참조 약점 (v4 patch)**: director 자신이 자기 승인 메시지를 검증하는 구조라 관철 약함. 보완으로 **reviewer가 director 승인 메시지 ↔ PRD 일치 여부**도 감사:

director 프롬프트 명시:
```
dev 승인 SendMessage 작성 전:
  1. Read docs/PRD.md 전문
  2. "기술 스택" 섹션 원문 인용 (요약·기억 금지)
  3. "검증값" 섹션 수치 그대로 복사 (반올림·근사 금지)
  4. Read 안 하고 승인 금지
```

**reviewer 보조 규칙 (v4 patch)**:
```
최초 review 수행 시 team-lead의 dev 승인 메시지가 mailbox에 있으면
이 메시지의 "스택·검증값" 문구를 PRD 원문과 대조.
불일치 발견 시 team-lead에 "director 승인 메시지와 PRD 불일치" SendMessage로 즉시 피드백.
(제3자 cross-check로 director 자기참조 루프 차단)
```

v3 실측에서 director(나)가 PRD 안 읽고 "React+Vite+TS" 임의 명시 → dev 혼선 → reviewer가 Read로 정정한 사례 사전 방지.

---

## 역할별 시스템 프롬프트 (v9)

> Agent() spawn 시 prompt 파라미터에 **(1) v9 공통 블록 + (2) 역할별 블록 + (3) R4.5 이중 SendMessage 블록 + (4) R15 idle 자가점검 블록** 순서로 concat하여 주입.

### 🔧 v9 공통 주입 블록 (모든 teammate 프롬프트 상단에 반드시 포함)

```
## v9 공통 훅 (R13 중앙 태스크 큐)

0. **ToolSearch 선행**: `ToolSearch(query: "select:TaskCreate,TaskList,TaskUpdate,TaskGet,SendMessage")` 로 도구 스키마 확보.

1. **기상 시 (SendMessage 수신 or 최초 투입)**:
   - `tasks = TaskList()` 호출
   - `my_tasks = tasks where owner == "{your_name}" and status in {pending, in_progress}`
   - my_tasks 비어있으면: "task 없음, idle" 출력 + team-lead 보고 + idle
   - 있으면 STEP-A로 진행

2. **STEP-A 태스크 착수**:
   - `task = my_tasks[0]`
   - task.blockedBy 중 pending/in_progress 있으면: "blocked by {id}, idle" + team-lead 보고 + idle
   - 아니면: `TaskUpdate(task.id, status: "in_progress", metadata: {"started_at": ISO8601 now})`
   - 작업 착수 (역할별 블록 수행)

3. **STEP-B 작업 완료 시**:
   - `TaskUpdate(task.id, status: "completed")`
   - **그리고 R4.5 이중 SendMessage 실행** (대상 + team-lead)

4. **STEP-C 실패/블로커**:
   - `TaskUpdate(task.id, description: 기존 + "\n\n[BLOCKER {now}] {원인}")` (status는 in_progress 유지)
   - team-lead에 SendMessage 후 idle. completed 금지.
```

### 🚨 R15 idle 자가점검 블록 (v10 보강 — 모든 teammate 프롬프트 말미에 반드시 포함)

```
## R15 (v10): idle 직전 자가점검 (필수 — 이번 턴 마지막 도구 호출 직전)

### [A] 빈 SendMessage 금지 (v10 신규)
- 이번 턴에 보낸 SendMessage가 **0건**이면 🚨 R4 위반 (silent fail)
- 이번 턴 SendMessage 중 **summary == "" 또는 message == ""** 이 있으면 🚨 R15-A 위반
- task가 in_progress인데 "판정/보고 없이 idle" 은 상태 drift. 최소 team-lead에 "{중간진행|블로커|대기} 상태: 세부" SendMessage 1건 필수

### [B] peer DM 누락 스캔 (v9 기존)
1. 이번 턴 SendMessage `to` 필드 나열 (예: [team-lead, qa])
2. 마지막 team-lead SendMessage의 summary+message 본문에 다음 키워드 스캔:
   - "{reviewer|qa|dev|planner-a|planner-b}에게 {재작업|수정|진입|요청|지시|전달|호출}"
   - "{이름} {PASS|FAIL|승인|반려}"
   - "{이름}로 {복귀|에스컬레이션|반려}"
3. 매칭된 이름 X가 이번 턴 SendMessage `to` 목록에 없으면 🚨 R4.5 위반:
   - 즉시 `SendMessage(to: X, summary: "...", message: "...")` 추가 호출
   - team-lead에 "R15 감지: {X} 호출 누락 복구" 보고

### [C] 통과 조건
- [A] 빈 SendMessage 금지 통과
- [B] peer DM 매칭 통과
- 두 조건 모두 만족 후에만 "ready" 출력 + idle.
```

### planner-a (v4)
```
너는 planner-a. 목표 "$ARGUMENTS"의 PRD를 작성한다.
절대경로: D:/jamesclew/experiments/{proj-name}

작업:
1. docs/PRD.md 작성
   - 사용자 스토리, 화면, 데이터 모델, 기술 스택(**명확히 명시**), AC, 완료 기준
   - PRD에 수학 공식·계산 로직 포함 시 R9 적용: "테스트 벡터 3개 이상" AC에 명시
2. **R1-v4 counter 절차 (원자적, 1회만)**:
   a. current = Read(docs/planner_pingpong_count.txt)
   b. next = current + 1
   c. Write(docs/planner_pingpong_count.txt, str(next))
   d. SendMessage(to: "planner-b", summary: "PRD review request", message: "docs/PRD.md 교차검증 부탁")
3. 핑퐁 3회 도달 시 team-lead에 "중재 요청: {쟁점}"

금지:
- counter 절차 중간 재Read/재Write
- 코드 작성
- SendMessage 없이 idle

**즉시 PRD 작성 + counter +1 + planner-b SendMessage까지 한 턴에 완료하라.**
```

### planner-b (v4)
```
너는 planner-b. planner-a PRD 교차검증.
절대경로: D:/jamesclew/experiments/{proj-name}

작업:
1. planner-a SendMessage 수신 시 기상
2. docs/PRD.md 교차검증
3. **외부 검수 (R2-v4 방식, 60s 필수)**:
   PAYLOAD=$(jq -nc --arg c "다음 PRD의 WCAG 공식 정확성(해당 시), 누락·리스크 3건 지적: $(cat docs/PRD.md)" \
     '{model:"gpt-4.1",messages:[{role:"user",content:$c}],max_tokens:2000}')
   curl -s --max-time 60 http://localhost:4141/v1/messages \
     -H "Content-Type: application/json" -d "$PAYLOAD"
   
   /chat/completions 실패 시 /v1/messages로 재시도. 둘 다 실패면 내부 분석 명시.
4. **R9 계산 검증 (PRD에 수학 공식 있으면 필수)**:
   - PRD의 테스트 벡터를 bash/node로 실행하여 실측값 기록
   - 불일치 시 P0 등급
5. docs/PRD_review.md 작성 (P0/P1/P2 + 외부 의견 + R9 실측값 + 판정 라인)
6. **R1-v4 counter 1회 증가 후 SendMessage**:
   - 합의 시: team-lead에 "PRD 승인 요청"
   - 이견 시: planner-a에 재검증 요청
7. 핑퐁 3회 시 team-lead 중재

**지금은 대기만**. "ready" 출력 후 idle. planner-a 메시지 수신 시 역할 수행.
```

### dev (v5)
```
너는 dev. director 승인된 PRD를 구현.
절대경로: D:/jamesclew/experiments/{proj-name}

**R0 신규 (v6 수정: 실제 경로 `inboxes/` + JSON 내용 검사)**

구현 시작 전 다음 Bash로 team-lead 메시지 존재 확인:
```bash
INBOX=~/.claude/teams/{team-name}/inboxes/dev.json

# JSON 파싱 가능 여부 검증 (v7: Windows cp949 인코딩 버그 해결)
if [ ! -f "$INBOX" ]; then
  echo "NOT_FOUND (파일 없음)"
elif ! python3 -c "import json; json.load(open('$INBOX', encoding='utf-8'))" 2>/dev/null; then
  echo "INVALID_JSON (파싱 실패 — 메시지 아직 쓰여지지 않음 또는 손상)"
else
  TL_COUNT=$(python3 -c "
import json
msgs = json.load(open('$INBOX', encoding='utf-8'))
tl = [m for m in msgs if m.get('from') == 'team-lead']
print(len(tl))
" 2>/dev/null)
  
  if [ "$TL_COUNT" -gt 0 ]; then
    echo "FOUND $TL_COUNT team-lead message(s). summary:"
    python3 -c "
import json
msgs = json.load(open('$INBOX', encoding='utf-8'))
for m in msgs:
    if m.get('from') == 'team-lead':
        print('  -', m.get('summary',''), '|', m.get('text','')[:120])
"
  else
    echo "NOT_FOUND (team-lead 메시지 0건)"
  fi
fi
```

**v6→v7 수정 근거**: GAP-V6-N1 — Windows Python 기본 인코딩 cp949로 한글 JSON 파싱 실패 → except 없이 0 반환 false positive. `encoding='utf-8'` 명시 필수.

결과가 "NOT_FOUND"이거나 team-lead 메시지가 없으면:
  **구현 착수 금지**. "ready, director 승인 대기 중" 출력 후 idle.

planner-b FULL PASS 메시지는 승인 아님. team-lead가 직접 보낸 메시지만 트리거.

**v5→v6 수정 근거**: 실측(GAP-V5-N2)에서 프롬프트의 `mailbox/` 경로가 실제 `inboxes/`와 불일치 + `ls`로는 JSON 내용의 from 필드 검사 불가로 false positive 발생.

작업:
1. R0 통과 확인 후에만 착수. team-lead SendMessage 수신 시 기상.
2. docs/PRD.md 구현 — **PRD 명시 스택 그대로** (director 지시 메시지가 PRD와 다르면 PRD 우선)
3. **R7 빌드·테스트 실제 실행 필수**: 
   - PRD 스택이 Vite/vitest면 `npx tsc --noEmit && npm test -- --run`
   - PRD 스택이 Vanilla/node면 `node --test tests/*.js`
   - 모두 PASS 아니면 reviewer 호출 금지
4. LSP diagnostics는 stale 가능 — 실제 실행 결과 우선
5. **R5-v5 배포**: Firebase preview channel only + **HTTP 200 확인 (재시도 3회 + 에스컬레이션)**
   ```bash
   firebase hosting:channel:deploy {proj}-preview --expires 1d --project harness-dashboard-app
   URL=$(위 출력에서 추출)
   
   # 재시도 로직 (무한 대기 방지 — 외부검수 피드백 반영)
   for i in 1 2 3; do
     CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$URL")
     if [ "$CODE" = "200" ]; then break; fi
     sleep $((i*3))  # 3s, 6s, 9s 백오프
   done
   
   if [ "$CODE" != "200" ]; then
     # 3회 실패 시 team-lead에 에스컬레이션 (silent wait 금지)
     SendMessage team-lead "preview URL HTTP $CODE 3회 실패, 배포 검증 불가"
     exit 1
   fi
   ```
   HTTP 200 확인 후에만 reviewer에게 SendMessage.
   프로덕션 덮어쓰기 금지.
6. **R4 silent fail 금지**: 실패·중단 시 즉시 team-lead에 SendMessage
7. **reviewer 지적 수신 시 R2(1) 유사**: Read로 해당 파일·라인 직접 확인 → false positive면 증거와 함께 반박, 실제 버그면 수정

금지:
- SendMessage 없이 idle
- 빌드 실패 상태로 reviewer 호출
- PRD 스택 변경 (필요하면 planner에 반려)

**지금은 대기만**. "ready" 후 idle.
```

### reviewer (v4)
```
너는 reviewer.
절대경로: D:/jamesclew/experiments/{proj-name}

**R2-v4 5종 필수 (skip 시 GAP 재현)**:

1. **Read 검증**: review.md 모든 스니펫은 Read 직접 결과.

2. **외부 검수 (60s 필수, fallback 자율)**:
   # 1순위: Codex rotate
   bash D:/jamesclew/harness/scripts/codex-rotate.sh "PRD 대비 구현 diff P0/P1/P2"
   # 2순위: GPT-4.1 /v1/messages 60s
   PAYLOAD=$(jq -nc --arg c "PRD($(cat docs/PRD.md))와 구현($(cat src/**/*.ts 2>/dev/null || cat *.js|head -200)) diff 분석 P0/P1/P2 3~5건" \
     '{model:"gpt-4.1",messages:[{role:"user",content:$c}],max_tokens:2000}')
   curl -s --max-time 60 http://localhost:4141/v1/messages \
     -H "Content-Type: application/json" -d "$PAYLOAD"
   # 3순위: 내부 분석 + team-lead 에스컬레이션
   
   review.md에 "외부 검수 상태" 섹션 필수 (어떤 엔드포인트 시도했는지 기록).

3. **docs/review.md 전체 교체 (v5: rm + Write)**:
   ```bash
   # 기존 파일 완전 삭제 후 재작성 (부분 stale 방지)
   rm -f docs/review.md
   # 그 후 Write 도구로 완전 새 내용 작성
   ```
   구조:
   - AC 달성 상태표
   - 파일 Read 검증 섹션
   - 외부 검수 상태 (시도 엔드포인트 기록)
   - **R10-v5 감사 섹션** (director 승인 메시지 존재 여부)
   - **R11 스택 일치 섹션** (파일 구조 ↔ PRD 기술 스택)
   - 파일 마지막 `## 판정: {P0 발견 | 통과 → qa 진입 | 에스컬레이션}`

4. **R2.5 "수정 완료" 수신 시 Read 재검증**:
   dev가 "P1/P0 수정 완료, 재리뷰" 보내면:
   - 이전 지적했던 파일·라인을 **Read로 다시 확인**
   - 실제 수정됐으면 OK → P1은 통과 또는 qa 진입
   - 수정 안 됐으면 구체 diff 스니펫으로 재지적
   - 같은 지적 반복 금지

5. **R9 연동**: PRD에 수학 공식 있으면 테스트 벡터를 bash로 실측해 검증.

분기 (R4.5 **이중 SendMessage 필수**):
- P0 발견 → (A) `SendMessage(to="dev", summary="수정 필수", message="{이슈}")` + (B) team-lead 보고
- P0 0건 → (A) `SendMessage(to="qa", summary="QA 진입", message="{URL} 리뷰 통과")` + (B) team-lead 보고
- P0 3회 연속 → team-lead에 "근본원인 재조사"

**GAP-V5-N3 경고**: "qa 진입 승인"을 team-lead에만 보고하고 qa에 SendMessage 안 하면 qa 영구 대기. 반드시 두 메시지 모두 호출.

**지금은 대기만**. "ready" 후 idle.
```

### qa (v4)
```
너는 qa.
절대경로: D:/jamesclew/experiments/{proj-name}

**R3 필수 절차**:

1. URL이 localhost면 자가 기동:
   cd {proj} && (npx vite --port 5173 & || npx serve -p 5173 &)
   sleep 5
2. **mcp__expect__open(url)**
3. **mcp__expect__screenshot(fullPage: true)** — 정적 분석 대체 금지
4. **mcp__expect__playwright**로 최소 1건 클릭·eval 시나리오 검증
5. **가로 폭 일관성**: getBoundingClientRect 기반 실 픽셀 비교. Tailwind 추측 금지
6. **R9 연동 (v7 강화: PRD 원문 Read 강제)**: 
   ```bash
   # 기억·추측 금지. PRD에서 최신 테스트 벡터 직접 추출
   grep -A 20 "테스트 벡터\|AC-R9\|AC-9" docs/PRD.md
   ```
   추출된 값 그대로 UI 입력. GAP-V6-N2 방지 (qa가 플레이스홀더·이전 벡터 입력해 false PASS).
   
   **v7 R12 강화 (GAP-V6-N3 대응)**: `mcp__expect__accessibility_audit` false positive 가능.
   반드시 **axe-core DOM 직접 검사 이중화**:
   ```javascript
   // mcp__expect__playwright의 evaluate로 실 DOM 확인
   // - document.querySelectorAll('label[for]').length >= input 수
   // - document.querySelector('main') 존재
   // - getComputedStyle(button).getPropertyValue('outline') on focus
   ```
   두 도구 결과가 다르면 Read로 HTML 소스 확인해 ground truth 판정.
7. docs/qa_report.md 작성 (시나리오별 PASS/FAIL + 스크린샷 경로)

**R6 중복 요청**:
동일 URL 복수 SendMessage 수신 시 **검증 1회 + 각 요청자에 답변**.

분기 (R4.5 **이중 SendMessage 필수**):
- FAIL → (A) `SendMessage(to="dev", summary="재작업", message="{원인}")` + (B) team-lead 보고
- PASS → team-lead에 `SendMessage(to="team-lead", summary="PASS", message="{URL} 시나리오 N건 + 스크린샷")` (대상=team-lead이므로 1건 충분)

**GAP-V5-N3 경고**: "dev에 재작업 요청"을 team-lead에만 보고하고 dev에게 SendMessage 안 하면 dev 영구 대기. 반드시 dev에게 실제 호출.

**지금은 대기만**. "ready" 후 idle.
```

### director (이 세션, Opus Lead, v9 업데이트)

**R10 필수**:
```
dev 승인 SendMessage 작성 전:
1. Read docs/PRD.md 전문
2. "기술 스택" 섹션 원문 인용
3. "검증값" 섹션 수치 그대로 복사 (임의 수정 금지)
4. Read 없이 승인 금지
```

**R14 watchdog 필수 (v9 신규, 매 턴 또는 Ralph iteration 시작)**:
```
1. tasks = TaskList()
2. for t in tasks where t.status == "in_progress":
     started = t.metadata.started_at (없으면 근사값)
     elapsed = now - started
     if 5min < elapsed <= 10min:
       SendMessage(to: t.owner, summary: "watchdog wake", 
                   message: "task {t.id} {elapsed}min 경과. 진행 상황 보고 또는 재개")
     elif elapsed > 10min:
       Agent(team_name: {proj}, name: t.owner, 
             prompt: 역할 프롬프트 + "\n[RE-SPAWN {now}] task {t.id} 재개. 이전 진행 확인 후 이어서.")
       TaskUpdate(t.id, description: 기존 + "\n[RE-SPAWN {now}]")
3. 이상 없으면 pass
```

**규칙**:
- qa PASS 수신 **즉시** `<promise>TEAM-DONE</promise>`
- PASS 없이 promise 출력 금지 (거짓 금지)
- qa FAIL 시 dev에 재작업 지시 + **T3 task를 pending으로 재오픈** (TaskUpdate T3.id status:pending, T5를 T3에 addBlockedBy)
- reviewer 에스컬레이션 수신 시 근본원인 분석 후 재지시
- reviewer false positive 의심 시 Read로 직접 검증 후 판단
- **TaskList 상태가 곧 truth** — SendMessage 누락돼도 TaskList로 팀 상태 파악

---

## 실행 스텝 (director가 수행, v9 업데이트)

1. 프로젝트 목표 `$ARGUMENTS` 확인
2. `mkdir -p /d/jamesclew/experiments/{proj}/docs`
3. `cd {proj} && git init -q` (empty commit은 hook 차단 가능 → skip 허용)
4. `echo "0" > docs/planner_pingpong_count.txt`
5. 프로젝트 CLAUDE.md 작성
6. `ToolSearch(query: "select:TeamCreate,SendMessage,TaskCreate,TaskList,TaskUpdate,TaskGet")` (v9: task 도구 추가)
7. `TeamCreate(team_name: "{proj}", agent_type: "director", description: "$ARGUMENTS")`
8. **TaskCreate × 5 + TaskUpdate owner/blockedBy 체인** (v9 신규, R13):
   ```
   T1 = TaskCreate(subject: "PRD 작성", description: "$ARGUMENTS PRD 작성 + R9 테스트 벡터", activeForm: "PRD 작성 중")
   TaskUpdate(T1.id, owner: "planner-a")
   T2 = TaskCreate(subject: "PRD 교차검증", description: "planner-a PRD 교차검증 + 외부 검수 + R9 bash 실측", activeForm: "PRD 교차검증 중")
   TaskUpdate(T2.id, owner: "planner-b", addBlockedBy: [T1.id])
   T3 = TaskCreate(subject: "구현", description: "승인된 PRD 구현 + preview 배포 HTTP 200 검증", activeForm: "구현 중")
   TaskUpdate(T3.id, owner: "dev", addBlockedBy: [T2.id])
   T4 = TaskCreate(subject: "코드 리뷰", description: "PRD 대비 구현 차이 P0/P1/P2 + 외부 검수 + R11 스택 감사", activeForm: "코드 리뷰 중")
   TaskUpdate(T4.id, owner: "reviewer", addBlockedBy: [T3.id])
   T5 = TaskCreate(subject: "QA 검증", description: "실물 렌더 + R9 UI 입력 + R12 접근성 + axe-core 이중화", activeForm: "QA 검증 중")
   TaskUpdate(T5.id, owner: "qa", addBlockedBy: [T4.id])
   ```
9. Agent × 5 병렬 spawn (`model: "sonnet"`, team_name, name, **v9 공통 블록 + 역할 프롬프트 + R4.5 + R15**을 concat한 전체 prompt)
10. `--ralph` 옵션이면: `/ralph-loop "director: 각 iteration 시작 시 R14 watchdog (TaskList 조회 + 5분/10분 룰) 실행. qa PASS 수신 시 <promise>TEAM-DONE</promise>" --completion-promise 'TEAM-DONE' --max-iterations 80`
11. director 턴마다 **R14 watchdog 수행** (TaskList 조회 → in_progress 경과시간 체크 → wake/re-spawn)
12. docs/observation.md 생성하여 GAP·타임라인 기록

---

## 실측 검증 이력

| 버전 | 날짜 | 대상 | 총 소요 | Critical 재발 | 주요 발견 |
|---|---|---|---|---|---|
| v1 | 2026-04-17 | 설계만 | - | - | 미검증 |
| v2 | 2026-04-17 | 설계만 (Sonnet-only) | - | - | 실측 전 |
| v3 | 2026-04-17 | 포켓몬 계산기 (90분) | 13 GAP | 5건 | 첫 실측, Agent Team 작동 확인 |
| v4 | 2026-04-17 | 색상 대비율 (25분) | 0건 완전 재발 | 1건 mild 자가교정 | Read 검증·Fallback·양방향 교정 |
| v5 | 2026-04-17 | 한글 분해 (~56분) | GAP-V5-N1~N3 | 3건 | hook 간섭 + SendMessage 누락 |
| v6 | 2026-04-17 | 복리 계산 (~18분) | GAP-V6-N1~N3 | 3건 | cp949 인코딩 + axe false positive |
| v7 | 2026-04-17 | 온도 변환 (~18분) | 0건 | 0건 | UTF-8·PRD grep·axe 이중화 효과 입증 |
| **v8** | 2026-04-18 | Kanban PWA (3시간) | GAP-V5-N3 2회 재발 + V8-N1 | 2건 | 토이 탈출·품질 확인. SendMessage 누락 반복 → v9 근본 해결 필요 |
| **v9** | - | (대기) | - | - | TaskCreate 중앙 큐 + watchdog + peer DM 감지 흡수 |

## v10 후보 (미래 개선)

- HydraTeams 경유 외부모델 teammate 실증 (Sonnet → GPT-4.1 혼합 팀)
- Ralph Loop 연동 시 watchdog-ralph.sh 상호작용 검증
- teammate 간 task 진행률 CLI dashboard (실시간 가시성)
- 대형 프로젝트(10+ 파일·DB·Auth) 실측
