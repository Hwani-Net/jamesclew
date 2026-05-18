---
slug: pitfall-164-coupang-partners-link-silent-fail
date: 2026-05-18
severity: critical
tags: [blog-pipeline, monetization, coupang-partners, fail-silent, gate-missing]
related: [[pitfall-001-image-lazy-loading]] [[pitfall-157-publisher-collection-mismatch-with-live-site]]
---

# P-164 — 쿠팡 파트너스 링크 silent fail로 9개 페이지 수익 0

## 증상
- 2026-05-07 발행 9개 MultiBlog 가전 리뷰 페이지 100% 수익화 실패
- 패턴 1 (4페이지): 이미지·쿠팡 링크 전무, 제조사/다나와 공식 사이트 링크만
- 패턴 2 (1페이지): `link.coupang.com/a/placeholder-{브랜드}-{모델}` 더미 5개 (403 응답)
- 패턴 3 (4페이지): `www.coupang.com` 일반 URL만, `/a/{ID}` 파트너스 형식 없음
- 라이브 검증으로 발견 (2026-05-18): 9개 모두 HTTP 200이지만 수익 라인 무효

## 원인
- `/blog-generate` 파이프라인에 **파트너스 링크 생성 단계(Phase 4.5)가 설계되지 않음**
- LLM이 초안 작성 시 링크 URL을 자체 생성 — placeholder 또는 일반 검색 URL로 채움
- `blog-generate.md` 라인 182의 "이미지 실패 → placeholder 삽입" fail-silent 정책이 링크에도 묵시 적용
- `/blog-review`는 SEO 체크리스트에 파트너스 링크 검증 항목 부재
- `blog-publish.sh`는 draft.md 파일 존재만 확인, 내용 무검증
- 3-레이어(generate/review/publish) 모두 게이트 없어 결함이 누수 없이 발행까지 전파

## 해결
2026-05-18 3-레이어 게이트 추가 (커밋 a16dc2a):
- `blog-generate.md` Phase 4.5 신설 — 파트너스 API → meta.json 수동 → FAIL-LOUD. placeholder 명시적 금지
- `blog-review.md` PARTNERS GATE — placeholder 또는 실제 링크 0개 시 SEO 점수 무관 FAIL override
- `blog-publish.sh` Gate A (placeholder 감지) + Gate B (제품 리뷰에서 파트너스 링크 0개)

## 재발 방지
- 발행 가능한 모든 글에 `link.coupang.com/a/{ID}` 형식 최소 1개 필수 (제품 리뷰 슬러그)
- placeholder 단어를 URL에 절대 사용 금지 — fail-loud로 처리
- 수익화 페이지는 발행 전 게이트 3-레이어 통과 필수
- 2026-05-07 발행 9개는 별도 재발행 작업으로 처리 (예정)
- 향후 `/blog-review` 7-pass 중 최소 1패스는 파트너스 링크 정합성 전용 검증
