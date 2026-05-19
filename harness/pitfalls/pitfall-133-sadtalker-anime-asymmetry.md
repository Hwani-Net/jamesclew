---
title: "SadTalker — 애니/일러스트 캐릭터 입 비대칭 한계"
slug: pitfall-133-sadtalker-anime-asymmetry
date: 2026-05-19
category: video-production
tags: [video, lipsync, sadtalker, anime, character]
severity: high
---

# pitfall-133 — SadTalker 애니 캐릭터 입 비대칭

## 증상
SadTalker 시범 (nuna-001-scene1.mp4) Opus Vision 직접 분석 결과:
- 0.2s: 입 닫힘, 대칭 OK
- 2s: 입 열림 시 좌측으로 미세 치우침
- 4s: 입 크게 열림 + 명확한 좌우 비대칭 (좌측 입꼬리 ↑, 우측 ↓)
- 6s: 입꼬리 비대칭 지속
- 8.5s: 다시 비대칭

대표님이 시청 후 즉시 지적: "입모양이 비뚤게 립싱크해" (정답).

## 원인
SadTalker는 다음 데이터셋 학습:
- CelebA, VoxCeleb, HDTF (실사 인물 영상)
- 3D Morphable Model (3DMM) 기반 얼굴 형상 추정 — 실사 인물 비율 가정
- GFPGAN enhancer도 실사 얼굴 기준 보정

애니/일러스트 캐릭터 (지브리 풍 누나) 는:
- 입 위치·비율이 실사와 다름 (눈 대비 입 비율 ↓, 입 위치 살짝 ↑)
- 입 색상·윤곽 단순화로 lankmark 검출 부정확
- 결과: 입 좌표 잘못 추정 → 좌우 비대칭 립싱크

## 해결 (옵션)
1. **gpt-image-2로 입 5종 생성 + 음파 진폭 교체** (채택)
   - 같은 캐릭터 + 입 모양만 5종 (닫힘·살짝·열림·크게·미소)
   - 음성 파형 진폭 분석 → 30fps 프레임마다 적합한 입 선택 → 합성
   - 캐릭터 일관성 100%, 비대칭 없음
2. MuseTalk — 입만 정밀 교체 (애니 호환성 검증 필요)
3. Hallo2 — 디퓨전 기반, 애니 지원 (처리 시간 2시간)
4. 단순 입 3프레임 루프 — 립싱크 X

## 재발 방지
- 애니/일러스트 캐릭터에는 SadTalker · Wav2Lip 등 실사 학습 모델 ❌
- Vision 검수는 Opus 직접 (Sonnet Vision은 좌우 대칭 같은 세밀 비교 누락 가능)
- 새 립싱크 도구 도입 시 시범 1개 → Opus Vision 검수 → 64 voice 배치 순서 엄수

## 관련
- [[pitfall-130-video-format-text-slideshow]]
- [[pitfall-132-character-static-overuse-subtitle-size]]
- [[pitfall-134-liveportrait-audio-unsupported]]
- [[pitfall-135-sonnet-vision-symmetry-blindness]]
- `automation/SadTalker/` (격리됨, 사용 안 함)
- 시범: `videos/longform-002/assets/lipsync/nuna-001-scene1.mp4`
