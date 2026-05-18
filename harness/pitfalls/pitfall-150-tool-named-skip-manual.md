---
slug: pitfall-150-tool-named-skip-manual
title: 사용자가 도구 명시 시 매뉴얼·doctor 우선 조회 안 함
date: 2026-05-12
severity: high
tags: [search-before-solve, manual-first, troubleshooting, p-020-related]
---

# 증상

대표님이 "Stitch가 그냥 MCP일 텐데 왜 gpt-korea를 찾고 있어?", "기존 도구가 왜 안 되는지" 물었을 때, 매뉴얼/README/doctor 명령 우선 조회 없이 직접 디버깅(gcloud config set, ADC quota 변경, npm 다운그레이드)으로 30분+ 낭비.

매뉴얼(stitch-mcp README) 끝까지 읽은 결과:
- `doctor` 명령으로 즉시 진단 가능 — 실제 active config는 stayicon@gmail.com / planning-with-ai-4d1f7
- `STITCH_USE_SYSTEM_GCLOUD=1` env var로 시스템 gcloud 사용 가능
- 격리된 stitch-mcp 자체 SDK가 `C:\Users\AIcreator\.stitch-mcp\` 에 존재
- 시스템 gcloud 변경은 stitch-mcp에 아무 영향도 못 줌

이 모든 게 README 1회 통독으로 알 수 있었음.

# 원인

CLAUDE.md "Search-Before-Solve"는 gbrain query 우선 명시. 그러나 **"사용자가 특정 도구를 명시하며 동작 안 한다고 물을 때 → 그 도구의 매뉴얼/README/doctor 명령을 가장 먼저 조회"** 라는 명시적 규칙 부재.

대표님 시그널 누적:
1. "디자인 스티치 안 썼어? jamesclew 규칙을 따라야지" — P-149
2. "전에 잘 사용하던 게 왜 api키가 없다고 해?" — 매뉴얼 안 본 시그널
3. "스티치가 그냥 mcp일 텐데 왜 gpt-korea를 찾고 있어?" — 잘못된 디버깅 방향 지적
4. "기존 도구 왜 동작 안 하느냐 등으로 도구를 명시하면 바로 매뉴얼부터 보고 고쳐야 했을 거 아니야"

→ 매뉴얼 우선 조회를 룰로 박지 않으면 반복.

# 해결

CLAUDE.md `rules/quality.md` 또는 `rules/architecture.md`의 Search-Before-Solve 섹션에 다음 추가:

> **도구 명시 시 매뉴얼 우선 조회 (Tool-Named-Manual-First)**
>
> 사용자가 특정 도구 이름을 명시하며 "왜 안 되는지" 묻거나, 도구가 예상과 다르게 동작할 때:
> 1. 가장 먼저 해당 도구의 매뉴얼·README·`--help` 출력 통독 (`cat $(npm root -g)/<pkg>/README.md` 등)
> 2. 도구가 `doctor` `status` `health` `info` 같은 진단 명령을 제공하면 우선 실행
> 3. **그 후에만** 트러블슈팅 코드 조사·환경변수 추측·재설치 시도
>
> 매뉴얼 1회 통독으로 해결되는 문제를 코드 디버깅으로 우회하지 말 것.

또한 SessionStart hook에서 도구 이름 감지 시 매뉴얼 위치 자동 안내(`telegram-notify.sh` 또는 stdout):
- npm 글로벌 패키지: `cat $(npm root -g)/<pkg>/README.md`
- MCP 서버: `claude mcp list` + 패키지 README
- CLI 도구: `<tool> --help` + `<tool> doctor` (있다면)

# 재발 방지

- enforce-tool-manual-first.sh hook 후보 (UserPromptSubmit 단계에서 "왜 안 돼/동작 안 해" + 도구 이름 패턴 감지 시 매뉴얼 조회 강제)
- gbrain `query "tool-manual-first"` 슬러그로 검색 시 본 pitfall 노출
- 본 pitfall을 P-149 (Stitch Step 0 건너뜀)와 cross-link — 디자인 도구 사용 시 매뉴얼·step 0 둘 다 점검

# 관련

- P-020 (UI 디자인 선행 필수)
- P-149 (Stitch Step 0 건너뜀)
- CLAUDE.md Search-Before-Solve (gbrain query 우선)
- `~/.claude/rules/quality.md`
