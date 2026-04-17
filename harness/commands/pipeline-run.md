---
description: "7단계 품질 파이프라인 실행 (루프)"
---

# /pipeline-run — 7단계 품질 파이프라인 실행 (루프)

설치된 파이프라인을 실행하고, FAIL 시 자동으로 수정 → 재실행하는 루프를 돌립니다.

## 사전 조건
- `/pipeline-install`이 완료된 프로젝트에서 실행
- CLAUDE.md에 파이프라인 테이블이 존재해야 함
- TodoWrite에 Step 0~6이 등록되어 있어야 함 (없으면 자동 등록)

## 실행 절차

### 1. 파이프라인 상태 확인
```bash
# TodoWrite 상태 확인 — 어디까지 진행되었는지
# CLAUDE.md에서 파이프라인 유형 (A/B/C) 확인
```
- 이전 실행에서 중단된 Step이 있으면 해당 Step부터 재개
- 처음 실행이면 Step 0부터 시작

### 2. Step 순차 실행
각 Step을 순서대로 실행하며, 완료 시 TodoWrite를 `completed`로 업데이트.

---

**Step 0: 디자인 (UI 프로젝트만)**
- DESIGN.md 확인/생성 → `mcp__stitch__*` 또는 경쟁사 벤치마킹
- UI가 아닌 프로젝트(API, CLI 등)는 스킵
- 산출물: `DESIGN.md`
- 완료: TodoWrite step0 → completed

---

**Step 1: 구현**
- 코드 작성 + 린트 + 테스트 + 커밋
- 각 하위 작업 완료 시 TodoWrite 업데이트
- 기준: `npm test` 또는 프로젝트별 테스트 suite 통과

---

**Step 2: 품질 검수 (체크포인트)**
- Codex + GPT-4.1 병렬 호출 (무료, 5H/7D = 0)
  ```bash
  PROMPT="다음 코드 변경사항을 rules/quality.md 코드 검토 5패스 기준으로 검토하라. PASS/REWORK/FAIL 판정과 구체적 수정 항목을 출력: $(git diff HEAD~1 --stat | head -20)"

  # Codex 리뷰
  bash "$HOME/.claude/scripts/codex-rotate.sh" "$PROMPT" 2>&1 \
    | tee ~/.harness-state/pipeline_review_codex.log &

  # GPT-4.1 리뷰
  curl -s --max-time 30 http://localhost:414/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"gpt-4.1\",\"messages\":[{\"role\":\"user\",\"content\":\"$PROMPT\"}]}" \
    2>&1 | tee ~/.harness-state/pipeline_review_gpt41.log &

  wait  # 두 호출 완료 대기
  # 불일치 시 메인(Opus/GPT-4.1 메인)이 최종 판정
  ```
- **saturation 판정**: 두 모델 모두 수정 0건이면 완료. 어느 하나라도 FAIL이면 Step 1로 복귀
- 완료 시:
  ```bash
  echo '{"step":2,"tool":"codex+gpt41","verdict":"PASS","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' \
    > ~/.harness-state/pipeline_review_done
  ```
- 증거 파일 없으면 deploy hook이 차단

---

**Step 3: 시각 검수 (UI 프로젝트만, 체크포인트)**
- UI가 아닌 프로젝트는 스킵

  ```
  # 1. 데스크톱 스크린샷
  mcp__expect__open(url: "<로컬 또는 스테이징 URL>")
  mcp__expect__screenshot()

  # 2. 모바일 스크린샷
  mcp__expect__playwright(script: "page.setViewportSize({width:390,height:844})")
  mcp__expect__screenshot()

  # 3. 콘솔 에러 확인
  mcp__expect__console_logs(type: "error")

  # 4. 네트워크 에러 확인
  mcp__expect__network_requests()

  # 5. 접근성 감사
  mcp__expect__accessibility_audit()

  mcp__expect__close()
  ```

- Design Rubric 평가: Codex + GPT-4.1 병렬 호출 (무료)
  ```bash
  RUBRIC_PROMPT="Design Rubric(~/.claude/rules/design_rubric.md) 4축(Consistency/Originality/Polish/Functionality) 기준으로 각 0-10 점수와 PASS/REWORK/FAIL 판정을 JSON으로 출력하라. 스크린샷 결과: $(cat ~/.harness-state/pipeline_screenshot.log 2>/dev/null | head -5)"

  bash "$HOME/.claude/scripts/codex-rotate.sh" "$RUBRIC_PROMPT" 2>&1 \
    | tee ~/.harness-state/pipeline_rubric_codex.log &

  curl -s --max-time 30 http://localhost:414/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"gpt-4.1\",\"messages\":[{\"role\":\"user\",\"content\":\"$RUBRIC_PROMPT\"}]}" \
    2>&1 | tee ~/.harness-state/pipeline_rubric_gpt41.log &

  wait
  ```
  - 최저축 6점 미만 = FAIL → Step 1 복귀
  - 최저축 8점 이상 전체 = PASS

- 완료 시:
  ```bash
  echo '{"step":3,"rubric_min":8,"screenshot":"done","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' \
    > ~/.harness-state/pipeline_visual_done
  ```

---

**Step 4: 빌드**
- 빌드 명령 실행 (에러 0 확인)
  ```bash
  npm run build 2>&1 | grep -iE 'error|warn|fail' | head -50
  ```
- exit 0 확인 후 TodoWrite step4 → completed

---

**Step 5: 배포 + 스모크테스트**
- `firebase deploy` 실행
- `verify-deploy.sh` hook이 자동으로:
  - HTTP 200 확인
  - `pipeline_review_done` 증거 파일 존재 확인 (없으면 배포 차단)
  - `mcp__expect__*`로 심층 검증 지시 주입
- 핵심 기능 1개 이상 실제 동작 확인 (버튼 클릭, API 응답 등)

---

**Step 6: 최종 판정 (루프 판정)**
- Codex + GPT-4.1 병렬 최종 검수 (Step 2와 동일 방식, 라이브 배포 기준)
  ```bash
  FINAL_PROMPT="라이브 배포 후 최종 품질 판정. rules/quality.md 코드 검토 5패스 + 배포 스모크테스트 결과 기준. PASS 시 PIPELINE_COMPLETE 승인, FAIL 시 구체적 수정 항목 출력. 배포 URL 응답: $(cat ~/.harness-state/pipeline_deploy.log 2>/dev/null | tail -5)"

  bash "$HOME/.claude/scripts/codex-rotate.sh" "$FINAL_PROMPT" 2>&1 \
    | tee ~/.harness-state/pipeline_final_codex.log &

  curl -s --max-time 30 http://localhost:414/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"gpt-4.1\",\"messages\":[{\"role\":\"user\",\"content\":\"$FINAL_PROMPT\"}]}" \
    2>&1 | tee ~/.harness-state/pipeline_final_gpt41.log &

  wait
  ```
- UI 프로젝트: Step 3 스크린샷 재촬영 (라이브 URL 기준)
  ```
  mcp__expect__open(url: "<라이브 URL>")
  mcp__expect__screenshot()
  mcp__expect__playwright(script: "page.setViewportSize({width:390,height:844})")
  mcp__expect__screenshot()
  mcp__expect__close()
  ```
- **ALL PASS → 완료 보고 + `<promise>PIPELINE_COMPLETE</promise>`**
- **FAIL → Step 1로 복귀 (FAIL 항목만 수정)**

---

### 3. 루프 규칙
```
┌─ Step 0: 디자인 (UI만)
│  Step 1: 구현
│  Step 2: 품질 검수 ← 체크포인트 (pipeline_review_done)
│  Step 3: 시각 검수 ← 체크포인트 (pipeline_visual_done, UI만)
│  Step 4: 빌드
│  Step 5: 배포 + 스모크
│  Step 6: 최종 판정
│     ├─ ALL PASS → 완료 보고 + <promise>PIPELINE_COMPLETE</promise>
│     └─ FAIL → Step 1로 복귀 (FAIL 항목만 수정)
└──────────────────────┘
```

- **최대 루프 횟수**: 일반 20회, 경량(`--light`) 5회. 초과 시 대표님께 보고
- **루프 카운터**: `~/.harness-state/pipeline_loop_count` 에 기록
- **루프 시 체크포인트 증거 파일 초기화**: 매 루프마다 `pipeline_review_done`, `pipeline_visual_done` 재생성 필수
- **saturation 판정**: 1라운드 수정 0건이면 즉시 완료. 수정 있으면 2라운드 후 재판정

### 4. 경량 모드
인자로 `--light`를 전달하면 경량 파이프라인:
- Step 1 → Step 2 (1라운드) → Step 4 → Step 5 → Step 6
- 파일 3개 이하 소규모 수정에 적합
- Step 0(디자인), Step 3(시각 검수) 스킵

### 5. 완료 보고
루프 완료 시:
- 총 루프 횟수, 각 루프에서 수정된 항목 요약
- 최종 감사 점수: `bash ~/.claude/scripts/audit-session.sh --compact` 실행
- `echo "파이프라인 완료 — 루프 N회, 최종 감사 점수" > ~/.harness-state/last_result.txt`
- 텔레그램 알림 자동 전송 (Stop hook)

## 참고: /ultrareview (선택적 유료)
Claude Code v2.1.111 신규. **체험권 3회 후 과금.** 예산 여유 시 Step 2/6 대신 1회 호출로 대체 가능 (더 심층적인 멀티에이전트 리뷰). 기본 파이프라인에서는 무료 외부 모델(Codex + GPT-4.1, `:414`)을 사용.

## 증거 파일 참조표
| 파일 | 생성 시점 | hook 확인 |
|------|----------|----------|
| `~/.harness-state/pipeline_review_done` | Step 2 완료 | verify-deploy.sh, audit-session.sh |
| `~/.harness-state/pipeline_visual_done` | Step 3 완료 (UI만) | audit-session.sh |
| `~/.harness-state/pipeline_loop_count` | 루프마다 갱신 | — |
