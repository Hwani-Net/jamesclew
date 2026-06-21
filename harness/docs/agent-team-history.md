# /agent-team — 변경 이력 & 실측 로그 (아카이브)

> `commands/agent-team.md` 본문에서 분리한 버전 변경 요약(v5~v11) + 실측 검증 이력 + 미래 개선 후보. **운영 규칙 아님** (참조용). 현행 운영 규칙은 agent-team.md의 R1~R15 + v12 패치를 보십시오.

## v11 변경 요약 (GAP-V10-N1/N2/N3 대응)

| 규칙 | 변경 | 근거 GAP |
|---|---|---|
| **R13 현실화** | **서브에이전트에서 TaskList/TaskUpdate/SendMessage 미동작 확인 (v2.1.112)**. teammate 프롬프트에서 이 도구 호출 시도는 무의미. **director가 모든 TaskUpdate 직접 호출**하는 "director override 모드"를 기본으로 명시. | V10-N1 (P-048) |
| **R8 스캐폴드 보강** | TeamCreate 전 `ls ~/.claude/teams/` 확인 — 좀비 팀 있으면 `rm -rf ~/.claude/teams/{name}` 후 진행. | V10-N2 (P-049) |
| **R16 (폐기됨)** | ~~MCP 경로 검증 — gbrain~~ gbrain은 2026-05-19 폐기 (P-172). 이 규칙 불필요. | V10-N3 (P-050) |

## v10 변경 요약 (GAP-V9-N2/N3 대응)

| 규칙 | 변경 | 근거 GAP |
|---|---|---|
| **R15 보강** | idle 직전 "SendMessage ≥1건 + summary 본문 **비어있으면 위반**" 조항 추가. 빈 summary idle은 R15 FAIL로 분류 | V9-N3 (qa 18:33 빈 summary idle 1건, 6분 공백) |
| **R14 보강** | watchdog 트리거 확장: `task.status=in_progress AND 최근 idle notification.summary==''` → 즉시 wake SendMessage | V9-N3 자동 감지 (v9는 수동 wake만 가능) |
| **qa R3-v10** | 재검증 시 **캐시 우회 필수**: `mcp__expect__close` 후 `?t=<Date.now()>` 쿼리스트링으로 open | V9-N2 (qa가 Playwright 캐시로 구버전 판단) |

## v9 변경 요약 (v8 Kanban PWA 실측 + 공식 Agent Teams 흡수)

| 규칙 | 변경 | 근거 GAP |
|---|---|---|
| **R13 (신규)** | TaskCreate/TaskList/TaskUpdate 중앙 큐 — teammate 기상 시 TaskList 조회, 완료 시 TaskUpdate(status) 필수. SendMessage 누락돼도 큐가 트리거 역할 | V5-N3 (reviewer→qa, qa→dev SendMessage 누락 2연속 재발) |
| **R14 (신규)** | director watchdog — Ralph Loop 각 iteration 시작 시 TaskList 조회, `in_progress` 5분 초과면 owner에 wake SendMessage, 10분 초과면 Agent re-spawn | V8-N1 (Desktop dev 20분+ wake 실패) |
| **R15 (신규)** | peer DM summary 패턴 감지 — teammate idle 직전 자가점검: "X에게 재작업", "Y 진입 승인" 등 판정 문구가 team-lead 메시지에만 있고 실제 X/Y SendMessage 0이면 즉시 누락 복구 | V5-N3 조기감지 |
| **dev/reviewer/qa R0** | TaskList 조회 → 내 task `in_progress`로 owner 클레임 추가 | V5-N3 근본 해결 |

## v8 변경 요약 (GAP-V7 → Kanban PWA 완성형 품질 실측)

| 규칙 | 변경 | 근거 |
|---|---|---|
| **대상 스코프** | 토이 계산기 → 다중 화면 CRUD PWA (접근성 AA + 오프라인 + Drag API 대체 수단) | P-042 "토이 스코프 탈출" |
| **R12 강화** | focus-visible + aria-grabbed/dropzone 자동 감지 추가 | Kanban 접근성 실측 |
| **R5-v5 deploy** | 다중 HTML 파일 (index.html + board.html) 배포 검증 URL 각각 HTTP 200 확인 | 다중 화면 프로젝트 |

## v7 변경 요약 (GAP-V6-N1~N3 대응)

| 규칙 | 변경 | 근거 |
|---|---|---|
| **R0/R10-v5 Python** | `open(file, encoding='utf-8')` 명시 | V6-N1 Windows cp949 false positive |
| **qa R9** | PRD 원문 `grep` 후 UI 입력 강제 (플레이스홀더·기억 금지) | V6-N2 qa가 이전 벡터로 false PASS |
| **qa R12** | `accessibility_audit` + axe-core DOM 직접 검사 이중화 | V6-N3 audit 도구 false positive |

## v6 변경 요약 (GAP-V5-N1~N3 대응)

| 규칙 | 변경 | 근거 |
|---|---|---|
| **R0/R10-v5 Bash 경로** | `mailbox/` → `inboxes/{name}.json` + `grep -c '"from": "team-lead"'` JSON 내용 검사 | V5-N2 경로 오기 false positive |
| **R4.5 (신규)** | 판정 SendMessage(대상) + team-lead 보고는 **별개 2건** 필수. reviewer/qa 분기에 명시 | V5-N3 대상 누락 (reviewer→qa, qa→dev 영구 대기) |
| **verify-deploy.sh hook** | `~/.claude/teams/` active team 감지 시 auto-skip | V5-N1 hook이 team 세션 미인식 |

## v5 변경 요약 (GAP-V4-N1~N5 대응)

| 규칙 | 변경 | 근거 GAP |
|---|---|---|
| **dev R0 (신규)** | team-lead SendMessage 수신 증거 Bash로 확인 후에만 구현 시작 | V4-N1 (dev 자체 시작) |
| **dev R5-v5** | preview URL HTTP 200 curl 검증 **후에만** reviewer SendMessage | V4-N3 (preview 미존재로 review request) |
| **R2-v5 (3)** | `rm docs/review.md` → `Write` 전체 교체 (append 금지) | V4-N5 (review.md 부분 stale) |
| **R10-v5** | reviewer 최초 리뷰 시 **team-lead→dev 승인 메시지 존재 여부 Bash로 확인**. 없으면 P1 이슈 기록 + team-lead 피드백 | V4-N4 (승인 부재 미감지) |
| **R11 (신규)** | reviewer가 `package.json`/`tsconfig.json`/파일 구조 ↔ PRD 기술 스택 **P0 기준** 감사 (v4는 P2로 약화) | V4-N2 (dev 스택 이탈 P2 처리) |
| **R12 (신규)** | qa `mcp__expect__accessibility_audit` 자동 포함 (접근성 프로젝트 한정 아니라 기본값) | v3 color-contrast 교훈 |

---


## 실측 검증 이력

| 버전 | 날짜 | 대상 | 총 소요 | Critical 재발 | 주요 발견 |
|---|---|---|---|---|---|
| v1 | 2026-04-17 | 설계만 | - | - | 미검증 |
| v2 | 2026-04-17 | 설계만 (Sonnet-only) | - | - | 실측 전 |
| v3 | 2026-04-17 | 포켓몬 계산기 (90분) | 13 GAP | 5건 | 첫 실측, Agent Team 작동 확인 |
| v4 | 2026-04-17 | 색상 대비율 (25분) | 0건 완전 재발 | 1건 mild 자가교정 | Read 검증·Fallback·양방향 교정 |
| v5 | 2026-04-17 | 한글 분해 (~56분) | GAP-V5-N1~N3 | 3건 | hook 간섭 + SendMessage 누락 |
| v6 | 2026-04-17 | 복리 계산 (~18분) | GAP-V6-N1~N3 | 3건 | cp949 인코딩 + axe false positive |
| v7 | 2026-04-17 | 온도 변환 (~18분) | 0건 | 0건 | UTF-8·PRD grep·axe 이중화 효과 입증 |
| **v8** | 2026-04-18 | Kanban PWA (3시간) | GAP-V5-N3 2회 재발 + V8-N1 | 2건 | 토이 탈출·품질 확인. SendMessage 누락 반복 → v9 근본 해결 필요 |
| **v9** | - | (대기) | - | - | TaskCreate 중앙 큐 + watchdog + peer DM 감지 흡수 |

## v10 후보 (미래 개선)

- HydraTeams 경유 외부모델 teammate 실증 (Sonnet + 로컬 보조 혼합 팀)
- Ralph Loop 연동 시 watchdog-ralph.sh 상호작용 검증
- teammate 간 task 진행률 CLI dashboard (실시간 가시성)
- 대형 프로젝트(10+ 파일·DB·Auth) 실측
