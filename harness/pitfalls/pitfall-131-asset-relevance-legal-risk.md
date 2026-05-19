---
title: "자료 자동 수집 — 사건 정체성 검증 누락으로 법적 위험"
slug: pitfall-131-asset-relevance-legal-risk
date: 2026-05-19
category: legal-safety
tags: [video, legal, defamation, automation, asset-verification]
severity: critical
---

# pitfall-131 — 자료 자동 수집 시 사건 정체성 검증 누락

## 증상
폭로·고발 채널의 영상 자료 자동 수집 시 검색 키워드 매칭만 사용 →
본 사건과 무관한 기관·인물·사건이 화면에 등장.

구체 사례:
- `voice_034` ("이행강제금 1억 3,560만 원") → **부동산 채널 영상이 끌어당겨짐** (Agent A 보고)
- "공기업" 키워드 → 다른 공기업 부정 사건 자료 혼입 가능
- "감사원" 검색 → 무관한 감사원 발표 자료 혼입

## 법적 위험
1. **명예훼손** (형법 §307) — 무관한 인물이 본 사건 연관자처럼 오인
2. **허위사실 적시 명예훼손** (§307②) — 무관 기관이 부정 관여한 것처럼 오인
3. **모욕** (§311) — 사건 무관자에 대한 부정적 영상 맥락 배치
4. **저작권 침해** — 인용 fair use 조건 위반 (출처·맥락 명확성 결여)
5. **민사 손해배상** — 잘못 노출된 당사자의 명예·신용 침해

## 원인
1. **검색 매칭 = 사건 일치라고 가정** — `asset_capture.py` 의 Tavily 점수만으로 자료 채택. 사건 정체성 (entity/amounts/dates) 일치 검증 없음
2. **video_clip_capture.py 의 score 산정** — 채널 신뢰도 50점 + 키워드 매칭 30점 + 신선도 20점. 사건 정체성 가중치 0
3. **사람 검수 게이트 부재** — 자동 빌드가 사람 승인 없이 진행됨
4. CLAUDE.md "모든 멘트 1차 자료 인용, 개인 거명 X, 출처 자막 100%" 원칙이 자동화 설계에 반영 안 됨

## 해결
**3단계 검수 시스템 도입**:

### 1. core_identity 메타 필수
각 영상 `script.json` 에 다음 필드 추가:
```json
"core_identity": {
  "primary_entity": ["하남도시공사"],
  "secondary_entity": ["감사원", "오스트리아", "체코"],
  "key_amounts": ["2,505만", "1억 3,560만"],
  "key_dates": ["2026-02-13"],
  "events": ["인권경영 외유성 출장"],
  "excluded": ["다른 공기업 일반", "부동산", "주택 정책"]
}
```

### 2. 자동 검증 함수
`verify_asset_relevance(asset, core_identity) -> dict`:
- primary_entity 매칭 ≥ 1 필수 (URL + 제목 + 페이지 첫 단락)
- secondary/amounts/dates 중 ≥ 1 추가 매칭 가산점
- excluded 매칭 1개라도 → 즉시 거부
- Opus Vision 옵션 — 이미지 화면 안 텍스트도 검사 (정확도 ↑)
- 통과 점수 ≥ 70

### 3. 사람 승인 게이트
- 검증 통과 자료를 `assets/auto-docs-verified/` 로 이동 + `manifest.json` 생성
- 대표님 검수 (실제 화면 확인) → manifest 에 `approved_by: user, approved_at: <date>` 서명
- `build_video_*.py` 는 manifest 의 `approved` 필드 확인 → 없으면 exit 1 차단

## 재발 방지
**영상 빌드 전 게이트**:
- [ ] script.json 의 `core_identity` 필드 존재 + 비어있지 않음
- [ ] `assets/auto-docs-verified/manifest.json` 존재 + `approved_by` 필드
- [ ] 자료 매니페스트의 자료 수 ≥ voice 매칭 수
- [ ] 모든 영상 클립은 사람 1차 검수 필수 (자동 매칭만으로 사용 금지)

**자동화 정책 변경**:
- 영상 클립 자동 매칭은 ❌ 발행 금지. 인프라는 보존하되 무인 사용 금지
- 자료 자동 수집은 검증·승인 게이트 통과 후에만 빌드 진입
- 영상 발행 전 "사건 무관 자료 ≥ 1개 발견 시 폐기" 체크리스트 통과

## 즉시 조치 (2026-05-19)
1. v7 발행 보류 (대표님 검수용으로만 보존)
2. v5 형식으로 #002 롤백 — 자막 18pt 미세 조정
3. 검수 게이트 시스템 구현
4. v8 안전 빌드 — 검증된 자료만 사용

## 관련
- [[pitfall-130-video-format-text-slideshow]] — 텍스트 슬라이드쇼 형식 문제 (이 문제 해결하려다 #131 발생)
- CLAUDE.md "법적 안전: 모든 멘트 1차 자료 인용, 개인 거명 X, 출처 자막 100%"
- `automation/lib/asset_capture.py` (586+154줄)
- `automation/lib/video_clip_capture.py` (802줄)
