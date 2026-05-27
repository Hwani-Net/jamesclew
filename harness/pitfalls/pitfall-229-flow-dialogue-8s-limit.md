# PITFALL-229 — Flow Veo 8초 dialogue 한계 + 외래어 발음 + Scene Extension 미사용

**날짜:** 2026-05-26
**증상키워드:** flow, veo, dialogue, 8초, 한국어, lip-sync, 챗지피티, scene extension

## 증상
- Flow에 한국어 dialogue 64자 ("감사원이 하남도시공사를 들여다봤습니다. 그리고 발견한 건, 7박 9일 동유럽 출장 보고서에 챗지피티가 등장한다는 사실이었습니다.")를 입력했더니:
  1. 8초 안에 못 넣어서 **임의 함축** ("동유럽 출장 보고서에" 부분 잘림)
  2. **외래어 "챗지피티" → "챗지피"** 잘못 발음
  3. 일부 단어가 누락되어 voice line과 불일치

## 원인
- Veo 3.1 fixed 8s window에 한국어 음운 너무 많이 넣으면 모델이 자동 축약
- 외래어 (영어 + 한국어 혼용) TTS는 정확도 떨어짐 (특히 짧은 외래어)
- + 버튼의 **Scene Extension 기능 미사용** (8초 → 8초 → 8초 chain으로 확장 가능)
- 누나 character reference sheet의 **다양한 각도/표정 이미지 미활용**

## 해결
1. **voice line당 1개 영상 X** — voice 자체를 **2-3 클립으로 분할** (각 4-5초 dialogue), Scene Extension(+ 버튼)으로 chain
2. **외래어는 영문 dialogue로 분리**: "ChatGPT" → 별도 컷 또는 한글 발음 강조 ("쳇 지 피 티")
3. **누나 character sheet 다양 각도 활용** — 정면/측면/하이앵글 ref 추가
4. **lip-sync 정확도 강박 버리기** — Flow 영상 = 입 움직임 only, 별도 TTS voice layer mix가 더 유연

## 재발 방지
- Flow 영상 생성 전 한국어 dialogue 음절 카운트 (8초 ≈ 20-25 음절 권장)
- 외래어 포함 시 별도 클립 또는 우회 표기
- Scene Extension (+ 버튼 / 확장 메뉴) 기본 옵션으로 인지

## 관련
- [[pitfall-218]] — sub-agent WSL2 경로 강제
- Google Cloud Veo 3.1 prompting guide
- Veo 3.1 features: Scene Extension up to ~2.5min, Ingredients to Video (multi-ref)
