---
slug: pitfall-149-skipped-stitch-step0-design
title: Step 0 디자인(Stitch+DESIGN.md+drift-guard) 건너뛰고 코딩 직진
date: 2026-05-12
severity: high
tags: [build-transition, stitch, design-first, p-020-recurrence]
---

# 증상

새 React 프로젝트(RebootJob MVP) PRD 작성 후 Plan → 곧장 Sonnet 서브에이전트에 코드 위임. Step 0 (디자인 단계: Stitch MCP 호출 → DESIGN.md 산출 → drift-guard init) 완전히 생략. 대표님이 "디자인 스티치 안 썼어? jamesclew 규칙을 따라야지"라고 지적할 때까지 인지 못함.

P-020(UI 디자인 선행 필수, memory `feedback_design_first.md`)의 재발.

# 원인

1. **마감 압박** (D-2)이 워크플로우 단축 유혹. "Plan에 디자인 토큰 다 정의했으니 충분하다"고 합리화
2. **OpportuMap 프로젝트 CLAUDE.md의 11단계 파이프라인**에 Step 0(Stitch) 명시되어 있는데 무시. RebootJob은 그 하위 디렉토리에 있으므로 동일 규칙 적용 의무 인지 실패
3. **글로벌 `feedback_design_first.md` 메모리를 로드해놓고도 행동에 반영 안 함** — 메모리는 읽기뿐 아니라 행동 트리거여야 함
4. Stitch MCP는 온디맨드 추가가 필요해 보였으나, 실제로는 deferred tool로 이미 사용 가능했음 (ToolSearch 로드만 하면 됨)

# 해결

새 프로젝트 시작 시 강제 체크리스트:
1. PRD 작성 직후, plan 진입 전: ToolSearch로 `mcp__stitch__*` 로드
2. Stitch MCP로 핵심 화면 생성 → 응답 이미지를 DESIGN_REFS/에 저장
3. DESIGN.md 작성 (생성된 디자인의 토큰·레이아웃·인터랙션 명시)
4. `npx drift-guard init --from design.html` (UI 프로젝트 한정)
5. **이후에만 Plan + 코드 진행**

위반 자동 감지: `enforce-build-transition.sh`에 Step 0 마커 (`/tmp/build-XXX/design_done`) 체크 추가. 없으면 `plan_done` 작성 차단.

# 재발 방지

- **PreToolUse hook(stitch-drift-guard.sh)이 Stitch 호출을 유도**하나, 호출 자체를 강제하지는 않음 → enforce-build-transition.sh에 design_done 단계 추가하여 강제화
- 글로벌 memory `feedback_design_first.md`를 SessionStart hook에서 신규 React 프로젝트 감지 시 시스템 메시지로 재주입
- 본 pitfall을 gbrain import하여 다음 세션에서 자동 검색·경고

# 회복 조치 (RebootJob)

마감 D-2 상태이지만 가능한 보완:
1. **즉시**: Stitch MCP로 디자인 양식 생성 → 현재 구현과 비교 → DESIGN.md 작성
2. **갭 분석**: 현재 라이브(https://rebootjob.web.app)와 Stitch 결과의 디자인 토큰·레이아웃 차이 확인
3. **선택적 보완**: 차이가 크지 않으면 PITFALL 기록만, 크면 핵심 화면 1~2개 재디자인 후 재배포
4. **발표심사(07.21) 전**: 풀 디자인 재작업 (Stitch 선행)

# 관련

- 글로벌 memory: `feedback_design_first.md` (P-020)
- CLAUDE.md (OpportuMap 프로젝트): Step 0 디자인 파이프라인 명시
- `~/.claude/hooks/stitch-drift-guard.sh`: Stitch 호출 후 drift-guard 유도 hook (호출 강제는 안 함)
