---
title: rules/ 파일별 레퍼런스
type: reference
diátaxis: Reference
source: D:/jamesclew/harness/rules/
---

# rules/ 레퍼런스

소스: `D:/jamesclew/harness/rules/`
배포 경로: `~/.claude/rules/`

CLAUDE.md가 에이전트의 행동 원칙을 정의한다면, rules/ 는 각 도메인의 세부 기준을 담습니다. 에이전트는 관련 작업 시 해당 파일을 참조합니다.

---

## 파일 일람

| 파일 | 주제 | 줄수 | 사용 시점 |
|------|------|------|----------|
| `architecture.md` | 멀티모델 라우팅, 도구 우선순위, 비용 추적 | 87 | 모델 선택 및 도구 호출 판단 시 |
| `design_rubric.md` | UI 디자인 4축 평가 기준 (Consistency / Originality / Polish / Functionality) | 112 | `/design-review`, `/qa` 실행 시 |
| `quality.md` | 품질 파이프라인, Multi-Pass Review, 이미지·링크 검증, PITFALLS 기록 절차 | 131 | `/pipeline-run`, 배포 전 검증 |
| `security.md` | 시크릿 보호, 파괴적 명령 차단 | 9 | 항상 적용 (hook으로 강제) |
| `stitch-design-reference.md` | Stitch MCP 참조 패턴, MotionSites Premium Hero 39개 프롬프트 | 206 | Stitch로 UI 생성 시 |

---

## architecture.md

멀티모델 환경에서 도구와 모델을 어떻게 선택하는지 기준을 정의합니다.

주요 내용:
- Tool Selection: GitHub=gh CLI, 브라우저=expect MCP 우선, 웹 콘텐츠=`curl r.jina.ai/URL`
- Tavily 기본값 강제: `search_depth="basic"`, `max_results=5`. advanced는 명시 요청 시에만.
- Perplexity 비용 비교: search($0.006) < reason($0.02) < ask($0.03) << research($0.80)
- 호스팅: Firebase 전용. 모든 웹 프로젝트 통일.
- 외부 모델 기본 매핑 표 (AI냄새→GPT-4.1, Vision→Opus, 이미지 검증→gpt-4o-mini)

---

## design_rubric.md

Evaluator가 프런트엔드 결과물을 평가할 때 사용하는 채점 기준입니다.

| 평가축 | 핵심 질문 | PASS 기준 |
|--------|----------|----------|
| Consistency | 통일된 토큰 체계를 따르는가? | 8점+ |
| Originality | 사람이 의도를 가지고 디자인했는가? | 8점+ |
| Polish | 타이포그래피·간격·대비가 디테일하게 맞는가? | 8점+ |
| Functionality | 컴포넌트가 UX에 기여하는가? | 8점+ |

AI 클리셰 블랙리스트(보라+핑크 그라데이션, blur circle, 3-column feature grid 등) 발견 시 -3점.

---

## quality.md

6단계 콘텐츠 검토 패스와 5단계 코드 검토 패스를 정의합니다.

콘텐츠 Multi-Pass Review:
1. 구조 (H2/H3, 흐름, 길이)
2. SEO (키워드 밀도, 메타 디스크립션, FAQ)
3. 독자 관점 (AI냄새 제거)
4. 사실 검증 (가격, 스펙, 링크)
5. 이미지/미디어 (썸네일, alt 태그)
6. 경쟁 대비 (차별 포인트)

최소 2라운드 필수. 2라운드 연속 수정 0건이면 완료.

PITFALLS 기록 절차: `gbrain query` → 신규 확인 → `pitfall-NNN-{slug}.md` 작성 → `gbrain import`.

---

## security.md

- 소스 코드에 시크릿 하드코딩 금지. 환경변수 사용.
- `.env`, `credentials`, `*.pem`, `*.key` 수정 시 PreToolUse hook이 자동 차단.
- `rm -rf`, `format`, `del /s/q` → deny list.

---

## stitch-design-reference.md

Stitch MCP로 화면을 생성하기 전 반드시 참조합니다.

핵심 패턴:
- 배경: `#050508` + 세로줄 텍스처 (40px pitch)
- 타이포그래피: 80px+ bold + Instrument Serif italic 혼합
- CTA: Amber filled(`#F59E0B`) + ghost 버튼 쌍
- 절대 금지: 보라+핑크 그라데이션, blur circle

Stitch는 온디맨드 MCP입니다. 사용 전 `claude mcp add stitch -s user -- npx @_davideast/stitch-mcp proxy` 로 활성화하고, 작업 후 `claude mcp remove stitch` 로 제거하십시오 (도구 50개 한도 관리).
