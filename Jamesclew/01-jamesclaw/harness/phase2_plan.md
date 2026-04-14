---
name: Phase 2 Revenue Pipeline Plan
description: 수익 파이프라인 우선순위와 도구 매핑
type: project
---

## 우선순위 (검증된 ROI순)
1. **WordPress + AdSense** — 공식 REST API, 완전 자동화, RPM 2,000-8,000원, 첫 수익 2-4주
2. **YouTube Shorts** — FFmpeg+TTS, Data API v3 (일 ~6건), $0.04-0.06/영상, 첫 수익 4-8주
3. **공모전/예창패 추적** — K-Startup API (data.go.kr) + Google Calendar, 돈보다 기회 포착
4. **SaaS 마이크로** — Firebase+Stripe, Next.js+Vercel, 반복 수익, 8-12주

## 비용 vs 수익 예측
- 월 비용: $110-220 (Claude Max + API + 호스팅)
- 월 6개월 후 예상: $1,050
- 월 12개월 후 예상: $2,800

## 도구 매핑 (검증 완료)
- YouTube: FFmpeg + ElevenLabs/Google TTS + Remotion + YouTube Data API v3
- Blog: WordPress REST API + claude-seo (3,791 stars) + Lighthouse CLI
- 공모전: K-Startup API + Playwright (민간 크롤링) + Google Calendar API + python-docx
- SaaS: Firebase (MCP+CLI) + Stripe API + Vercel

## 스킵
- 네이버 블로그 자동화 (ROI -96%)
- 인스타그램 완전 자동화 (계정 정지 위험)
- 해커톤 완전 자동 제출 (심사위원 감지)

## 미구현 사항 (Phase 1.5)
- Usage 80%+ 자동 행동 (세션 저장→종료→새 세션)
- 관찰성/메트릭 (토큰 로깅, audit trail)
