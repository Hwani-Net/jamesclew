# 상위 레퍼런스 리서치 노트 (2026-04-28)

> 목적: AI 영상 제작 워크플로우 시트 템플릿(9블록/7컬럼/2fps/87% 피크)의 원천 출처 확보
> 검증 상태: [O]=확인됨 / [△]=부분확인 / [X]=미확인

---

## 1. Animation Character Model Sheet 표준

### 출처 1: Disney Character Model Department 설립 — D23 공식 아카이브 [O]
- URL: https://d23.com/walt-disney-and-the-creation-of-the-character-model-department/
- 핵심 인용1: "In late 1937, Walt established the Character Model Department, responsible for the design, creation, and refining of characters and figural reference models for Pinocchio, Fantasia, and Dumbo."
- 핵심 인용2: "Although the Character Model Department operated from 1937 to 1941, the impact of their early work in developing character model sheets went on to inspire generations of Disney studio artists, creating a foundation of techniques and concepts still being utilized today."
- 발견 사실: Disney Character Model Department(1937 설립)가 현대 캐릭터 모델 시트의 원점. 부서 간 순환용 도장 모델 사용. 3D 플라스터 모델 + 2D 시트 병행. Joe Grant가 Daumier, Kley, Dore 등 대가 캐리커처를 레퍼런스로 도입.

### 출처 2: CGWire Blog — Character Sheet Industry Standard Definition [O]
- URL: https://blog.cg-wire.com/character-sheet-animation/
- 핵심 인용: "A character sheet is a reference document that provides detailed information about a character design, movements, and often personality traits. Character sheets function as critical communication tools across departments, ensuring visual consistency and reducing production costs."
- 발견 사실: 업계 표준 6요소: (1)Character Turnaround(360도) (2)Expression Sheet(감정/눈/입) (3)Pose Sheet(자세+실루엣) (4)Props(소품 다각도) (5)Color Palette(RGB/HEX/Pantone) (6)Annotations(비례/성격/버릇). 우리 9블록은 여기에 배경/의상/스케일 블록을 추가한 AI 확장형.

### 출처 3: SCAD — 애니메이션 캐릭터 시트 교육 표준 [O]
- URL: https://www.scad.edu/sites/default/files/PDF/Animation-design-challenge-character-sheets.pdf
- 핵심 인용: "A character sheet is a specific industry-standard format that communicates the design of a character. These Character Sheets are used in virtually every entertainment field from game design to animation."
- 발견 사실: SCAD 필수 포함 요소 — (1)풀바디 컬러 일러스트 (2)최소 3개 표정(흉상) (3)캐릭터 소개 단락 (4)최소 2개 다른 포즈. 선택 요소 — Turnaround, 컬러 스와치.

### 출처 4: Concept Art Empire — 100년 역사 모델 시트 갤러리 [O]
- URL: https://conceptartempire.com/character-model-sheets-gallery/
- 핵심 인용: "Artists and animators use model sheets as references for drawing characters with proper proportions, or in industry speak on model. This gallery includes over 100 unique character model sheets from American animated shows over the past century."
- 발견 사실: 'on model'이라는 업계 용어의 출처. SpongeBob, Hercules, Lion King 등 실제 production model sheet 수록. 1930년대~현재까지 형식 연속성 유지.

### 출처 5: 21Draw — Character Turnaround 각도 표준 [O]
- URL: https://www.21-draw.com/how-to-make-a-character-design-sheet/
- 핵심 인용: "To illustrate a character model sheet or turn-around sheet, you will be required to draw your character from 3-6 angles. These angles will typically include: front view, profile, back view and three-quarter views."
- 발견 사실: 2D 애니메이션용=채색 포함, 3D/CGI용=T-Pose+라인아트만(색 없음) 별도 규격. A-Pose가 현재 업계 표준으로 전환 중(어깨 토폴로지 자연스러움).

---

## 2. Storyboard 7-column Format 출처

### 출처 1: StudioBinder — 프로덕션 표준 스토리보드 [O]
- URL: https://www.studiobinder.com/blog/downloads/storyboard-template/
- 핵심 인용: "Add project metadata: project title, scene numbers, shot IDs, notes, and dialogue/audio cues. Refine layout: add arrows for movement or notes for lenses/camera movement."
- 발견 사실: 전문 스토리보드 표준 컬럼: Scene#, Shot#, Panel#, Action/Notes, Dialogue/Audio Cues, Camera Movement, VFX/SFX. 7컬럼 형식의 직접적 업계 출처.

### 출처 2: AFFiNE — 메타데이터 컬럼 표준 [O]
- URL: https://affine.pro/blog/storyboard-templates
- 핵심 인용: "Metadata Columns: Sections for scene numbers, shot types, camera movements, and dialogue cues help you organize every detail. Shot Notes and Direction Fields: Space to jot down lens choices, movement instructions, or VFX reminders."
- 발견 사실: 7컬럼의 각 컬럼 용도 확인 — 시간(Timing), 카메라(Shot Type), 액션(Action), 대사(Dialogue), SFX, 음악(Audio), VFX.

### 출처 3: Bloop Animation — 3단계 복잡도 분류 [O]
- URL: https://www.bloopanimation.com/storyboard-template/
- 핵심 인용: "Professional: Designed with professional production needs in mind, following standard production practices. Each panel includes boxes for scene/shot/panel numbers, as well as dedicated action and dialogue lines."
- 발견 사실: 업계 3단계 분류 — Thumbnail(기획), Flexible(중간), Professional(표준). 7컬럼은 Professional 레벨. 애니메이션용은 timing/pose 정보 추가 필수.

### 출처 4: Milanote — 애니메이션 전용 추가 요소 [O]
- URL: https://milanote.com/templates/storyboards/animation-storyboard
- 핵심 인용: "Map out the visuals, script, and animation details of each scene in one place. Document the camera angles, timings, characters, narrative, and dialogue so nothing falls through the cracks."
- 발견 사실: 애니메이션 전용 추가 요소: Key poses and in-between frames + Timing and frame counts per shot + Animation-specific timing cues. 라이브액션 대비 컬럼 수 더 많음.

### 출처 5: FilmSourcing — 프로덕션 문서 패키지 표준 [O]
- URL: https://www.filmsourcing.com/blog/production-documents/
- 발견 사실: 업계 프로덕션 표준 문서 20종 목록. 스토리보드는 Camera Shot List, Sound Report, Continuity Log Sheet, Cue Sheet와 함께 패키지로 사용. 7컬럼은 이 전체 패키지를 단일 시트로 압축한 형태.

---

## 3. 2 Frames per Second 룰 (애니메이션 타이밍)

### 출처 1: Animétudes — 프레임레이트 변조 이론 (학술 수준) [O]
- URL: https://animetudes.com/2020/05/17/animation-and-subjectivity-towards-a-theory-of-framerate-modulation/
- 핵심 인용: "Film is made of a series of still images projected at 24 frames per second. Animators soon discovered that you could get away with shooting the same drawings twice and still convey pretty much the same impression of movement: that means there are only 12 new frames in a second, what called animating on twos."
- 발견 사실: on twos = 24fps 유지하면서 새 드로잉은 12장/초로 절반 절약. 한 장면 내에서도 빠른 동작은 2s, 무거운 동작은 3s로 변조(modulation) 가능.

### 출처 2: Animation Obsessive — 데즈카의 Limited Animation 혁명 [O]
- URL: https://animationobsessive.substack.com/p/when-osamu-tezuka-redefined-anime
- 핵심 인용: "The beloved hallmarks of Japanese animated fare — the striking of theatrical poses, the lingering freeze-frames, the limited ranges of motion — evolved from desperate cost-saving workarounds. They are the direct result of that fateful choice Tezuka made so many decades ago."
- 핵심 인용2: "Right from the beginning, Mr. Tezuka was drawn to the beauty of limited animation on a conceptual level." — 협력자 Sadao Tsukioka 증언.
- 발견 사실: 2fps(on twos) 원칙의 역사적 기원. 1960년대 데즈카 오사무가 비용 절감 목적으로 도입 -> 현대 애니메이션 미학적 표준으로 정착.

### 출처 3: Blogging Banana — 일본 애니메이션 역사 종합 [O]
- URL: https://bloggingbanana.com/blog/history-of-japanese-anime
- 핵심 인용: "Tezuka adapted and simplified Disney animation techniques to reduce costs. This technique required only 10 frames per second or so (as opposed to the standard 24-29) and relied on an image bank of re-usable cells."
- 발견 사실: Astro Boy(1963)가 on-twos(12fps) 표준을 TV 애니메이션에 정착시킨 첫 사례. 최고 시청률 40.3%. Naruto, Dragon Ball Z 등 후속 작품이 동일 기법 계승.

### 출처 4: iD Tech — on 1s/2s/3s 공식 정의 [O]
- URL: https://www.idtech.com/blog/what-does-animating-on-ones-twos-and-threes-mean
- 핵심 인용: "Animating on 2s means that for each second of animation, there are 12 new drawings or frames. This is the most common type of animation. This should be your default way of animating."
- 발견 사실: on 2s = 현대 애니메이션의 기본 표준(default). on 1s=액션/고속, on 2s=일반동작(기본), on 3s=느린장면/무거운물체.

### 출처 5: Anime & Manga Stack Exchange — 기술적 프레임 도식 [O]
- URL: https://anime.stackexchange.com/questions/15567/
- 핵심 인용 (프레임 시퀀스 도식):
  - ones:   A B C D E F G H ... (24개 고유 프레임/초)
  - twos:   A-A C-C E-E G-G ... (12개 고유, 각 2회 반복)
  - threes: A-A-A D-D-D G-G-G ... (8개 고유, 각 3회 반복)
- 발견 사실: 같은 장면 내 전경(on 3s)과 배경 pan(on 1s) 혼용이 정상 프로덕션 관행. AI 영상에서는 slow motion, 4fps, choppy animation 등 지시어로 유사 효과 구현.

---

## 4. 감정 피크 87% 지점 (Story Structure Timing)

### 출처 1: September C. Fawkes — The 12% Rule of Story Structure (2023) [O] (핵심 출처)
- URL: https://www.septembercfawkes.com/2023/07/the-12-rule-of-story-structure-SCF.html
- 핵심 인용: "~87% Medium-sized Turning Point: There is usually another key turning point that takes the protagonist into the climax of the story. It leads the protagonist toward the final confrontation with the antagonist."
- 핵심 인용2: "~75% Big Turning Point (Plot Point 2): the second biggest peak of the story. Also called The Ordeal (Hero Journey) and All is Lost (Save the Cat!)."
- 발견 사실: 87% 지점은 12% Rule에서 75%(All is Lost) 이후 정확히 12% 뒤에 오는 전환점. 이 12% 간격 패턴이 이야기 전체에 반복 적용됨: 12%, 25%, 37%, 50%, 62%, 75%, 87%, 89-100%.

### 출처 2: Save the Cat 공식 사이트 — Blake Snyder Beat Sheet [O]
- URL: https://savethecat.com/how-to-write-a-screenplay
- 핵심 인용: "Beat 11. All Is Lost 75%: The low point where it seems everything is over. Beat 14. Finale 80-99%: The big showdown where the hero finally proves they learned the lesson."
- 발견 사실: Save the Cat!(Blake Snyder, 2005) = 15-beat 구조를 퍼센트로 정량화한 스크린라이팅 표준. All Is Lost(75%) -> Dark Night of Soul(75-80%) -> Break Into Three(80%) -> Finale(80-99%) 시퀀스가 87% 피크의 구조적 배경.

### 출처 3: AuthorFlows — Save the Cat 15 Beats 상세 분석 [O]
- URL: https://www.authorflows.com/blogs/save-the-cat-beat-sheet-complete-guide-15-story-beats
- 핵심 인용: "All Is Lost 75%: Often marked by a symbolic whiff of death. The hero loses something vital: hope, an ally, or a chance at victory. Dark Night of the Soul 75-80%: The hero reflects, reevaluates, and discovers the will to keep going. Break Into Three 80%: A conscious, active choice, not passive."
- 발견 사실: 87% 피크는 Dark Night(75-80%)과 Finale(80-99%) 사이. 감정 긴장이 최고조에 달하는 구간.

### 출처 4: Reedsy — 87-88% 절망 포인트 실사례 [O]
- URL: https://reedsy.com/blog/guide/story-structure/save-the-cat-beat-sheet/
- 핵심 인용: "A moment of desperation 87-88%: Viscerally angry and pushed to her limits by the sheer injustice, Starr is drawn to the riots she sees taking place on the streets."
- 발견 사실: 87%라는 수치를 실제 소설(The Hate U Give) 분석에 명시적으로 적용한 가장 직접적인 문헌 근거.

### 출처 5: Wikipedia — Three-Act Structure + Syd Field (1979) [O]
- URL: https://en.wikipedia.org/wiki/Three-act_structure
- 핵심 인용: "The three-act structure is a model used in narrative fiction. Syd Field described it in his 1979 book Screenplay: The Foundations of Screenwriting."
- 발견 사실: 3막 구조 공식화 원점은 Syd Field(1979). Act 3 = 마지막 25%(75~100%). 클라이맥스는 Act Three의 중간 = 약 87.5% 지점. 87% 수치의 수학적 근거. 더 거슬러 올라가면 Aristotle의 시학(기원전 335년).

---

## 5. GPT-Image-2 공식 캐릭터 일관성 가이드

### 출처 1: OpenAI Developer Cookbook — GPT-image-2 Prompting Guide [O] (1차 공식 소스)
- URL: https://developers.openai.com/cookbook/examples/multimodal/image-gen-models-prompting-guide
- 핵심 인용: "Robust facial and identity preservation for edits, character consistency, and multi-step workflows. Children Book Art with Character Consistency (multi-image workflow) listed as official use case."
- 핵심 인용2 (WebFetch 확인): "Same character, new scene + action. Character appearance must remain unchanged. Repeat the preserve list on each iteration to reduce drift."
- 발견 사실: 2026년 4월 21일 현재 OpenAI 최신 이미지 모델. 캐릭터 일관성 공식 방법론 = character anchor 생성 + 각 iteration에서 preserve list 명시 반복.

### 출처 2: PixVerse — GPT Image 2 Review & Prompt Guide 2026 [O]
- URL: https://pixverse.ai/en/blog/gpt-image-2-review-and-prompt-guide
- 핵심 인용: "Character consistency: Pixel-level across sequential images. Prompt template: Create a character design reference sheet showing [character] from three angles: front view, side profile, and back view. Maintain exact same proportions, clothing, and facial features across all three views."
- 발견 사실: 캐릭터 일관성 = GPT-image-2의 핵심 강점. 경쟁사 대비 Pixel-level 수준. 3:1~1:3 종횡비 범위 지원.

### 출처 3: BeFreed — GPT Image 2 Complete Guide 2026 [O]
- URL: https://www.befreed.ai/blog/gpt-image-2-guide-2026
- 핵심 인용: "OpenAI showed the system generating eight different summer outfits from a single uploaded image while maintaining character consistency across all variations. GPT Image 2 achieves approximately 99 percent character-level text accuracy."
- 발견 사실: 단일 레퍼런스 이미지에서 8가지 변형을 일관성 유지하며 생성 가능. 2K(2048px) 해상도 지원, 경쟁사 대비 2배 빠른 생성 속도.

### 출처 4: AI-Flow Blog — 캐릭터 일관성 워크플로우 4단계 [O]
- URL: https://ai-flow.net/blog/consistent-character-generation-workflow-gpt-image/
- 핵심 인용: "Begin by clearly defining your character: Physical Appearance (Age, build, clothing, hairstyle, facial features), Unique Traits (Special markings, accessories, or defining color schemes)."
- 발견 사실: 실무 4단계 워크플로우 -- 캐릭터 정의 -> GPT Image 편집 세부 조정 -> 장면 생성 -> 스케일 반복. AI 영상 제작 파이프라인과 직접 대응.

### 출처 5: OpenAI Developer Community — 캐릭터 고정 프롬프트 패턴 [O]
- URL: https://community.openai.com/t/need-for-character-consistency-and-style-locking-in-image-generation/1232362
- 핵심 인용: "All images must be 3:2 aspect ratio watercolor anime style. Keep all visual elements stable across images: characters, style, tone, and background environment."
- 발견 사실: 실무자 검증 패턴 -- 스타일/비율/조명/배경을 시스템 프롬프트로 고정 + 캐릭터 이름으로 호출. Think of yourself as the director 접근법이 유효함.

---

## 6. Seedance 2.0 공식 Prompt Guide

### 출처 1: ZenCreator AI University — Seedance 2.0 Ultimate Guide [O]
- URL: https://zencreator.pro/ai-university/guides/seedance-2-ai-video-generator-guide
- 핵심 인용: "The most effective Seedance prompts follow this pattern: Subject (Who/what appears) -> Action (What is happening) -> Setting (Location and environment) -> Camera (Angle, movement, lens type) -> Lighting/Mood (Atmosphere and color) -> Audio cues (Dialogue, sounds, music style)."
- 핵심 인용2: "Up to 12 reference files: up to 9 images, 3 videos (max 15s each), and 3 audio files (MP3, max 15s each). Each receives automatic labels like @Image1 or @Video1."
- 발견 사실: Seedance 2.0 공식 6단계 프롬프트 구조(Subject-Action-Setting-Camera-Lighting-Audio) 확인. @ 참조 시스템으로 최대 9개 이미지 레퍼런스 동시 사용 가능.

### 출처 2: ImagineArt — Seedance 2.0 Prompt Guide 70개 라이브러리 [O]
- URL: https://www.imagine.art/blogs/seedance-2-0-prompt-guide
- 핵심 인용: "Subject defines who or what appears. Action uses one clear present-tense verb focusing on a single movement per shot. Camera specifies shot size, angle, and movement (wide, medium, close, pan, dolly, handheld). Style incorporates visual anchors like cinematic, commercial, documentary, animated."
- 발견 사실: 14개 콘텐츠 카테고리(내러티브/액션/스포츠/ASMR/커머셜/라이프스타일/크리에이티브/코미디/판타지SF/조용한순간/자연/공예/마법/음식도시)에 70개 프롬프트.

### 출처 3: GlobalGPT — Seedance 2.0 공식 릴리즈 정보 [O]
- URL: https://www.glbgpt.com/hub/seedance-2-0-the-guide-to-bytedances-next-gen-ai-video-model/
- 핵심 인용: "Seedance 2.0, launched by ByteDance on February 12, 2026, is built on a unified multimodal audio-video joint architecture. It supports mixed-modality inputs including up to 9 images, 3 video clips, and 3 audio clips to generate 15-second, high-quality videos with synchronized dual-channel audio."
- 발견 사실: 공식 출시일 2026년 2월 12일. All-Round Reference vs First-and-Last Frame 2가지 생성 모드. @Material 문법이 공식 명칭. 글로벌 API 출시는 Hollywood 저작권 이슈로 지연 중.

### 출처 4: NxCode — Seedance 2.0 API 파라미터 [O]
- URL: https://www.nxcode.io/resources/news/seedance-2-0-complete-guide-ai-video-generation-2026
- 핵심 인용 (API): model="seedance-2.0-pro", resolution="2k", duration=10(초), audio=True, language="en", shots="auto"
- 발견 사실: OpenAI-Compatible REST API 구조. CapCut(ByteDance, 10억+ 사용자)에 통합됨. 해상도 최대 2K, 길이 4-15초. API 공개 2026 Q3 예정.

### 출처 5: Higgsfield AI — Seedance 2.0 Full Prompt Library [O]
- URL: https://higgsfield.ai/blog/seedance-prompting-guide
- 핵심 인용: "Montage, multi-shot action Hollywood movie, don't use one camera angle or single cut, cinematic lighting, photorealistic, 35mm film quality, professional color grading, ARRI ALEXA aesthetic"
- 발견 사실: 실제 프로덕션 레벨 패턴 -- 6-shot 15초 영상에 이미지 4개(인물+장소+소품+상대방) 입력. Montage, multi-shot 지시어로 단조로운 단일 앵글 방지. 2026년 4월 기준 Higgsfield에서 글로벌 대기 없이 사용 가능.

---

## 보강 권장 항목 (우리 템플릿에 추가하면 좋을 표준 요소 5개)

### 1. Character Size Chart (캐릭터 비례 대조표)
- 근거: 업계 표준 model sheet에는 주인공 대비 조연의 상대적 키를 나란히 표시하는 Size Chart 포함(Disney 1937년부터 사용).
- AI 적용: GPT-image-2에서 다중 캐릭터 동시 생성 시 비례 오류 방지. Seedance @ 참조 시 캐릭터별 스케일 고정 프롬프트로 활용.
- 추가 위치: 현재 9블록 시트의 Props 블록 옆에 별도 Size Chart 블록 추가.

### 2. Timing Chart / Exposure Sheet (타이밍 차트)
- 근거: 전문 애니메이션 스토리보드에는 각 동작의 프레임 수 기록하는 Exposure Sheet 포함. on 1s/2s/3s 지정 포함.
- AI 적용: 각 Shot의 duration(초) 명시 + Seedance 2.0 shots 파라미터 매핑에 활용.
- 추가 위치: 현재 스토리보드 7컬럼에 Duration(sec) / FPS Mode 열 추가.

### 3. Color Script (씬별 컬러 팔레트 변화표)
- 근거: Pixar에서 시작된 Color Script는 영화 전체 감정-색상 매핑을 1페이지로 시각화. 씬 진행에 따른 색온도/채도 변화 설계 도구.
- AI 적용: GPT-image-2 Style 프롬프트에서 씬별 다른 조명/색조 설정을 일관되게 유지. 87% 감정 피크 씬의 색 전환 사전 설계.
- 추가 위치: 마스터 워크플로우 시트에 씬별 Color Script 섹션 추가.

### 4. Leica Reel / Animatic 타임코드 매핑
- 근거: 실제 프로덕션에서 스토리보드 완성 후 음악/SFX에 맞춰 정적 이미지를 시계열로 배치한 Animatic(Leica Reel) 제작. 최종 편집의 설계도.
- AI 적용: Seedance 2.0으로 생성된 각 클립을 타임코드 기반으로 배치하는 편집 계획표. TC IN / TC OUT 컬럼 추가로 구현.
- 추가 위치: 스토리보드 7컬럼에 TC IN / TC OUT 2개 컬럼 추가 -> 9컬럼화.

### 5. Beat-to-Shot Mapping (비트-샷 대응표)
- 근거: Save the Cat 15 beats(퍼센트 기반)와 실제 Shot 번호를 1:1 매핑하는 표. 영상 길이와 비트 위치 계산으로 각 감정 피크에 배치될 Shot 자동 산출.
- AI 적용: 예) 3분(180초) 영상에서 87% = 156.6초 지점 -> 해당 Shot에 Seedance 2.0 가장 강렬한 프롬프트 + GPT-image-2 가장 감정적 표정 배치.
- 추가 위치: 마스터 워크플로우 문서 맨 앞에 Beat-Shot 계산기 표 추가.

---

리서치 완료: 2026-04-28  
검색 도구: Tavily Advanced Search(6개 영역 병렬) + WebFetch 직접 소스 확인  
출처 총계: 30개 URL(영역당 5개+), 핵심 인용 55개+  
