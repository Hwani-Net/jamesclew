---
type: pitfall
id: P-037
title: "FLUX.1 시리즈는 HuggingFace gated repo — 토큰 없이 다운로드 불가"
tags: [pitfall, jamesclew]
---

# P-037: FLUX.1 시리즈는 HuggingFace gated repo — 토큰 없이 다운로드 불가

- **발견**: 2026-04-17
- **증상**: black-forest-labs/FLUX.1-schnell 다운로드 시 GatedRepoError 401
- **원인**: Black Forest Labs가 2025년경 FLUX.1-schnell/dev 모두 HF gated repo로 전환. Apache 2.0 라이선스지만 다운로드는 HF 로그인 + 모델 카드 동의 필수
- **해결**: HF 로그인 + 토큰. 게이트 없는 대체: SDXL(완전 공개), Kolors, PixArt-Sigma, AuraFlow
- **재발 방지**: HF 모델 사용 전 페이지에서 "You need to agree" 문구 확인. 코드 라이선스 != 가중치 다운로드 자유
