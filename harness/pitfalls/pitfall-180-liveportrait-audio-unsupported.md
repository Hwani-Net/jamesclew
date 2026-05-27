---
title: "Live Portrait — audio-driven 모드 미지원 (driving video 전용)"
slug: pitfall-180-liveportrait-audio-unsupported
date: 2026-05-19
category: video-production
tags: [video, lipsync, liveportrait, audio]
severity: medium
---

# pitfall-134 — Live Portrait audio 미지원

## 증상
SadTalker 입 비대칭 문제 (pitfall-133) 회피용으로 Live Portrait (KuaiShou 2024-07) 도입 검토.
설치·시범까지 진행했으나 시범 실행 시 발견:
- `-d <driving>` 인자가 **driving video (.mp4 또는 .pkl) 전용**
- WAV 직접 입력 불가
- Audio-driven 립싱크는 설계 범위 외

## 원인
Live Portrait는 "implicit keypoints + stitching control" 기반의 portrait animation 도구.
- 입력: source image + driving (다른 영상의 표정·움직임)
- 동작: source 인물이 driving 인물의 표정·머리 움직임을 따라함
- 즉, **다른 사람 얼굴 영상 → 같은 표정으로 변환**이 본질
- 오디오 → 입 모양 매핑은 별도 모델 (audio2expression 같은) 필요

## 해결
1. **audio2expression + Live Portrait 2단계 파이프라인** — 구축 공수 2-3시간, 검증된 사례 부족
2. **gpt-image-2로 입 5종 + 음파 교체** (채택, 더 단순)
3. **MuseTalk** — 단일 도구로 audio→입 매핑 직접 지원

## 재발 방지
**새 립싱크 도구 도입 시 사전 확인 체크리스트**:
- [ ] 입력 형식: audio (WAV/MP3) 직접 가능?
- [ ] 또는 driving video 만? (그러면 audio→expression 별도 필요)
- [ ] 애니/일러스트 호환성 명시?
- [ ] 우리 환경 GPU (12GB VRAM) 충분?
- [ ] CLI 또는 Python API 명확?

릴리즈 노트·README 의 "Audio-driven" 또는 "audio support" 키워드 grep 필수.

## 관련
- [[pitfall-133-sadtalker-anime-asymmetry]]
- Live Portrait: `automation/LivePortrait/` (격리됨, 사용 안 함)
- 시범 결과: nuna-d0.mp4 (driving video 기반, audio 불일치)
