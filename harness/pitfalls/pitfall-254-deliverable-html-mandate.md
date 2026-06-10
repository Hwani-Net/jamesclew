# PITFALL-254 — 사람 검토용 산출물을 .md로 생성 (HTML 의무 위반)

- 날짜: 2026-06-03
- 분류: 산출물 형식 / 규칙 영구화 누락
- 연결 정책: CLAUDE.md STICKY P-254

## 증상
공모 기획서 3종(KOICA·산업부·문체부)을 대표님 검토용으로 제작하면서 `.md`로 생성. 대표님 지적: "기획서·PRD 등 사람이 보고 판단하는 산출물은 HTML로 만들라고 했는데 왜 이 규칙이 적용되지 않았나?"

## 원인
"사람 검토용 산출물(기획서·PRD 등)은 HTML로 제작" 규칙이 CLAUDE.md·rules/*.md·MEMORY.md **어디에도 기록되지 않았음**(`기획서|PRD` grep → CLAUDE.md 1곳(무관), `html` grep → drift-guard 1건뿐). 과거 구두 지시였으나 STICKY DECISIONS/rules에 영구화되지 않아 세션 컨텍스트에 부재 → `.md` 기본값으로 생성. **근본 원인은 "구두 지시 미영구화"** — STICKY DECISIONS가 존재하는 바로 그 이유.

## 해결
1. 3개 기획서 `.md` → `.html` 변환: `D:/AI 비즈니스/공모해커톤/_md2html.py` (python-markdown `extensions=[tables,fenced_code,attr_list,sane_lists,nl2br]` + 인쇄 친화 CSS: A4 `@page`, Pretendard, 표·blockquote·코드블록 스타일). expect MCP로 브라우저 렌더링 검증 완료(표·다이어그램·콜아웃 정상).
2. 규칙을 CLAUDE.md STICKY DECISIONS에 **P-254**로 영구 등록(대표님 승인).

## 재발 방지
- 기획서·PRD·제안서·보고서 등 **사람이 보고 판단·결재하는 산출물 = 반드시 HTML**. `.md`는 작업·중간본 한정.
- 표준 변환기 `_md2html.py` 재사용(또는 동급 python-markdown + 인쇄 CSS).
- **구두 지시·선호는 즉시 CLAUDE.md STICKY/rules에 영구화** — 미영구화가 재발의 근본 원인. 새 세션은 CLAUDE.md를 1차 소스로 로드하므로 STICKY 등록만이 인수인계를 보장.
