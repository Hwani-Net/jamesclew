---
slug: pitfall-183-latentsync-anime-mouth-rainbow-noise
title: "LatentSync 1.5 — 애니 캐릭터 입 영역 무지개 노이즈/회색 흐림 합성 실패"
symptom: "애니 캐릭터 입력 시 입 영역이 무지개 노이즈 또는 회색 덩어리로 완전 손상됨. 외형(머리·옷·배경)은 보존되지만 마우스 영역 합성 자체 실패"
tags: [lipsync, latentsync, anime, vasa-1, false-claim, sd-vae]
date: 2026-05-19
severity: high
---

## 증상
LatentSync 1.5 (ByteDance, 5,685 stars) 시범 결과:
- 입력: 누나 (지브리 풍 애니 일러스트, nuna-loop-v2.mp4 11.32s 1024x1024)
- 출력: nuna-001-latentsync.mp4 (0.9MB, 11.3초)
- **5프레임 모두 입 영역이 무지개 노이즈 또는 흐릿한 회색 덩어리**
- 외형 보존: ✅ 머리·옷·배경·이마·눈
- 좌우 대칭: ✅ (한쪽 마비 X, 다만 입 자체가 깨짐)
- 배경·옷·머리 점프: ✅ 0 (정적 유지)
- 입+머리 자연스러움: ❌ FAIL — 입 영역 무지개 노이즈

## 원인
1. **README "anime videos from VASA-1" 주장 vs 실제 SD VAE 한계**:
   - LatentSync README는 애니 데모 명시
   - 실제로는 Stable Diffusion VAE가 애니 입을 못 재구성
   - 데모는 cherry-picked (VASA-1 원본 데모를 가져와 시각화한 것)

2. **256px stage2.yaml 다운/업샘플 디테일 손실**:
   - 1024x1024 입력 → 256px 다운샘플 → diffusion → 1024px 업샘플
   - 256px 단계에서 애니 입 윤곽선이 SD VAE에 의해 재구성됨 (실사 분포)
   - 애니 입 모양은 학습 분포 밖이라 무지개 노이즈로 재구성됨

3. **stage2_512.yaml (1.6 체크포인트) VRAM 한계**:
   - 512px 모델은 18GB VRAM 필요
   - 우리 RTX 3080 Ti 12GB에서 OOM 불가피
   - 12GB 환경에서는 256px만 가능 → 애니 입 합성 실패

4. **처리 시간 비효율**:
   - 1 voice (11.2초) = 807초 (13.5분)
   - 64 voice = 14.4시간 (inference_steps 20으로 낮춰도 9~10시간)
   - 결과 품질도 fail이라 시간 투자 의미 X

## 해결
1. **LatentSync 1.5 즉시 폐기** — 우리 누나 (애니 12GB 환경) 사용 불가
2. **PITFALL-182 (AniTalker)와 동일 교훈** — README "anime support" 주장은 cherry-pick 가능성 인지
3. **MuseTalk 우선** — 입 영역 inpainting 방식 (256x256만 변경, 나머지 픽셀 그대로)
4. **AniPortrait 시도 가능성** — 16GB VRAM 추정, 12GB 한계 검증 필요

## 재발 방지
- 신규 도구 채택 전 우리 실제 입력으로 1개 시범 → Opus Vision 검수
- README "anime support" 명시는 **참고용** — 실제 시범으로 최종 판정
- SD VAE 기반 도구는 애니 입 형상 학습 분포 밖 위험
- VRAM 요구량 확인 — 12GB 한계 도구는 256px 다운샘플로 디테일 손실

## 관련
- [[pitfall-179-sadtalker-anime-asymmetry]] (SadTalker 비대칭)
- [[pitfall-180-liveportrait-audio-unsupported]] (Live Portrait audio 미지원)
- [[pitfall-182-anitalker-anime-claim-vs-ffhq-reality]] (AniTalker FFHQ 변환)
- LatentSync 시범 mp4: `D:/AI 비즈니스/youtubeshorts/research/latentsync-test/nuna-001-latentsync.mp4`
- 현재 시도 중: MuseTalk 3차 (CLI bbox_shift 0/15/-15)
- 다음 후보: AniPortrait (16GB VRAM 추정)
