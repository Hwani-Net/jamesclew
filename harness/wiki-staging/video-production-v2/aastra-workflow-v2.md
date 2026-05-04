---
title: "AI 아스트라 워크플로우 v2 — GPT 5.5 + Seedance 2.0 통합"
slug: aastra-workflow-v2
type: workflow
date: 2026-04-28
tier: synthesized
source: https://www.youtube.com/watch?v=7oN5U0XFhNU
project: video-production
tags:
  - workflow
  - gpt-5.5
  - seedance-2.0
  - suno
  - master
---

# 워크플로우 v2 — GPT 5.5 + Seedance 2.0 통합

> 영상 출처: AI 아스트라 "GPT 5.5 미쳤다?! AI 장편 애니메이션 딸깍 완성!" (2026-04-25, 길이 10:52)
> 데모 결과물: "해치의 이상한 나라" 2분 15초 K-판타지 뮤직비디오, 작업 시간 60분
> v2 보강 (2026-04-28): 30개 산업 표준 출처 발굴, 보강 5건 적용 — [[aastra-upstream-references]]

## 산업 표준 출처 체인 (전체 통합)

| 카테고리 | 원천 | 본 워크플로우 적용 |
|----------|------|-------------------|
| Character Model Sheet | Disney 1937 → CGWire / SCAD 표준 | 캐릭터 시트 10블록 |
| Storyboard 7컬럼 | StudioBinder + AFFiNE + Bloop | 스토리보드 9컬럼 (TC IN/OUT 추가) |
| Animating on Twos | Tezuka 1963 (Astro Boy) | "animating on twos" 용어 정정 (12fps) |
| 87% Climax Rule | Aristotle → Syd Field → Save the Cat → Fawkes 12% Rule (2023) | 감정 피크 87% 배치 |
| Color Script | Pixar (Toy Story 1995~) | 컬러 팔레트 v2 신설 섹션 |
| Character Anchor | OpenAI Cookbook (2026-04-21) | gpt-image-2 프롬프트 패턴 |
| Seedance 6단계 | ByteDance (2026-02-12 출시) | Seedance 비디오 프롬프트 |
| K-한복 적용 | AI 아스트라 (2026-04-25) | 한국어 시트 + 한복 캐릭터 |

## 핵심 메시지
**GPT 5.5의 image-2 + Seedance 2.0 + Suno 조합으로 60분 만에 1~2분 K-판타지 뮤직비디오 제작 가능. 일관성의 핵심은 시트 3종(캐릭터/컬러/스토리보드).**

## 2단계 파이프라인 (영상 챕터 매핑)

### Stage 1 — 스토리보드 (GPT 5.5 image-2)
| # | 단계 | 영상 챕터 | 산출물 | 도구 |
|---|------|-----------|--------|------|
| 1 | 스토리 기획 | 03:19 | story.md (한 줄 컨셉 → 6컷 시놉시스) | GPT-5.5 (텍스트) |
| 2 | **캐릭터 시트 작성** | 03:33 | 마스터 시트 2장 (서하린 + 해치) | GPT-5.5 image-2 (3:4) |
| 3 | 컬러 팔레트 락 | (시트 내포) | 4색 HEX 표 | (시트 내) |
| 4 | 신별 프롬프트 | 05:05 | scenes.json (컷별 카메라/액션/SFX/음악) | GPT-5.5 (텍스트) |
| 5 | **스토리보드 시트 작성** | 05:05 | 스토리보드 시트 6컷×N장 | GPT-5.5 image-2 |

### Stage 2 — 영상 생성 (Seedance 2.0 + Suno)
| # | 단계 | 영상 챕터 | 산출물 | 도구 |
|---|------|-----------|--------|------|
| 6 | 비디오 프롬프트 작성 | 07:13 | seedance_prompts.json (컷별) | GPT-5.5 보조 |
| 7 | 컷별 영상 생성 | 07:13 | cut_01.mp4 ~ cut_NN.mp4 (2.5~15초) | **Seedance 2.0** |
| 8 | 음악 생성 | (기승전결) | bgm.mp3 (전체 길이) | **Suno** |
| 9 | 편집 합성 | 07:53 | output.mp4 | ffmpeg / Premiere |

---

## 일관성 99% 룰 — Sheet Key 2가지

### Key 1 — HEX 락
- 모든 색상 6자리 HEX (`#5B9FD5`)
- "파란색", "sky blue" 같은 어휘 금지
- 캐릭터 4색 + 캐릭터 4색 = 6~8색 마스터 팔레트 고정

### Key 2 — 미시 디테일
- "롱헤어" 금지 → "체스트 길이 웨이브 + 코랄 레드 리본"
- 길이 / 소재 / 위치 / 텍스처 명시
- 소품도 형태/색/크기 모두 명시

> **이 두 가지만 적용하면 캐릭터 일관성 99% 해결.**

---

## 시트 3종 표준

| 시트 | 역할 | 빈도 | 템플릿 |
|------|------|------|--------|
| 캐릭터 시트 | 생김새/의상/소품/색 1장 고정 | 캐릭터당 1장 | [[aastra-character-sheet-template]] |
| 컬러 팔레트 | HEX 4색 + 톤 콘셉트 | 캐릭터당 1세트 | [[aastra-color-palette]] |
| 스토리보드 시트 | 시간×카메라×SFX×음악 7컬럼 표 | 씬당 1장 | [[aastra-storyboard-sheet-template]] |

---

## 2 frames/sec 룰 (스토리보드 핵심)

- 1초당 시작 프레임 + 끝 프레임 2장 명시
- 컷 길이 1.5~2.5초 권장
- "15초 통컷 prompt" 절대 금지
- Seedance는 시작/끝 프레임 사이 보간만 담당

## 수미상관 + 감정 피크
- **수미상관**: 오프닝 컷 = 클로징 컷 거울 (예: 경복궁 → 판타지 → 경복궁)
- **감정 피크**: 영상 길이의 87% 지점에 클라이맥스 (2분 영상 → 1분 45초)
- 음악도 동일 구조

## 오디오 맵핑
- 가야금/해금/대금/첼로/오케스트라 — 컷별 악기 사전 배치
- 모르면 GPT-5.5와 협의

---

## 도구 스택

| 단계 | 도구 | 비용 / 비고 |
|------|------|-------------|
| 스토리/시트/스토리보드 | ChatGPT (GPT 5.5 image-2) | 유료 (Plus $20/월) |
| 영상 생성 | Seedance 2.0 | fal.ai $0.40/초 (15초 = $6) |
| 음악 | Suno | $10/월 무제한 |
| 편집 | ffmpeg / Premiere | 자체 |
| 보조 협업 | Claude Opus / Gemini | 스토리/프롬프트 발전 |

> **2분 영상 비용 추정**: 시트 5장 × $0.02 + 영상 12컷 × 2.5초 × $0.40 = $0.10 + $12 = **약 $12** (음악·편집 별도)

---

## 한 줄 컨셉 → 영상 6단계 절차

```
1. 한 줄 컨셉 작성 → "한복 입은 여대생이 경복궁에서 해치와 판타지로"
2. GPT-5.5와 대화 → 6~12컷 시놉시스 + 캐릭터 디테일 발전
3. CHARACTER MASTER SHEET PROMPT 입력 → 마스터 시트 2장 생성
   ├─ HEX 4색 명시 ✅
   ├─ 미시 디테일 (체스트 길이 웨이브 등) ✅
   └─ 표정 6 + 의상 4 + 포즈 5 + 소품 3 한 장에 ✅
4. STORYBOARD SHEET PROMPT 입력 → 씬별 스토리보드 시트
   ├─ 7컬럼 표 (#/시간/비주얼/카메라/신/SFX/음악) ✅
   ├─ 2 frames/sec 룰 ✅
   └─ 수미상관 + 87% 클라이맥스 ✅
5. SEEDANCE VIDEO PROMPT (컷별) → 2.5~15초 클립 N개
6. Suno BGM + ffmpeg 편집 → 최종 영상
```

## 우리 프로젝트 적용 (현재 PRD v2.1과 매핑)

| PRD 모듈 | 본 워크플로우 단계 | 비고 |
|----------|-------------------|------|
| `00_character_sheet.py` | 단계 3 (캐릭터 시트) | 9블록 시트 1장 표준 적용 |
| `01_storyboard_sheet.py` | 단계 4 (스토리보드 시트) | 7컬럼 표 표준 적용 |
| `02_keyframes.py` | 단계 5 (시작/끝 프레임 추출) | 2 frames/sec 룰 |
| `02b_videogen.py` (fal Seedance) | 단계 5 (Seedance 2.0) | 컷별 2.5초 단위 |
| `02c_videogen_veo.py` | 단계 5 폴백 | Veo 3.1 (Flow GUI 자동화) |
| `06_compose.py` | 단계 6 (편집 합성) | ffmpeg + BGM |

---

## 관련 페이지

- [[aastra-character-sheet-template]] — 9블록 표준
- [[aastra-color-palette]] — HEX 락 룰
- [[aastra-storyboard-sheet-template]] — 7컬럼 표 + 2fps
- [[aastra-master-prompts]] — Copy & Paste 프롬프트 5종
- [[video-production-moc]] — 프로젝트 인덱스

## Beat-to-Shot 계산기 (v2 신설 — Save the Cat 12% Rule)

영상 길이 입력 → 컷 수 + 클라이맥스 시점 자동 계산:

| 영상 길이 | 컷 수 (2.5s 기준) | 87% 클라이맥스 진입 | 75% All is Lost | 50% Midpoint |
|-----------|--------------------|---------------------|------------------|---------------|
| 30초 | 12컷 | 26초 | 22.5초 | 15초 |
| 1분 | 24컷 | 52초 | 45초 | 30초 |
| 2분 | 48컷 | 1분 45초 | 1분 30초 | 1분 |
| 3분 | 72컷 | 2분 37초 | 2분 15초 | 1분 30초 |
| 5분 | 120컷 | 4분 21초 | 3분 45초 | 2분 30초 |
| 10분 | 240컷 | 8분 42초 | 7분 30초 | 5분 |

> 출처: [Fawkes 12% Rule (2023)](https://www.septembercfawkes.com/2023/07/the-12-rule-of-story-structure-SCF.html) + [Reedsy Save the Cat](https://reedsy.com/blog/guide/story-structure/save-the-cat-beat-sheet/)

## 변경 이력
| 날짜 | 버전 | 변경 |
|------|------|------|
| 2026-04-28 | v2 | 시트 3종 + 마스터 프롬프트 5종 분리 추출. PITFALL-079 재발 방지 적용. |
| 2026-04-28 | v2.1 | **상위 레퍼런스 30개 출처 발굴** ([[aastra-upstream-references]]). 보강 5건: Character Size Chart (10블록), TC IN/OUT (9컬럼), Color Script (Pixar), Animatic 매핑, Beat-to-Shot 계산기. **용어 정정**: "2fps" → "animating on twos (12fps)" — Tezuka 1963 표준. **모델명 정정**: GPT-5.5 image-2 → gpt-image-2 (OpenAI 공식). 대표님 지적: "기존 영상분도 누군가의 자료를 보고 작성한 것" 반영. |
