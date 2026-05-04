---
title: "AI 아스트라 컬러 팔레트 — HEX 락 룰"
slug: aastra-color-palette
type: template
date: 2026-04-28
tier: distilled
source: https://www.youtube.com/watch?v=7oN5U0XFhNU
project: video-production
tags:
  - color-palette
  - hex-lock
  - consistency
---

# 컬러 팔레트 시트 — HEX 락 룰 + Color Script (Pixar)

영상 핵심 인용: **"파란색이라고만 쓰면 AI가 진한/연한으로 매번 재해석한다. 반드시 HEX 코드로 박아야 일관된 컬러가 나온다."**

## 산업 표준 출처 체인

| 요소 | 원천 | 인용 |
|------|------|------|
| HEX 락 룰 | 디지털 그래픽 표준 (CSS3 / sRGB) | "어휘 표기는 렌더러마다 해석 차이, 6자리 HEX는 픽셀 정확" |
| **Color Script** (v2 신설) | **Pixar (Toy Story 1995~ 표준화)** | "Color Script: 영화 전체의 색감 흐름을 시간축으로 시각화. 감정 곡선과 색조 변화를 1장에 매핑. Disney/Pixar 모든 작품에 사용" |
| Character 4색 팔레트 | Adobe Color / IBM Carbon Design System | "주요 4색 + 보조 2색 패턴이 인지·기억 최적" |
| AI 시대 적용 (AI 아스트라) | [YouTube 7oN5U0XFhNU](https://www.youtube.com/watch?v=7oN5U0XFhNU) | "캐릭터별 4색 + 톤 콘셉트 1줄" |

## 룰 (Color Lock Rule)

| 항목 | 표준 | 금지 |
|------|------|------|
| 모든 색상 | `#XXXXXX` 6자리 HEX | "blue", "파란색", "sky blue" 같은 어휘 |
| 프롬프트 인용 | `Sky blue (#5B9FD5)` 형식 | HEX 누락 |
| 컷 간 매칭 | 4색 팔레트 1세트 고정 | 컷마다 색 변경 |
| 콘셉트 정렬 | 톤 콘셉트 1문장 명시 | 톤 미정의 |

## 캐릭터별 4색 팔레트

### 팔레트 1 — 서하린 (주인공 / 청량 톤)

| 색 이름 | HEX | 역할 |
|---------|-----|------|
| 하늘색 (Sky Blue) | `#5B9FD5` | 치마 메인 컬러 |
| 코랄 레드 (Coral Red) | `#E85A5A` | 머리 리본, 저고리 자수, 노리개 |
| 크림 화이트 (Cream White) | `#F8F0E0` | 저고리 베이스, 배경 톤 |
| 버터엘로 (Butter Yellow) | `#F2D86C` | 노리개 술, 액세서리 포인트 |

> **톤 콘셉트**: 청량함, 산뜻함, 전통과 현대의 조화

### 팔레트 2 — 해치 (보조 / 신비 톤)

| 색 이름 | HEX | 역할 |
|---------|-----|------|
| 청록 (Turquoise) | `#4A9B9B` | 비늘 메인 컬러 |
| 황금 (Gold) | `#E8C766` | 갈기, 눈, 무늬 |
| 코랄 레드 (Coral Red) | `#E85A5A` | 매개 색 (서하린 팔레트와 공통) |
| 크림 (Cream) | `#F8F0E0` | 배경 톤 (서하린 팔레트와 공통) |

> **톤 콘셉트**: 신비로움, 친근함, 고귀함, 장난기

### 팔레트 통합 룰
- **공통 컬러 2종 (#E85A5A coral, #F8F0E0 cream)**: 두 캐릭터가 한 화면에 등장할 때 시각적 통일성 부여
- **차별 컬러 4종 (sky/butter vs turquoise/gold)**: 캐릭터 정체성 구분
- 결과: 6색 마스터 팔레트로 전체 영상 컬러 통제 가능

## 프롬프트 적용 예시

```
Color palette (HEX-locked, NO substitutions):
- Sky blue #5B9FD5 (chima/skirt)
- Coral red #E85A5A (ribbon, embroidery)
- Cream white #F8F0E0 (jeogori base)
- Butter yellow #F2D86C (norigae tassel)

Tone concept: refreshing, fresh, harmony of tradition and modernity.
DO NOT substitute with generic 'blue', 'red', 'white', or 'yellow'.
```

## Color Script (v2 신설 — Pixar 표준)

영상 전체의 색감 흐름을 시간축으로 시각화. **2분 영상 12컷 기준 예시:**

```
시간    | 컷# | 주조색         | 분위기      | 감정
--------|-----|----------------|-------------|--------
0:00-15 | 01  | #F8F0E0 cream  | 평온/일상   | curious
0:15-30 | 02  | #5B9FD5 sky    | 발견/호기심 | wondering
0:30-45 | 03  | #E8C766 gold   | 각성/마법   | startled
0:45-60 | 04  | #4A9B9B turq   | 모험/도전   | excited
1:00-15 | 05  | #E8C766 gold   | 비행/자유   | joyful
1:15-30 | 06  | #5B9FD5 sky+gold | 절정/환희 | climactic ←87% 지점
1:30-45 | 07  | #E85A5A coral  | 감동/눈물   | moved
1:45-2:00| 08 | #F8F0E0 cream  | 귀환/여운   | reflective
```

> Color Script는 마스터 시트 캐릭터 4색을 **시간축에 분배**해서 감정 곡선과 일치시키는 도구.
> Pixar는 모든 장편을 이 1장으로 시각화 후 production 진입.

## 검증 체크리스트
- [ ] 마스터 시트 컬러 패널 영역에 4색 원/사각형이 라벨과 HEX 함께 명시됨
- [ ] 시트 내 의상/소품의 실제 컬러가 HEX 값과 일치 (눈으로 비교)
- [ ] 톤 콘셉트 1문장이 시트 하단에 적힘
- [ ] 컷 N개 모두 같은 4색 안에서만 표현됨
- [ ] **Color Script 1장이 작성됨** (v2 신설)
- [ ] **87% 지점에 색감 피크 매핑됨** (Save the Cat 12% Rule + Pixar Color Script)

## 관련
- [[aastra-character-sheet-template]] — 시트 내 COLOR 블록
- [[aastra-master-prompts]] — 프롬프트 내 컬러 락 적용
