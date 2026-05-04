---
slug: pitfall-065-pexels-id-guessing
date: 2026-04-27
severity: P1
tags: [pexels, vision, image, pitfall]
---

# Pitfall-065: Pexels ID 추측 제공 → 비커플 사진 노출

## 증상
team-lead이 HTTP 200 확인만 한 Pexels ID 8개를 제공했으나, Vision 검증 없이 내용 추측 → 8개 모두 커플이 아닌 사진(산악 풍경, 1인 여성, 건물 등).

## 원인
- Pexels API key 없이 photo ID → URL만 검증 (HTTP 200, 파일 크기)
- 파일 크기 ≠ 사진 내용. 50KB+ 이어도 인물이 없을 수 있음
- 학습 데이터의 Pexels ID 기억은 신뢰 불가 (시간이 지나면 사진이 교체되거나 ID가 다른 사진)

## 해결
dev가 자체 검색 + Opus Vision 직접 확인으로 올바른 ID 선택:
- 5080651: 동남아 커플 공원 볼키스 페어룩 (KR×VN)
- 4099034: 벚꽃 가로수길 커플 들어올리기 (KR×JP)

## 재발 방지
1. Pexels 사진 제안 시 ID만 제공 금지 — 반드시 Vision(Opus Read) 또는 브라우저 스크린샷으로 내용 직접 확인 후 제공
2. HTTP 200 + 파일 크기는 "접근 가능"만 증명, 내용은 증명하지 않음
3. 이미지 선택 권한은 Vision 검증 가능한 dev에게 위임이 더 안전
