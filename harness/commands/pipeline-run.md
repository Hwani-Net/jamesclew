# /pipeline-run — 11단계 품질 파이프라인 실행 (루프)

설치된 파이프라인을 실행하고, FAIL 시 자동으로 수정 → 재실행하는 루프를 돌립니다.

## 사전 조건
- `/pipeline-install`이 완료된 프로젝트에서 실행
- CLAUDE.md에 파이프라인 테이블이 존재해야 함
- TodoWrite에 Step 0~11이 등록되어 있어야 함 (없으면 자동 등록)

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

**Step 0: 디자인 (UI 프로젝트만)**
- DESIGN.md 확인/생성 → Stitch MCP 또는 벤치마킹
- 산출물: `DESIGN.md`
- 완료: TodoWrite step0 → completed

**Step 1~4: 구현 단계**
- 프로젝트 유형에 따라 코드작성/린트/테스트/커밋
- 각 Step 완료 시 TodoWrite 업데이트

**Step 5: 품질루프 (체크포인트)**
- 5패스 실행. 수정 0건이면 1라운드로 완료, 수정 있으면 2라운드
- 완료 시: `echo "패스별 결과" > ~/.harness-state/step5_quality_done`
- FAIL 시: 수정 → Step 5 재실행 (self-correction 최대 2회)

**Step 6: 스크린샷/이미지**
- Playwright 주요 화면 캡처 또는 이미지 검증

**Step 7: 교차검수 (체크포인트) + Design Rubric 평가**
- 외부 모델 실제 호출 필수 (codex exec / opencode run)
- UI 프로젝트: `$HOME/.claude/rules/design_rubric.md` 기반 4축 등급 평가 강제
- 완료 시:
  ```bash
  RUBRIC=$(cat $HOME/.claude/rules/design_rubric.md)
  codex exec "$RUBRIC\n\n위 rubric으로 현재 구현 평가. JSON 출력." \
    2>&1 | tee ~/.harness-state/step7_review_done
  ```
- 증거 파일 100byte 미만이면 deploy hook이 차단
- 최저축 점수가 6점 미만이면 Step 7 FAIL → 구현 수정 후 재실행

**Step 8: 빌드**
- `npm run build` 또는 해당 빌드 명령 실행
- 에러 0 확인

**Step 9~10: 배포 + 스모크테스트**
- `firebase deploy`
- 라이브 URL HTTP 200 + **핵심 기능 1개 이상 실제 동작 확인**

**Step 11: 최종 검증 (루프 판정)**
- Playwright 데스크톱+모바일 스크린샷 Read
- 디자인 5패스(레이아웃/타이포/시각/인터랙션/렌더링). 수정 0건이면 1라운드 완료
- **ALL PASS → 완료**
- **FAIL 있음 → Step 1로 돌아가서 수정 → 재실행**

### 3. 루프 규칙
```
┌─ Step 0: 디자인
│  Step 1~4: 구현
│  Step 5: 품질루프 ← 체크포인트 (증거 파일)
│  Step 6: 스크린샷
│  Step 7: 교차검수 ← 체크포인트 (증거 파일)
│  Step 8: 빌드
│  Step 9~10: 배포 + 스모크
│  Step 11: 최종 검증
│     ├─ ALL PASS → 완료 보고 + <promise>PIPELINE_COMPLETE</promise>
│     └─ FAIL → Step 1로 복귀 (FAIL 항목만 수정)
└──────────────────────┘
```

- **최대 루프 횟수**: 일반 20회, 경량(`--light`) 5회. 초과 시 대표님께 보고
- **루프 카운터**: `~/.harness-state/pipeline_loop_count` 에 기록
- **루프 시 Step 5/7 증거 파일 초기화**: 매 루프마다 새로 생성해야 함
- **saturation 판정**: 1라운드 수정 0건이면 즉시 완료. 수정 있으면 2라운드 후 재판정

### 4. 경량 모드
인자로 `--light`를 전달하면 경량 파이프라인:
- Step 1 → Step 5 (1라운드) → Step 8 → Step 9~10 → Step 11
- 파일 3개 이하 소규모 수정에 적합

### 5. 완료 보고
루프 완료 시:
- 총 루프 횟수, 각 루프에서 수정된 항목 요약
- 최종 감사 점수: `bash ~/.harness-state/../.claude/scripts/audit-session.sh --compact` 실행
- `echo "파이프라인 완료 — 루프 N회, 최종 감사 점수" > ~/.harness-state/last_result.txt`
- 텔레그램 알림 자동 전송 (Stop hook)
