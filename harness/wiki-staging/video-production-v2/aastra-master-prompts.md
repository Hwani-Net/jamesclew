---
title: "AI 아스트라 마스터 프롬프트 (GPT 5.5 image-2 / Seedance 2.0 Copy & Paste)"
slug: aastra-master-prompts
type: template
date: 2026-04-28
tier: distilled
source: https://www.youtube.com/watch?v=7oN5U0XFhNU
project: video-production
tags:
  - prompts
  - gpt-5.5
  - image-2
  - seedance-2.0
---

# 마스터 프롬프트 — Copy & Paste 템플릿 (v2 보강)

영상 캡처(이미지 12) 기반 실제 사용된 프롬프트 구조 재현 + OpenAI 공식 Cookbook 패턴 + Seedance 2.0 6단계 구조 통합.

## 산업 표준 출처 체인

| 요소 | 원천 | 인용 |
|------|------|------|
| **gpt-image-2** 공식 명칭 | [OpenAI Developer Cookbook (2026-04-21 update)](https://developers.openai.com/cookbook/examples/multimodal/image-gen-models-prompting-guide) | "공식 모델명: `gpt-image-2`. AI 아스트라 영상의 'GPT 5.5 image-2' 표현은 비공식 — 본 문서는 공식 명칭 사용" |
| Character Anchor 패턴 | OpenAI Cookbook "Children's Book Art with Character Consistency" | "create a character anchor + repeat the preserve list on each iteration to reduce drift" |
| Preserve List | OpenAI Cookbook | "각 iteration마다 보존 항목 명시 반복 — 우리 [APPEARANCE] 블록과 [COLOR LOCK] 블록의 근거" |
| **Seedance 2.0 공식 출시** | 2026-02-12 ByteDance | "공식 6단계: Subject → Action → Setting → Camera → Lighting/Mood → Audio Cues" |
| Seedance @ 참조 시스템 | [Seedance Prompting Guide (Higgsfield)](https://higgsfield.ai/blog/seedance-prompting-guide) + [zencreator.pro](https://zencreator.pro/ai-university/guides/seedance-2-ai-video-generator-guide) | "@ 시스템으로 최대 9 이미지 + 3 영상 + 3 오디오 동시 참조 가능" |
| K-한복 캐릭터 디자인 (AI 아스트라) | [YouTube 7oN5U0XFhNU](https://www.youtube.com/watch?v=7oN5U0XFhNU) | 한국어 시트 9블록 매거진 레이아웃 |

---

## 1. CHARACTER MASTER SHEET PROMPT (서하린 예시)

> GPT 5.5 image-2, 비율 3:4

```
You are a professional animation character designer, art director, and visual concept artist.

Your task is to generate a complete animated character profile sheet for a Korean female college student protagonist in a 2-minute music video titled "Haechi's Wonderland" (해치의 이상한 나라).

---

[LANGUAGE CONTROL]

Target Language: Korean

- All visible text inside the image MUST be written in Korean
- English labels allowed as secondary annotations in parentheses
- Includes:
    - character name
    - profile / biography
    - role description
    - labels (expressions, outfits, poses)
    - annotations
- NO Japanese characters anywhere

---

[ART STYLE — STRICT]

Modern Japanese illustrator aesthetic, fresh bright digital illustration style popular among contemporary Pixiv artists.

- Clean cel-shading with defined light and shadow
- Medium-weight clean outlines
- Crisp digital finish, NO photorealistic rendering
- Bright luminous colors, high saturation but CLEAN
- Sky blue + coral red + cream white palette
- NOT moe-childish, NOT retro, NOT muddy
- Contemporary refined illustration

---

[OUTPUT STRUCTURE]

Generate ONE final character sheet image using this magazine-style layout:

masterpiece, best quality, ultra detailed, 4k resolution,
modern anime illustration, clean digital art, fresh Pixiv style,
professional animation character design sheet, editorial layout.

---

[CHARACTER IDENTITY (이름 / 프로필)]

Name (이름): 서하린 (Seo Harin)
Birthdate (생년월일): 2004년 3월 15일
Age (나이): 22세
Height (신장): 164cm
Nationality (국적): 대한민국
MBTI: ENFP
Role (역할): 한복을 입고 경복궁을 방문한 호기심 많은 여대생

Profile description (프로필 소개 - in Korean):
"밝고 호기심 많은 성격의 대학생. 전통 문화에 관심이 많아 한복을 입고 경복궁을 방문했다가 신비한 해치를 만나게 된다. 차분하면서도 모험을 즐기는 이중적인 매력을 가진 캐릭터. 표현력 있는 눈과 부드러운 웨이브 헤어가 특징."

---

[APPEARANCE (외형)]

Left side large portrait (leftmost column, full height):
- Upper body portrait, modern anime illustration style
- Wavy black hair reaching shoulders with soft bangs
- Vivid coral red ribbon tied on top of head
- Large expressive brown eyes in contemporary illustrator style (NOT moe-childish, refined and mature)
- Pale porcelain skin with natural anime shading
- Wearing the signature hanbok outfit
- Soft neutral background with light sky blue gradient

Hair: chest-length wavy black hair (NOT long, NOT short — exactly chest-length)
Outfit: cream white jeogori (#F8F0E0) + sky blue chima (#5B9FD5) + coral red ribbon (#E85A5A) + butter yellow norigae tassel (#F2D86C)
Footwear: traditional flower shoes (kkotsin) + white beoseon socks
Accessories: norigae pendant, hair ribbon, optional flower hairpin

---

[COLOR LOCK — CRITICAL]

Color palette (HEX-locked, NO substitutions):
- Sky blue #5B9FD5 (chima/skirt)
- Coral red #E85A5A (ribbon, embroidery, accent)
- Cream white #F8F0E0 (jeogori base, background tone)
- Butter yellow #F2D86C (norigae tassel)

Tone concept: refreshing, fresh, harmony of tradition and modernity.
DO NOT substitute with generic 'blue', 'red', 'white', or 'yellow'.

---

[SHEET LAYOUT — 9 BLOCKS]

1. IDENT — Profile box (top right): Name / Age / Nationality / MBTI / Role
2. FACE — Expressions (6 headshots): 기본(Neutral) / 미소(Soft Smile) / 놀람(Surprised) / 경이(Wonder) / 결의(Determined) / 감동(Moved)
3. FIT — Outfits (4 panels): Main Hanbok (메인) / Jeogori Detail / Chima Detail / Accessories
4. BODY — Full Body (3 panels): Front (정면) / Side (측면) / Back (후면)
5. POSE — Poses (5 panels): walking / running / surprised / staring / laughing
6. PARTS — Styling Breakdown (7 items): Jeogori / Chima / Flower Shoes / Beoseon / Norigae / Deenggi / Hair Accessories
7. PROPS — Story Props (3 items): Traditional Fan / Paper Lantern / Magical Peach
8. COLOR — Color & Tone: 4 HEX swatches + tone concept line
9. MOOD — Mood Board: 4 reference images (Gyeongbokgung gate / cherry blossom / blue sky / sunset hanok)

All 9 blocks on ONE sheet, magazine editorial layout.
```

---

## 2. HAECHI MASTER SHEET PROMPT (보조 캐릭터)

```
[CHARACTER IDENTITY (이름 / 프로필)]

Name (이름): 해치 (Haechi)
Alt name (별명): 해태 (Haetae)
Type (종족): Korean Mythological Guardian (한국 신화 수호수)
Origin (출처): Ancient Korean mythology, symbol of justice and fire prevention
Size (크기): 80cm shoulder height (large dog / lion-sized)
Age (나이): 1000+ years old

Profile description:
"수호수. 천 년간 경복궁을 지켜온 신수. 평소엔 석상이지만 위험이 다가올 때 깨어난다. 정의를 지키고 거짓을 가려내는 신비로운 능력. 강한 외모지만 친근하고 현대 감성도 갖춘 사랑스러운 신수."

---

[APPEARANCE]

- 4-legged guardian beast, lion-dog hybrid silhouette
- Turquoise scales (#4A9B9B) covering body
- Golden flowing mane (#E8C766) — long curly fur around neck and tail
- Two small horns on forehead
- Golden eyes (#E8C766) with vertical pupils
- Coral red accent on collar/chest medallion (#E85A5A)
- Cream underbelly (#F8F0E0)

---

[COLOR LOCK]

- Turquoise #4A9B9B (scales — main)
- Gold #E8C766 (mane, eyes, patterns)
- Coral red #E85A5A (medallion, accent)
- Cream #F8F0E0 (underbelly, background)

Tone concept: mystical, friendly, noble, playful.

---

[SHEET LAYOUT — 9 BLOCKS]

1. IDENT — Profile box: Name / Type / Origin / Size / Age
2. FORM — Form States (4 panels): Stone Statue (석상) / Awakening (각성중) / Living Form (살아있는 해치, MAIN/메인) / Flying (비행중)
3. FACE — Expressions (6 headshots): 평온(Calm) / 장난(Playful) / 호기심(Curious) / 진지(Serious) / 웃음(Laughing) / 부드러움(Gentle)
4. BODY — Full Body (3 panels): Front / Side / Back
5. POSE — Poses (5 panels): Running (달리기) / Jumping (점프) / Roaring (포효) / Sitting (앉기) / Playing (장난)
6. DESIGN — Design Breakdown (6 items): Mane / Scales / Eyes / Horns / Tail / Feet
7. ABILITIES — Abilities (6 icons): Shape-shifting / Portal Creation / Flight / Edge / Protection / Foresight
8. COLOR — 4 HEX swatches + tone line
9. SCALE & MOOD — Scale reference (vs Seo Harin 1:0.6) + mood board (palace / sky / market)

All 9 blocks on ONE sheet, magazine editorial layout.
```

---

## 3. STORYBOARD SHEET PROMPT (씬별)

```
You are a film director and storyboard artist.

Generate a single storyboard sheet image for the following scene from "Haechi's Wonderland" music video.

---

[INPUT — Master Sheets]

Reference Image 1: {character_master_sheet_seo_harin.png}
Reference Image 2: {character_master_sheet_haechi.png}

Maintain 100% visual consistency with these master sheets — same face, hair, outfit, color palette, all HEX-locked.

---

[SCENE INFO]

Scene title: {예: "Sky Palace Entry"}
Time range: 0:45-1:00 (15 seconds)
Cuts: 6 cuts × 2.5 seconds each
Total frames shown: 12 (start + end frame per cut, 2 frames/sec rule)

---

[STORYBOARD TABLE — 7 COLUMNS]

Generate a magazine-style storyboard sheet with this table:

| # | Time | Visual (start+end) | Camera Action | Scene | SFX | Music |
|---|------|--------------------|---------------|-------|-----|-------|
| 01 | 0:45.0-0:47.5 | [2 panel images] | Push through into wide reveal | Sky palace realm revealed. Breathtaking first glimpse | Celestial ambience, wind | Full orchestra wonder theme |
| 02 | 0:47.5-0:50.0 | [2 panel images] | Medium shot with slow rotation around her | Discovery of flight. Childlike joy | Gentle wind chimes | Major key uplift |
| ... continue ...

Add a Director's Note paragraph at the bottom describing visual spectacle and narrative function of the most important cut.

---

[STYLE]

Same modern anime illustration style as the master sheets.
Magazine editorial layout, dark background, gold accent dividers.
All Korean labels with English in parentheses.
```

---

## 4. SEEDANCE 2.0 VIDEO PROMPT (컷 단위 — 공식 6단계 구조)

> **공식 6단계 구조** (ByteDance Seedance 2.0, 2026-02-12 출시): Subject → Action → Setting → Camera → Lighting/Mood → Audio Cues. **@ 참조 시스템**으로 최대 9 이미지 + 3 영상 + 3 오디오.

```
[@ REFERENCES — 최대 9 image / 3 video / 3 audio]
@image1: master_seo_harin.png (character anchor)
@image2: cut_01_start.png (start frame, animating-on-twos rule)
@image3: cut_01_end.png (end frame)
@image4: storyboard_sheet_scene_05.png (scene composition reference)

[CUT INFO]
Cut #01 — TC 00:00:45:00 → 00:00:47:12 (2.5 sec, 24fps)

[1. SUBJECT]
A young Korean woman, 22yo, named Seo Harin from @image1.
Maintaining 100% consistency with master sheet (HEX-locked colors, chest-length wavy black hair, coral red ribbon).

[2. ACTION]
Slowly emerges from drifting clouds, hair flowing in wind, eyes wide with wonder. Hands gently outstretched.

[3. SETTING]
Sky palace realm in the distance. Floating Korean traditional architecture (단청 painted hanok) on cloud platforms. Cherry blossom petals drift through air. Golden hour light.

[4. CAMERA]
Push-through dolly motion through clouds, opening to wide reveal of sky palace. Camera height: medium shot rising to high angle. Smooth Steadicam feel.

[5. LIGHTING / MOOD]
Soft golden hour with celestial light rays. Sky blue (#5B9FD5) tone with coral red (#E85A5A) accent on ribbon. Mystical, breathtaking, sense of discovery. Tone concept: refreshing, fresh, harmony of tradition and modernity.

[6. AUDIO CUES]
SFX: Celestial ambience layered with gentle wind. Subtle wind chime resonance.
Music: Full orchestra wonder theme entering — major key, swelling strings, hint of Korean daegeum flute.

[CONSISTENCY LOCK]
- Same face / hair / outfit as @image1 (HEX-locked: #5B9FD5 chima, #F8F0E0 jeogori, #E85A5A ribbon, #F2D86C tassel)
- Modern anime illustration style (NOT photorealistic)
- Animating on twos (24fps source, 12fps unique frames) — Tezuka 1963 limited animation aesthetic

[OUTPUT]
2.5 second clip, 1080×1920 (9:16), 24fps source.
Start frame matches @image2 exactly.
End frame matches @image3 exactly.
Seedance interpolates only between start/end (animating on twos rule, NOT free generation).
```

---

## 5. SUNO MUSIC PROMPT (전체 BGM)

```
2-minute Korean fantasy music video soundtrack.

Structure (matches video story arc):
- 0:00-0:30 — Mysterious opening, traditional Korean instruments (gayageum, daegeum), low energy
- 0:30-1:00 — Awakening theme, building drums, brass entering
- 1:00-1:45 — Adventure flight theme, full orchestra, energetic
- 1:45-2:00 — EMOTIONAL PEAK, soaring strings + choir, climax
- 2:00-2:15 — Resolution, returning to mystery (수미상관 mirror of opening)

Instruments: Gayageum (가야금), Haegeum (해금), Daegeum (대금), Cello, Full Orchestra, Light Bells, Flute, Brass, Choir
Mood: K-fantasy, modern cinematic, mystical
NO vocals, instrumental only

Tempo: 90 BPM base, accelerating to 120 at peak
Key: A minor (mystery) → C major (peak) → A minor (resolution)
```

---

## 사용 절차

1. **Stage 1 — GPT 5.5 image-2 (3:4)**
   - CHARACTER MASTER SHEET PROMPT 1, 2 → 마스터 시트 2장 생성
   - STORYBOARD SHEET PROMPT 3 → 씬별 스토리보드 시트 생성
2. **Stage 2 — Seedance 2.0**
   - 컷별 SEEDANCE VIDEO PROMPT 4 입력 → 2.5~15초 클립 생성
3. **Stage 3 — Suno**
   - SUNO MUSIC PROMPT 5 입력 → BGM 생성
4. **Stage 4 — 편집**
   - ffmpeg로 컷 합성 + BGM 오버레이 + 자막

## 관련
- [[aastra-character-sheet-template]] — 시트 9블록 표준
- [[aastra-color-palette]] — HEX 락 룰
- [[aastra-storyboard-sheet-template]] — 7컬럼 표
- [[aastra-workflow-v2]] — 전체 파이프라인
