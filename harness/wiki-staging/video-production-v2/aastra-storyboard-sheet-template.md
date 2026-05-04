---
title: "AI 아스트라 스토리보드 시트 템플릿 — 2 frames/sec + 카메라/SFX/음악 표"
slug: aastra-storyboard-sheet-template
type: template
date: 2026-04-28
tier: distilled
source: https://www.youtube.com/watch?v=7oN5U0XFhNU
project: video-production
tags:
  - storyboard
  - 2-frames-per-second
  - camera-action
  - sfx-mapping
  - music-mapping
---

# 스토리보드 시트 — Animating on Twos + 카메라/SFX/음악 표 (9컬럼)

영상 핵심 인용: **"Seedance에 '15초 영상 만들어줘'라고만 넣으면 카메라/액션/타이밍이 제멋대로 섞인다. 컷별 + 초별로 짜야 정교하게 영상이 나온다. 초마다 카메라 액션 효과음 음악까지 표에 한꺼번에 넣어 밀도를 더해준다."**

## 산업 표준 출처 체인

| 요소 | 원천 | 인용 |
|------|------|------|
| Storyboard 7컬럼 | [StudioBinder Pro Template](https://www.studiobinder.com/blog/downloads/storyboard-template/) + [AFFiNE](https://affine.pro/blog/storyboard-templates) + [Bloop Animation](https://www.bloopanimation.com/storyboarding/) | "Scene#/Shot#/Panel#/Action/Dialogue/Camera/SFX 7컬럼 — Professional 레벨 업계 표준" |
| Animatic TC 컬럼 (v2 추가) | Disney Leica Reel 전통 → 현대 Animatic 표준 | "TC IN / TC OUT 매핑은 NLE 합성 시 필수" |
| Timing/Pose 컬럼 (v2 추가) | [Milanote Animation Storyboard](https://www.milanote.com/) | "애니메이션 전용 Pose/Timing 추가 컬럼" |
| **"animating on twos" 용어** | **오사무 데즈카 (1963, Astro Boy)** [Animation Obsessive](https://animationobsessive.substack.com/p/when-osamu-tezuka-redefined-anime) + [Animétudes](https://animetudes.com/2020/05/17/animation-and-subjectivity-towards-a-theory-of-framerate-modulation/) | "Tezuka가 Disney 기법을 비용 절감 목적으로 단순화하면서 on-twos(12fps) 표준을 TV 애니메이션에 정착" |
| 감정 피크 87% (수미상관 + 클라이맥스) | Aristotle 시학 → Syd Field(1979) 3막 구조 → Blake Snyder Save the Cat!(2005) → [September Fawkes 12% Rule (2023)](https://www.septembercfawkes.com/2023/07/the-12-rule-of-story-structure-SCF.html) + [Reedsy 적용 사례](https://reedsy.com/blog/guide/story-structure/save-the-cat-beat-sheet/) | "All is Lost(75%) 이후 12% 후 = 87% 클라이맥스 진입 전환점" |
| AI 시대 적용 (AI 아스트라) | [YouTube 7oN5U0XFhNU](https://www.youtube.com/watch?v=7oN5U0XFhNU) | "초마다 카메라 액션 효과음 음악까지 표 / 2-frame per second" |

## 9컬럼 표준 표 (v2 보강)

| 컬럼 | 영문 | 내용 | 출처 |
|------|------|------|------|
| 1. 컷# | Shot # | 01 / 02 / ... / NN (2자리) | StudioBinder |
| 2. **TC IN / OUT** | Timecode | `00:00:45:00 / 00:00:47:12` (NLE timecode, fps 기준) | Disney Leica Reel (v2 추가) |
| 3. 시간 (런타임) | Duration | `2.5s` (런타임 길이) | 표준 |
| 4. 비주얼 | Visual | 시작 프레임 + 끝 프레임 2장 | StudioBinder + Tezuka on-twos |
| 5. 카메라 액션 | Camera Move | Push / Pan / Tilt / Dolly / Tracking | StudioBinder |
| 6. 액션/포즈 | Action / Pose | 캐릭터 동작 + Timing 비고 | Milanote (v2 추가) |
| 7. 신 설명 | Scene Description | 무슨 일이 일어나는지 1~2문장 영문 | StudioBinder |
| 8. 효과음 | SFX | Wind / Whoosh / Crane cry / Gate resonance | StudioBinder |
| 9. 음악 | Music | Major key uplift / Brass fanfare / Flute melody | StudioBinder |

> v1 7컬럼 → **v2 9컬럼** (TC IN/OUT, Action/Pose 분리). Render duration 정확도 + NLE 합성 호환성 향상.

## "Animating on Twos" 룰 (용어 정정)

- 정확한 업계 용어: **"animating on twos"** (24fps 기준 2프레임당 1 고유 프레임 = **유효 12fps**)
- 잘못된 표기: "2fps" — 일반 영상 fps와 혼동, 업계에서 사용하지 않음
- 적용: **시작 프레임 + 끝 프레임 2장**을 컷마다 명시 (시각적 anchor)
- 컷 길이 1.5~2.5초 권장 (짧을수록 보간 정밀)
- "15초 통컷 prompt" 절대 금지 — Seedance가 카메라/타이밍을 임의 해석
- Seedance는 시작/끝 프레임 **사이만** 보간 (Tezuka의 limited animation 원리 디지털 적용)

## 구조 룰

### 수미상관 (Frame-Story Bracket)
- **오프닝 컷 = 클로징 컷의 거울**
  - 예: 경복궁 광화문 (오프닝) → 판타지 → 경복궁 광화문 (클로징, 같은 구도)
- 시청자에게 "여행을 다녀왔다"는 감각 부여

### 감정 피크 배치 (Emotion Peak Beat — Save the Cat 12% Rule)
- **2분 영상 기준 1분 45초 부근에 클라이맥스 = 영상 길이의 87% 지점**
- 출처: Save the Cat 15-beat 구조 (Snyder 2005) + Fawkes 12% Rule (2023)
- 87% 의미: All is Lost(75%) 이후 12% 후 = 클라이맥스 **진입 전환점** (클라이맥스 자체는 89~100%)
- 영상별 Beat-to-Shot 계산:
  - 30초 → 26초 지점 클라이맥스 진입
  - 1분 → 52초
  - 2분 → 1분 45초 (영상 데모 일치)
  - 5분 → 4분 21초
- 음악도 동일 구조 — Suno에 기승전결 명시 후 생성 (BGM 87% 지점에 swelling)

### 오디오 맵핑 (Audio Mapping in Sheet)
- 가야금/해금/대금/첼로/오케스트라 — 컷별 악기 미리 배치
- AI 모르면 GPT-5.5와 협의: "이 컷 분위기에 맞는 한국 전통악기는?"

---

## 예시 — "해치의 이상한 나라" 2분 15초 뮤직비디오 발췌 (CUT 01-06, 0:45-1:00 구간)

| # | 시간 | 카메라 액션 | 신 설명 | 비고 | 효과음 | 음악 |
|---|------|-------------|---------|------|--------|------|
| 01 | 0:45.0-0:47.5 | Push through into wide reveal | Sky palace realm revealed. Breathtaking first glimpse | — | Celestial ambience, wind | Full orchestra wonder theme |
| 02 | 0:47.5-0:50.0 | Medium shot with slow rotation around her | Discovery of flight. Childlike joy | — | Gentle wind chimes | Major key uplift |
| 03 | 0:50.0-0:52.5 | Two-shot flying tracking | Reunion with Haechi in the sky. Flight together begins | — | Whoosh of flight | Flute melody over driving drums |
| 04 | 0:52.5-0:55.0 | Side-tracking shot | Magical encounter with a crane rider | — | Crane cry, flapping wings | Light bells and flute |
| 05 | 0:55.0-0:57.5 | Approaching dolly shot | Giant sky palace gate opens welcomingly | — | Gate opening with deep resonance | Brass fanfare |
| 06 | 0:57.5-1:00.0 | Push through and reveal | They enter deeper into kingdom. Market visible below | — | Wind, magical chimes | Transition sting, energy carries forward |

### Director's Note (CUT 04 예시)
> The biggest visual spectacle of the sequence — discovery of flight and wonder of the fantasy realm. Fresh modern illustration meets Korean mythology. Crane rider serves as a passing magical guide, leading into CUT 05.

---

## 빈 템플릿 (복사해서 사용)

```markdown
# 스토리보드 시트 — {프로젝트명} {길이}

## 메타
- 길이: {예: 2분 15초}
- 컷 개수: {예: 54개 (2.5초 × 54)}
- 클라이맥스 시점: {1분 45초}
- 음악: Suno (기승전결 구조)
- 영상 생성: Seedance 2.0 (15초 단위 또는 2.5초 단위)

## 컷 표

| # | 시간 | 카메라 액션 | 신 설명 | 비고 | 효과음 | 음악 |
|---|------|-------------|---------|------|--------|------|
| 01 | 0:00.0-0:02.5 | | | — | | |
| 02 | 0:02.5-0:05.0 | | | — | | |
| ... | | | | | | |

## 컷별 Director's Note
### CUT NN
> ...
```

## 검증 체크리스트
- [ ] 모든 컷에 7컬럼 다 채워짐 (빈칸 없음)
- [ ] 시작/끝 프레임 2장 첨부됨 (2fps 룰)
- [ ] 수미상관 구조 (오프닝 = 클로징 거울)
- [ ] 감정 피크가 87% 지점 ± 5% 내 배치됨
- [ ] 효과음 + 음악이 컷마다 명시됨 (—만 있는 컷 없음)
- [ ] 캐릭터 등장 컷에 master_sheet 참조 명시

## 관련
- [[aastra-character-sheet-template]] — 캐릭터 일관성 reference
- [[aastra-master-prompts]] — Storyboard prompt 섹션
- [[aastra-workflow-v2]] — Seedance 2.0 단계
