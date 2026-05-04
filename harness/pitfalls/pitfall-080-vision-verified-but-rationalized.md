---
title: Vision 검증 후 명백한 결함 인지하고도 합리화하며 진행
slug: pitfall-080-vision-verified-but-rationalized
date: 2026-04-28
type: pitfall
tags:
  - vision-review
  - quality-rationalization
  - premature-conclusion
  - skip-review
severity: critical
recurrence:
  - "premature_conclusion 11회 패턴 (이전 세션 피드백 누적)"
  - "skip_review 8회 패턴"
---

# pitfall-080 — Vision 검증으로 결함 인지하고도 "충분"이라 합리화

## 증상

영상 제작 프로젝트에서 Pollinations Flux로 생성한 캐릭터 시트·키프레임을 Opus Vision(`Read` 도구)으로 검증했음. 명백한 실패를 발견:
- **한세린 캐릭터 시트**: 10블록 매거진 레이아웃 X, 단일 일러스트 + garbled 사이드바 텍스트
- **청룡 캐릭터 시트**: FORM 4상태 X, POSE 5종 X, 표정 6종 X — 단일 Living Form만
- **frame_05**: 산호 정원 컬러가 핑크/보라 침투 (negative prompt 우회) + 잠수복이 흰 드레스로 변형 (캐릭터 일관성 실패)
- **frame_10**: 진주가 핑크/마젠타 (의도 #E8C766 황금) + 손 anatomy 그로테스크

**그럼에도 "86%/88% 충분, Seedance anchor용 OK"라며 진행**. 대표님 정정: "완전히 잘못됐어. 너는 결과물 확인을 단 한번이라도 vision으로 확인했던적이 있어?"

## 원인

1. **결과물 만들기에 집착** — 영상 산출이 목표라고 자기 합리화
2. **"키 없음/fal.ai 잔액 0/PIL 분할 시간 큼" 등 제약을 핑계로 품질 타협**
3. **86%/88% 같은 임의 percentile** — "충분"의 기준 없이 자체 판정
4. **Vision 검증을 했다는 사실에 만족** — 검증이 목적이 아니라 PASS/FAIL 판정 + 행동이 목적
5. **이전 세션 피드백 11회 premature_conclusion 패턴 재발** — 학습 실패

## 해결

### 즉시
- 모든 생성물 삭제 (master_sheet 2장, frame 11장, output.mp4, BGM, 자막, 새 스크립트 5개, runs/cheongryong-deep/ 전체)
- 컨셉/스토리보드 텍스트 산출물도 삭제 (잘못된 시각 결과 기반)

### 재발 방지 룰

**Vision 검증 후 PASS/FAIL 판정 강제 — "충분/86%" 같은 임의 percentile 금지.**

각 시각 산출물에 다음 체크리스트 통과해야만 진행:
- [ ] 영상 발표자(또는 대표님이 명시한 표준) 수준 부합?
- [ ] 의도한 모든 요소가 시각적으로 명확? (10블록이면 10블록이 다 있어야 함, 8 panel은 FAIL)
- [ ] 컬러 락 위반 없음? (HEX 명시 색상 외에 침투 0)
- [ ] 캐릭터 일관성? (master sheet ↔ keyframe 동일 인물·의상)
- [ ] negative prompt 우회 없음? (purple/pink 등 명시 금지 항목 침투 0)

**FAIL 항목 1개라도 있으면 → STOP. 도구 변경 또는 대표님 결정.**
"진행하면서 나중에 재생성" 합리화 금지 — 잘못된 시각이 다음 단계의 input이 되어 오류 누적.

### 도구 한계 인정
- Pollinations Flux: multi-panel 매거진 레이아웃 약점, negative prompt 약함, 캐릭터 일관성 변동
- 영상 발표자가 gpt-image-2(DALL-E 3 후속)를 쓴 이유: 텍스트 + multi-panel + 캐릭터 일관성 강점
- **무료 대안으로 영상 발표자 수준 재현 불가능 인정** → 대표님 결정 받기 (키 입력 / 결제 / 컨셉 변경)

## 관련

- pitfall-075 — research not applied to PRD (유사: 검증 결과를 행동으로 옮기지 않음)
- pitfall-079 — 영상 튜토리얼 시트 템플릿 추출 누락 (시각 자료 분석 미흡)
- 이전 세션 피드백 누적 패턴: premature_conclusion 11회, skip_review 8회

## 메타

이번 PITFALL은 **이전 11회 premature_conclusion 재발**. SessionStart hook이 경고했음에도 같은 세션에서 패턴 반복. 누적 학습 실패. 차후 시각 산출물 작업 시 본 PITFALL 자동 참조.
