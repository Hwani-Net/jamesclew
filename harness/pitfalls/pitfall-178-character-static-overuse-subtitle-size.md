---
title: "롱폼 영상 — 캐릭터 정적·재사용·자막 사이즈 트로이카 함정"
slug: pitfall-178-character-static-overuse-subtitle-size
date: 2026-05-19
category: video-production
tags: [video, longform, character, subtitle, lipsync]
severity: high
---

# pitfall-132 — 캐릭터 정적·재사용·자막 작음 트로이카

## 증상
v8 빌드(Coffeezilla 비율 부합)에서도 3가지 새 문제 발견:
1. **자막 사이즈 18pt 본문 + 28pt 강조 → 너무 작음** (한국어 시청 기준 부적정)
2. **캐릭터 정지 사진만 — 입조차 안 움직임** (talking-head 효과 X, 시청자에게 정적 인상)
3. **8표정만으로 56% 화면 채움 → 같은 이미지 반복 노출** (재사용 인식 강함)

## 원인
1. **자막 사이즈** — 영문 자막 기준(작은 폰트 + outline 강조)을 한국어에 잘못 적용. 한국어는 한 글자가 정보량 큼 → 더 큰 폰트 필요
2. **정적 캐릭터** — gpt-image-2 단일 이미지만 사용 + 립싱크 도구 미도입. ffmpeg zoompan 미세 줌으로 정적 인상 해소 시도했으나 부족
3. **재사용** — 8 표정 × 약 5분(56% × 9.2분) = 평균 표정당 38초 노출. 사용자가 같은 인물 같은 자세 반복 인지

## 해결

### 자막 사이즈
- **본문 32pt + 강조 44pt amber** (`build_subtitles_v8.py` Style 정의)
- 한국어 시청 최소 기준 24pt 본문 + 36pt 강조 (Coffeezilla 영문 24pt 대비 가독성 보존)

### 캐릭터 입 움직임 (립싱크)
- **SadTalker** 도입 — 정적 이미지 + 오디오 → 머리·눈·입 자동 움직임 영상 (RTX 3080 Ti, voice 1개당 1-3분)
- Wav2Lip은 입만 (속도 빠르나 효과 약함)
- 64 voice 전체 자동화 → 약 1-2시간 추가 빌드 시간

### 캐릭터 다양화
- **8표정 → 14표정으로 확장** (gpt-image-2 reference cascading 추가 6장)
- 추가: pointing-data, nodding, tilting-head, sighing, emphasizing, listening
- voice 톤 → 표정 매핑 더 세밀화

## 재발 방지
**영상 빌드 전 체크리스트** (`build_video_*.py` 실행 전):
- [ ] 자막 본문 폰트 ≥ 24pt (한국어 시청 최소)
- [ ] 강조 키워드 폰트 ≥ 본문의 1.4배 이상
- [ ] 캐릭터 정적 이미지 사용 시 → 최소 립싱크 또는 줌·각도 변화 다양화
- [ ] 캐릭터 노출 시간 ≥ 영상 30% 시 → 표정·자세 12종 이상 보유
- [ ] 캐릭터 표정당 최대 노출 시간 ≤ 1분 (반복 인식 회피)

**자동 검증 가능 항목** (`verify_v10_output.py` 검토):
- 자막 ASS 파일 폰트 사이즈 grep → ≥ 24pt 확인
- 클립 종류별 시간 측정 → 단일 캐릭터 이미지 ≤ 60초/표정
- 립싱크 mp4 유무 (SadTalker 출력) 확인

## 관련
- [[pitfall-130-video-format-text-slideshow]] (텍스트 슬라이드쇼 형식)
- [[pitfall-131-asset-relevance-legal-risk]] (자료 무관성 법적 위험)
- v8 빌드: `build_video_v8.py`, `build_subtitles_v8.py`
- v9 임시 패치: 자막만 32/44pt (`out/longform-002-v9-bigger-subs.mp4`)
- v10 계획: SadTalker 립싱크 + 14표정 + 화자 선택 + 자막 32/44pt 통합
