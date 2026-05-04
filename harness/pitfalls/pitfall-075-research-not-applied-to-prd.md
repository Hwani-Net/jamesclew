---
type: pitfall
title: "리서치 산출물을 PRD 설계에 미적용"
id: P-075
tags: [jamesclew, pitfall, prd, research, synthesized]
---

# P-075: 리서치 산출물을 PRD 설계에 미적용

- **발견**: 2026-04-28
- **프로젝트**: 영상제작 (G시나리오 30초 모션 그래픽)

## 증상
영상제작 프로젝트에서 `05_실사아이돌_트렌드+프롬프트.md`, `01_레퍼런스영상_분석.md` 등 synthesized/distilled tier 자료에 정리한 핵심 노하우(일관성 락 5단 구조, 9-panel canvas trick, HEX 코드 락, 2 frames/sec 스토리보드 시트)를 PRD v1에 전혀 반영 안 하고 "이미지 6장 무작위 생성" 수준의 단순 파이프라인 작성. 대표님이 "리서치 결과와 너무 다르다" 지적.

## 원인
리서치 산출물을 gbrain에 등록만 하고 실제 PRD 설계 시 다시 읽지 않음. distilled/synthesized tier 자료를 implementation에 강제 적용하는 체크리스트 부재. PRD 작성 직전 `gbrain query` 호출 습관 없음.

## 해결
PRD 작성 직전 `gbrain query "프로젝트 도메인 키워드"`로 synthesized/distilled 자료 호출 → 핵심 노하우를 PRD 모듈 명세에 그대로 인용 → 인용한 출처 슬러그 명시하여 재설계.

## 재발 방지
1. PRD 템플릿에 "참조한 synthesized/distilled 자료 슬러그" 섹션 필수
2. 자료에서 추출한 룰을 모듈별 acceptance criteria로 변환
3. PRD 작성 전 `gbrain query "<도메인 키워드>"` 실행 → 결과를 참조 자료 섹션에 붙여넣기
4. `/prd` 스킬 실행 시 CLAUDE.md "0단계 사전 조회" 에 synthesized 자료 읽기 추가
