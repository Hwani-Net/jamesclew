# PITFALLS 인덱스

> Reference | 대상: JamesClaw 하네스 운영자 | 최종 업데이트: 2026-04-18

---

## 1. PITFALLS란

PITFALLS는 하네스 운영 중 발생한 실수·교훈을 누적한 지식 로그입니다. 같은 실수가 반복되지 않도록 증상·원인·해결·재발방지를 기록하고, gbrain에 import하여 다음 세션에서 검색 가능하게 유지합니다.

파일 형식: `pitfall-NNN-{slug}.md` (NNN은 3자리 시퀀스 번호)

저장 위치: `D:/jamesclew/harness/pitfalls/`

gbrain 검색: `gbrain query "증상키워드"` → pitfall-NNN-* 슬러그로 자동 매칭

---

## 2. 현황

- 총 파일 수: 50개
- 시퀀스 범위: P-001 ~ P-055
- 결번: P-014, P-015, P-045, P-046, P-047 (5개)

결번은 중복 발견으로 미작성되거나 P-018로 통합된 항목입니다.

---

## 3. 기록 절차

새로운 실수·교훈 발생 시 반드시 다음 순서를 따릅니다.

```bash
# 1. 유사 항목 먼저 확인 (중복 기록 방지)
gbrain query "증상키워드"

# 2. 신규이면 파일 작성
# D:/jamesclew/harness/pitfalls/pitfall-NNN-{slug}.md

# 3. gbrain import (파일 방식만 사용)
gbrain import D:/jamesclew/harness/pitfalls/
```

**필수 작성 항목** (4개 모두 포함해야 합니다):

| 항목 | 내용 |
|------|------|
| 증상 | 언제, 어디서, 무슨 에러/동작이 나타났는가 |
| 원인 | 왜 발생했는가 (근본 원인) |
| 해결 | 어떻게 해결했는가 (재현 가능한 명령 포함) |
| 재발방지 | 다음에 같은 상황에서 무엇을 먼저 확인해야 하는가 |

**주의**: `gbrain put --content` 방식은 multi-line 내용이 깨집니다. 반드시 파일로 작성 후 `gbrain import` 방식을 사용하십시오.

---

## 4. 최근 10개 목록

| P-번호 | 슬러그 | 핵심 주제 |
|--------|--------|---------|
| P-055 | sonnet-vision-accuracy-gap | Sonnet Vision 정확도 Opus 대비 20~30% 낮음 |
| P-054 | stitch-design-to-code-gap | Stitch 디자인과 실제 코드 구현 간 괴리 |
| P-053 | nextjs-static-export-out-html-stale | Next.js 정적 빌드 후 out/ HTML 캐시 오래됨 |
| P-052 | firebase-static-export-next-static-missing | Firebase + Next.js _next/static 경로 누락 |
| P-051 | prisma-v7-breaking-changes-windows | Prisma v7 Windows 환경 breaking changes |
| P-050 | gbrain-npm-fake-package-cmd-broken | gbrain npm 가짜 패키지로 cmd 실행 실패 |
| P-049 | zombie-teams-block-teamcreate | 좀비 Agent Teams가 TeamCreate 차단 |
| P-048 | agent-teams-tools-unavailable-in-subagents | Agent Teams 내 서브에이전트에서 도구 미상속 |
| P-044 | agent-teams-desktop-no-pane | Agent Teams 데스크톱 모드에서 UI 패널 없음 |
| P-043 | agent-team-reviewer-qa-send-on-pass | Agent Teams 리뷰어가 PASS 시에도 QA 전송 |

---

## 5. 테마별 분류

### Claude Code 기능/버전 관련
- P-009: 5H/7D 사용량 수치가 오래된 캐시를 반환 (stale)
- P-026: `--dangerously-skip-permissions`도 harness hook은 우회 불가
- P-039: bypassPermissions 설정이 특정 hook을 우회하지 못함

### 하네스 훅 충돌/오동작
- P-005: enforce-execution.sh가 정상 명령을 잘못 차단
- P-011: 교차 검수 훅이 Sonnet 자기 검수와 충돌
- P-020: Ghost Mode 훅이 필요한 확인 메시지를 차단

### 외부 도구/MCP 한계
- P-025: copilot-api에 128개 도구(korean-law) 전달 시 400 에러
- P-032: Perplexity API 50회 제한 초과 시 자동 폴백 없음
- P-033: Tavily MCP 결과가 평균 11KB로 컨텍스트 과소비
- P-040: gbrain PGLite WASM Windows 환경에서 aborted

### Agent Teams 운영
- P-042: Agent Teams를 너무 작은 작업에 투입하여 오버헤드 발생
- P-048: 서브에이전트에서 동적 추가 MCP 도구 미상속 (v2.1.101+에서 해결)
- P-049: 이전 세션의 좀비 Teams가 신규 TeamCreate를 차단

### UI/배포
- P-001: `loading="lazy"` 사용으로 이미지 헤드리스 환경에서 미로드
- P-021: TUI Fullscreen과 VS Code 통합 터미널 충돌
- P-052: Firebase 배포 후 Next.js `_next/static` 경로 404

---

## 6. 상세 조회

각 pitfall 파일을 직접 Read하거나 gbrain에서 검색합니다.

```bash
# gbrain 검색 (권장)
gbrain query "agent teams 좀비"

# 파일 직접 읽기
# Read("D:/jamesclew/harness/pitfalls/pitfall-049-zombie-teams-block-teamcreate.md")
```

새 버전의 Claude Code가 특정 pitfall을 해결한 경우, 해당 파일에 `해결됨: vX.X.XXX` 주석을 추가하고 gbrain을 재import합니다.
