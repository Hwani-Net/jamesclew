---
slug: pitfall-084-manual-over-application
tags: [pitfall, manual-application, multi-reference, context-branching, video-storyboard]
date: 2026-04-30
project: 영상제작 (Phase 2 v2)
---

# P-084: 매뉴얼 갭 무차별 적용 금지 — 작가 컷별 컨텍스트 우선

- **발견**: 2026-04-30
- **프로젝트**: 영상제작 Phase 2 v2 스토리보드 9컷 자동 생성
- **심각도**: HIGH (작가 의도 손상)

## 증상
- 매뉴얼 갭 분석 풀 적용(multi-reference + Joseon dynasty + seed + @태그)으로 v2 9컷 생성
- CUT01 / CUT08: 작가 의도 = "석상 형태 해치만 등장" / 우리 v2 = "살아있는 해치(turquoise scales, golden mane)가 5,6번 컷에 섞여 등장"
- CUT05.5: "wooden boat with lotus-shaped hull" 명시했으나 "연꽃 자체에 앉은 듯한 느낌" → 보트 형태 손실
- 대표님 정확 지적: "작가 의도일 때 프롬프트엔 어색함이 묻어있다면, 우리 프롬프트엔 '이게 뭐지?'라는 느낌"
- 작가 의도 충족도: 78% (작가 도구 v1 92%, ChatGPT UI 92% 대비 14% 손상)

## 원인
1. haechi-MASTER.png는 살아있는 해치 1장 → CUT01, CUT08 석상 형태 누락. multi-reference가 살아있는 형태를 모든 컷에 강제 적용
2. 매뉴얼 갭 분석 시 컷별 캐릭터 형태 변화(석상↔살아있는) 인식 못함
3. 작가 PDF Part 3 원본 프롬프트의 자연스러운 흐름이 매뉴얼 표준화로 손상됨
4. 1차 결과 검증 없이 9컷 일괄 생성 (1컷 테스트 후 9컷 결정 절차 누락)

## 해결
- 작가 PDF의 컷별 컨텍스트(석상/살아있는, 위치, 모드) 변화 → 적용 전 컷별 분기 필수
- 매뉴얼 권장사항은 **선택적 적용** — 모든 컷 동일 적용 금지
- multi-reference 사용 시 **컷별 적합한 reference만 첨부**:
  - CUT01, CUT08 (해치 석상 컷): protagonist + 석상 reference (살아있는 해치 reference 제외)
  - CUT02~07 (살아있는 해치 컷): protagonist + 살아있는 해치 reference
- 매뉴얼 갭 적용 1차 결과를 **반드시 작가 의도와 매칭 검증** 후 차회 적용 결정

## 재발 방지 체크리스트
- [ ] 작가 PDF의 컷별 캐릭터 형태 변화 확인
- [ ] 컷별 reference 분리 가능성 확인
- [ ] 매뉴얼 권장 적용 vs 작가 원본 유지 비교 분석
- [ ] 1컷 테스트 → 9컷 진행 게이트 적용
- [ ] 작가가 "어색해 보여도" 그 자체가 의도일 수 있음 인지

## 메모리 연동
- `feedback_manual_over_application.md` (memory)
- `references/storyboard-comparison-v1-v2-chatgpt.md` (학습 자료)
