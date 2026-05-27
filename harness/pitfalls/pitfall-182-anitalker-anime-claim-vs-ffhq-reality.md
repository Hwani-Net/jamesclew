---
slug: pitfall-182-anitalker-anime-claim-vs-ffhq-reality
title: "AniTalker — README는 애니 특화 주장, 실제는 FFHQ 실사 학습으로 누나 캐릭터를 서양 실사로 변환"
symptom: "애니 캐릭터 입력 시 출력이 서양 여성 실사로 재구성됨. 원본 캐릭터 외형 보존율 0%"
tags: [lipsync, anitalker, anime, ffhq, false-claim]
date: 2026-05-19
severity: high
---

## 증상
AniTalker (X-LANCE 2024-05, 1,604 stars) 시범 결과:
- 입력: 누나 (지브리 풍 애니 일러스트, nuna-01-ref.png)
- 출력: 256x256 mp4, 11.2초, 25fps
- **얼굴이 서양 여성 실사로 완전 재구성됨** — 원본 캐릭터 외형 보존 0%
- 입 움직임은 정상, 머리 미세 움직임도 동작

## 원인
1. **README "애니 특화" 주장 vs 실제 FFHQ 학습**:
   - AniTalker README는 "Identity-Decoupled Facial Motion Encoding" 강조
   - HuggingFace Space에 애니 데모 예제 다수 있음
   - 그러나 핵심 motion encoder + renderer는 **FFHQ 실사 데이터셋 학습**
   - 결과: 애니 입력 시 실사 도메인으로 강제 변환

2. **identity-decoupled 구조의 함정**:
   - 머리/옷과 얼굴 움직임을 분리한다는 설계
   - 그러나 얼굴 외형 자체가 실사 분포에서 샘플링됨
   - 즉, "캐릭터 외형 보존"은 약속이지만 실제 동작 X

3. **researcher 보고서의 한계**:
   - GitHub stars/README/공식 데모만 보고 "애니 호환 ✅" 판정
   - 실제 inference 결과를 확인하지 않음
   - HuggingFace Space의 애니 데모는 cherry-picked 가능성

## 해결
1. **AniTalker 즉시 폐기** — 우리 누나 캐릭터에 사용 불가
2. **시범 우선 검증 원칙**:
   - README "anime support" 명시만으로 채택 금지
   - 반드시 우리 실제 캐릭터로 1개 시범 → Opus Vision 검수 → 채택 결정
3. **MuseTalk 우선** — 입 영역만 inpainting (배경/머리/외형 절대 불변)
4. **LatentSync 1.5 보조** — 애니 데모 명시 (검증 필요)

## 재발 방지
- 모든 신규 립싱크/이미지 변환 도구 채택 전:
  - [ ] 우리 실제 입력 (누나 nuna-01-ref.png)으로 시범 1개 실행
  - [ ] Opus Vision으로 원본 vs 결과 비교 (외형 보존 ≥ 90%)
  - [ ] 도메인 (애니/실사) 명시 확인 — 학습 데이터셋 README 검증
- researcher 보고서의 "애니 호환" 평가는 **참고용**, 실제 시범으로 최종 판정
- HuggingFace Space 데모는 cherry-picked 가능성 인지

## 관련
- [[pitfall-179-sadtalker-anime-asymmetry]] (SadTalker 비대칭 → 도구 교체 시도)
- [[pitfall-180-liveportrait-audio-unsupported]] (Live Portrait audio 미지원)
- AniTalker 시범 mp4: `D:/AI 비즈니스/youtubeshorts/research/anitalker-test/nuna-01-ref-nuna-001-scene1.mp4`
- 다음 시도: MuseTalk 1.5 (진행 중), LatentSync 1.5 (시작 예정)
