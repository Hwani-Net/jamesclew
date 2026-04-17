# P-044: Claude Desktop 앱에서 Agent Teams pane UI 없음 — mailbox wake 실패

> type: pitfall | id: P-044 | date: 2026-04-18 | tags: pitfall, agent-team, claude-desktop, wake

## [P-044] Claude Desktop 환경에서 Agent Teams teammate wake 실패 (pane UI 불가)
- **발견**: 2026-04-18 (v8 kanban-pwa 실측 중 dev 20분+ 무반응)
- **증상**:
  - TeamCreate + Agent() spawn 성공, inbox 메시지 도달 확인
  - 하지만 teammate가 실제 turn 실행 안 함 (파일 수정 0건)
  - 대표님 기억: "원래 Shift+Down으로 teammate pane 전환, 실시간 터미널 화면 보임" — 현재 세션에는 그런 UI 없음
- **원인**:
  - 환경변수: `CLAUDE_CODE_ENTRYPOINT=claude-desktop`
  - Claude Desktop 앱은 단일 대화창 UI — **Agent Teams pane 렌더링 미지원**
  - in-process mode의 teammate 시각화는 **터미널 Claude Code CLI**에서만 동작
  - Desktop에서는 spawn은 되지만 **백그라운드 mailbox runtime만 작동** → wake 신뢰도 낮음
- **해결**:
  - 영상 수준 Agent Teams 실측은 **터미널 CLI** (`claude` 명령)에서 실행
  - Desktop 유지 시 **Agent Teams 대신 서브에이전트 직렬 호출** (Agent tool을 director가 순차 호출)
  - 또는 Desktop 모드에서는 **Ralph Loop + 단일 director**가 더 안정
- **재발 방지**:
  - /agent-team 스킬 실행 전 `echo $CLAUDE_CODE_ENTRYPOINT` 확인
  - `claude-desktop`이면 경고 + 직렬 모드 제안
  - CLAUDE.md Agent Teams 섹션에 "Desktop 앱 제약" 추가
