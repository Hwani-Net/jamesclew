---
title: "Sonnet Vision — 좌우 대칭 검수 누락 (Opus 직접 분석 필수)"
slug: pitfall-135-sonnet-vision-symmetry-blindness
date: 2026-05-19
category: vision-routing
tags: [vision, opus, sonnet, qa, symmetry]
severity: high
---

# pitfall-135 — Sonnet Vision 좌우 대칭 누락

## 증상
SadTalker 시범 mp4 (nuna-001-scene1.mp4) Sonnet 서브에이전트 Vision 검수:
- "Frame 4s: 입 크게 열림 ✓ 발화 정확히 표현"
- 결론: "SadTalker가 애니 캐릭터에서 이미 정상 작동 중"

그러나 대표님 시청 + Opus Vision 직접 분석:
- 입을 열 때마다 **좌측 입꼬리 ↑, 우측 입꼬리 ↓** 명확한 비대칭
- 대표님 지적 "입모양이 비뚤게 립싱크해" 정답

## 원인
1. **Sonnet 4.6 Vision 정확도 한계** — CLAUDE.md 명시: "Sonnet Vision 디테일 누락률 20~30%, Opus 대비 현저히 낮음"
2. **검수 항목 차이** — Sonnet은 "입 열림→닫힘 시계열 변화"만 평가, 좌우 대칭 비교 누락
3. **시계열 vs 공간** — 시간 흐름 (frame N→N+1) 비교는 잘 함, **공간 비대칭 (좌측 vs 우측)** 비교는 약함

## 해결
1. **CLAUDE.md 규칙 엄수**: Vision 검수는 Opus 직접 (Sonnet teammate에서 Vision 필요 시 Opus 메인에 SendMessage)
2. **검수 항목 명시 패턴**:
   - "입 모양 시계열 변화" (Sonnet OK)
   - "좌우 대칭" (Opus 필수)
   - "색상 정확도" (Opus 권장)
   - "텍스트 가독성" (Sonnet OK)
   - "구도 비율" (Opus 권장)

## 재발 방지
새 영상·이미지 산출물 검수 시:
- [ ] **대칭·정렬·정밀 비교**가 필요한가? → Opus 직접 Read
- [ ] **시간 변화·존재 여부**만 확인하면 됨? → Sonnet OK
- [ ] **사용자가 시청 후 지적할 만한 디테일**이 있는가? → Opus 사전 검수 필수

특히 **사람 얼굴·캐릭터** 분석은 좌우 대칭이 시청 인상의 핵심 → 항상 Opus.

## 관련
- [[pitfall-133-sadtalker-anime-asymmetry]] (Sonnet이 비대칭 못 잡아 진단 늦어짐)
- CLAUDE.md "Vision 라우팅 규칙": Opus 4.6 직접 Read, Sonnet Vision 금지
- `rules/architecture.md` Vision 우선순위 표
