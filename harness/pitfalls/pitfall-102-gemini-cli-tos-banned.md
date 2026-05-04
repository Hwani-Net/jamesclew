---
slug: pitfall-102-gemini-cli-tos-banned
title: gemini CLI 다계정 로테이션 시 ToS 위반 차단
tags: [gemini, oauth, multi-account, tos-violation]
date: 2026-05-03
---

# 증상
```
Error: This service has been disabled in this account for violation of Terms of Service.
Please submit an appeal to continue using this product.
```
gemini CLI 호출 시 즉시 차단. Pro 구독 결제 상태와 무관.

# 원인
다계정 로테이션 흔적이 Google에 의해 감지됨:
- `~/.gemini/accounts/hwanizero01.json` (추가 계정 등록)
- `~/.gemini/accounts/rotation.json` (로테이션 메타데이터)
- `~/.gemini/gemini-rotate.sh` (로테이션 스크립트)

CLAUDE.md `codex-refresh` 패턴을 gemini에도 적용했으나, Google은 Anthropic보다 단일 OAuth 정책이 엄격.

# 해결
- gemini CLI 단일 OAuth 사용 (rotation 비활성화)
- 다계정 필요 시 Chrome 별도 프로필 + Antigravity GUI 사용 (CLI는 단일 계정만)
- 차단 해제: Google 어필 제출 (https://support.google.com/) — 회신 1~2주

# 재발 방지
외부 모델 로테이션 정책 적용 전 각 벤더 ToS 확인:
- Codex/OpenAI: 다계정 OAuth 허용 (검증됨)
- Claude/Anthropic: 2026-04 이후 OAuth third-party 차단 (Pro/Max 구독)
- **Gemini/Google: 다계정 로테이션 → 즉시 ToS 차단**
