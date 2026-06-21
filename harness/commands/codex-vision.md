---
description: "Codex CLI Vision — 이미지/스크린샷을 GPT-5.5에 넣어 cross-family 검증 (Gemini 대체)"
---

# /codex-vision — Codex CLI Vision (cross-family 2차 검증)

Opus(Anthropic) Vision의 1차 분석을 **codex-cli + GPT-5.5(OpenAI) Vision**으로 2차 cross-check.

## 왜 필요한가

- 우리 기본 Vision = Opus 4.8 (Anthropic) → 같은 모델이 같은 사각지대 가짐
- Gemini는 무료 3개월 키 만료 + 6월 18일 Gemini CLI 폐기 → 장기 의존 안 함
- **Codex CLI**가 `-i, --image` 옵션으로 vision input 네이티브 지원 (codex-cli 0.131.0 검증됨)
- GPT-5.5 1M context = long doc + 이미지 동시 분석 가능
- 비용 0 (Codex 6계정 로테이션 활용)

## 사용법

```
/codex-vision <image_path> "<분석 질문>"
```

예시:
```
/codex-vision /tmp/screenshot.png "이 UI에서 클릭 가능한 모든 버튼의 좌표 추출"
/codex-vision dist/index.html.png "Stitch 디자인과 라이브의 차이 N개 찾기"
```

## 실행 절차

### 1. 이미지 검증
- 파일 존재 확인 (`Read(image_path)` 통과)
- 1차로 Opus가 직접 Read → 1차 분석 (기존 정책)

### 2. Codex Vision 2차 호출

```bash
codex exec -i "<image_path>" "$(cat <<'EOF'
# Role: Cross-family Vision Reviewer

당신은 Anthropic Claude(Opus)가 이미 1차 분석한 이미지를 OpenAI GPT-5.5 관점에서 재검증합니다.

## 평가 기준

1. **Opus가 놓쳤을 가능성 높은 항목**:
   - 색상 미세 차이 (1px hex code 변화)
   - 텍스트 OCR 오인 (특히 한글, 숫자)
   - 작은 UI 요소 (3px 미만 padding, border)
   - 그라데이션/그림자 detail
   - 비대칭/정렬 미세 오차

2. **공통 sanity check**:
   - 텍스트 내용 정확 추출
   - 레이아웃 구조
   - 색상 토큰 (hex, rgb)
   - 인터랙티브 요소 위치

## 출력 형식

```
## 1차 (Opus 가정) 검증
- 정확한 부분: [...]
- 불확실/누락 가능: [...]

## 2차 (Codex Vision) 추가 발견
- [발견 1]
- [발견 2]

## Cross-family 판정
- 일치: N개 / 불일치: N개
- 종합 결론
```

## 분석 질문

$2

위 이미지에 대해 분석하세요.
EOF
)"
```

### 3. Opus와 Codex Vision 결과 비교
- 일치 항목 = 신뢰도 높음
- 불일치 항목 = 추가 검증 필요 (3차 패스 또는 사용자 확인)

## 적용 케이스

| 작업 | Opus 1차 | codex-vision 2차 |
|------|----------|------------------|
| `/design-review` Stitch ↔ 라이브 비교 | pixel diff 1차 발견 | 미세 차이 cross-check |
| `/qa` UI 버그 스크린샷 | 1차 진단 | 누락 요소 확인 |
| Computer Use 클릭 좌표 | 1차 좌표 추정 | 좌표 재확인 (Anthropic vs OpenAI) |
| 블로그 이미지-제품 매칭 | 1차 매칭 | 다른 family 판단 (편향 회피) |
| 긴 PDF/문서 분석 | Opus 1M context | GPT-5.5 1M context cross-check |

## 비용

- 비용 0 (Codex CLI 6계정 로테이션 활용)
- 추가 결제 없음

## 영상 패턴과의 차이

- 영상 (AI 치트키 2026-05-18): Gemini Vision 사용
- 우리 환경: **Gemini 대체로 codex-vision 사용** (무료 3개월 키 만료 대비 + 환경 단순화)
- 단점: family 1개 감소 (3 → 2). 보강책: gemma4 보조 + Opus 최종 판정 유지

## 영상 출처

- [영상 (AI 치트키 2026-05-18)](https://www.youtube.com/watch?v=iNCOuMCzzDg): Gemini가 vision + long doc + 3rd party review 담당
- 우리 환경 검증: `codex exec --help` → `-i, --image <FILE>...` 네이티브 지원 (codex-cli 0.131.0)
- GPT-5.5 modality: Text + Vision (OpenAI 공식)
