---
title: "롱폼 영상 자동화 — 텍스트 슬라이드쇼 형식의 함정"
slug: pitfall-130-video-format-text-slideshow
date: 2026-05-19
category: video-production
tags: [video, longform, youtube, benchmarking, ui]
severity: high
---

# pitfall-130 — 텍스트 카드 95% 슬라이드쇼 형식의 함정

## 증상
자동화 롱폼 영상이 벤치마킹 채널(Coffeezilla / 경제사냥꾼 / Wendover)과 형식이 완전히 다름.
실측 비율:
- 우리 영상: 텍스트 카드 95% / 1차 자료 5% / 자막 전체 문장 22pt burn-in
- 벤치마킹 평균: 텍스트 카드 3-10% / 1차 자료(뉴스 캡처·트윗·공문서·영상 클립) 45-60% / 자막 키워드만

결과: "텍스트 슬라이드쇼"·"팟캐스트 자막 버전"으로 인식. 폭로 채널의 신뢰성 기반인 "보여주기"가 실종.

## 원인
1. **자료 수집 자동화 부재** — voice별 매칭 자료 1-2장만 있어서 텍스트 카드로 메꿈
2. **자막을 voice 전체 burn-in** → 카드와 중복 (둘 다 텍스트)
3. **컷 평균 8-15초** (벤치마킹은 2-6초)
4. **모션 그래픽·차트·영상 클립 0%** (벤치마킹은 30-50%)
5. 빌드 파이프라인 설계 시 벤치마킹 채널 frame-by-frame 분석 없이 가정으로 진행

## 해결
**Coffeezilla 스타일 파이프라인 재설계 (3주)**:
1. Week 1: 자료 자동 캡처 모듈 (Playwright 기반 voice별 키워드 검색 → 뉴스·감사원·트윗 캡처) + 줌인·하이라이트 애니메이션 + 컷 평균 2-3초
2. Week 2: 모션 인포그래픽 (Manim 또는 Motion Canvas) + 캐릭터 일러스트 10종 (Codex gpt-image-2) + 자막 키워드 강조 시스템 (22pt 전체 → 14pt 본문 + 28pt 강조)
3. Week 3: SFX (강조음·셔터·임팩트) + 통합 빌드 + #001·#002 재빌드

목표 비율 (옵션 C — Coffeezilla 스타일):
- 1차 자료 캡처 + 줌인 애니메이션: 40%
- 뉴스 영상 클립 + 인터뷰 (공공기관 발표 영상): 20%
- 커스텀 모션 인포그래픽: 20%
- 캐릭터 일러스트 (감정 10종): 10%
- 텍스트 카드: 5%
- 지도: 5%

## 재발 방지
**영상 빌드 전 체크리스트** (`/build-video` 전 필수):
- [ ] 벤치마킹 채널 1편 frame-by-frame 비율 분석 완료 (또는 등록된 분석 참조)
- [ ] 자료 자동 캡처 모듈 voice별 매칭 자료 ≥ 1.5장/voice 확보
- [ ] 컷 평균 길이 < 6초 (목표 3초)
- [ ] 텍스트 카드 비중 ≤ 15%
- [ ] 자막 키워드 강조 형식 (전체 문장 burn-in 금지)

빌드 완료 후 검증:
- [ ] 풀스크린 화면에서 1차 자료가 차지하는 시간 측정 → ≥ 40%
- [ ] 모션/애니메이션 (Ken Burns 외) 존재 여부

## 관련
- [[pitfall-129-korean-native-numerals]]
- `rules/architecture.md` Vision 라우팅 정책 (영상 자료 매칭은 Opus Vision)
- 벤치마킹 분석 보고서 — researcher 에이전트 2026-05-19
- `automation/lib/voices_supertonic.py` — TTS 모듈
- `D:/AI 비즈니스/youtubeshorts/videos/longform-00X/build_video_v5.py` — 현행 빌드 (재설계 대상)
