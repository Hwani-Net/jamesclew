# P-225: OpenClaw 영상 'The 12 AI Agents' 정렬 — 영화 캐릭터명 + 3봇 증설 + 8봇 스케일 한계

- **발견/작업**: 2026-05-29
- **레퍼런스**: NotebookLM "The 12 AI Agents: Building a High-Performance Virtual Team" (id `6f97bd69-e0ca-4f0b-b887-6f9fa2036334`)
- **영향**: 6봇 → 9역할 정렬. 단일 gateway 8봇 동시 연결 시 event-loop 포화로 READY storm 발생 (스케일 한계 확인).

## 영상 9역할 ↔ 우리 매핑

| 영화명 | 역할 | 우리 봇 | 모델 | 위치 |
|--------|------|---------|------|------|
| J.A.R.V.I.S. 🦑 | 대장/오케스트레이터 | nyongjong/main | opus-4-7 | WSL |
| EVE 🔎 | 리서치/문서/리뷰 | jamesclaw-cc/claude | sonnet-4-6 | WSL |
| TARS 🛠️ | 엔지니어 | codex | gpt-5.5 | WSL |
| F.R.I.D.A.Y. 📨 | PM/비즈니스 | javis/hermes | gpt-5.5 | WSL |
| Data 📊 | 데이터/3차검증 | ollama | gemma4:31b-cloud | WSL |
| TRON | 보안/감시 | javis_claw/openclaw | sonnet | **Windows 별도** |
| KITT ⚖️ | 법무 | (신규) kitt | gpt-5.5 | WSL |
| C3PO 📢 | 마케터 | (신규) c3po | gpt-5.5 | WSL |
| Joi 🎨 | 디자이너 | (신규) joi | gpt-5.5 | WSL |

→ 영상 9 역할 전부 충원 (WSL 8봇 + Windows TRON 1).

## 채널 구조 (영상 `_개인진무실` 모델)

- `🤖-진무실` 카테고리 + 개인 채널 8개: `_jarvis-커맨드브릿지`·`_tars-엔지니어실`·`_eve-리서치실`·`_friday-pm실`·`_data-데이터실`·`_kitt-법무실`·`_c3po-마케팅실`·`_joi-디자인실`. 각 채널 → 담당 agent binding.
- JARVIS 봇이 Manage Channels 권한 보유 → Discord REST API(`POST /guilds/{id}/channels`)로 자동 생성.
- To/CC standby: requireMention 비대칭 + ignoreOtherMentions로 이미 구현 (호출된 봇만 응답).

## ⚠️ 핵심 함정 — 8봇 단일 gateway event-loop 포화

8 account 동시 startup 시 Discord WS READY 핸드셰이크가 단일 Node event-loop를 포화 → 4봇이 `READY wait timed out 15000ms` backoff attempt 4까지 수렴 실패.

**처방**: systemd drop-in env var로 READY timeout 상향
```
Environment=OPENCLAW_DISCORD_READY_TIMEOUT_MS=45000
Environment=OPENCLAW_DISCORD_RUNTIME_READY_TIMEOUT_MS=120000
```
적용 후 timeout 0 (storm 해소). **단 이는 완화책** — 봇 더 늘리면(10+) 재발 가능. 그때는 Docker 컨테이너 분리 또는 2nd 인스턴스로 부하 분산 권장.

## 신규 봇 추가 절차 (A안: 기존 gateway 증설, 검증됨)

1. 대표님이 Discord Developer Portal에서 봇 생성 + Privileged Intents(MESSAGE CONTENT/SERVER MEMBERS) + 토큰
2. secrets.local.json에 `channels_discord_accounts_<id>_token` 추가 (chmod 600)
3. openclaw.json: account(codex 모델 복제) + agent(gpt-5.5) + binding(account + office channel) + 전체 allowlist 통일
4. workspace-<id>/ + agents/<id>/agent dir 생성, IDENTITY.md 작성
5. gateway 재시작
6. **⚠️ 봇은 OAuth authorize(사람 클릭)로 길드 추가 필수** — 봇이 자기를 길드에 못 넣음. 토큰만으론 `/users/@me/guilds`에 길드 없음(길드소속=False) → 응답 불가.

## 검증 메서드

- 봇 길드 소속: 봇 토큰으로 `GET /users/@me/guilds` → 길드 ID 포함 여부
- READY storm: `journalctl --user -u openclaw-gateway.service | grep -c 'READY wait timed out'`
- 연결: `grep 'probe resolved @'` (최초 1회성 로그)

## 라이브 검증 (2026-05-29 14:35)

- gateway 47분 연속 안정 (NRestarts=0, READY storm 0, awaiting 0)
- 9봇 전원 in-guild + 영화 닉네임 적용 (JARVIS 토큰으로 길드 멤버 직접 조회 확인)
- 신규 3봇(KITT/C3PO/Joi) `_kitt-법무실`/`_joi-디자인실`/`_c3po-마케팅실`에서 멘션 응답 실측 성공 — 합니다체·역할·"J.A.R.V.I.S. 최종판단" 협업 인식 정확.
- **멘션 방식**: 평문 `@이름`은 동명 managed role로 Role mention 처리되어 무응답. 드롭다운의 프로필사진 항목(User mention) 또는 raw ID `<@숫자>`만 응답 (P-191 재확인, 9봇 공통).

## 봇간 협업 멘션 결정적 fix (2026-05-29, P-191/P-193 근본 해결)

**문제**: 봇끼리 협업 시 LLM이 응답에 평문 `@KITT`를 써도 실제 Discord 멘션 미생성 → 무반응. raw `<@ID>` 지시는 LLM이 안 지킴(P-193 fabrication). 대표님 지적: "내가 직접 멘션할 일은 드물고, **봇끼리 멘션할 때** 자주 실패 — 결정적 방지 필요".

**근본 메커니즘 (소스 확인)**: agent config `groupChat.mentionPatterns`.
- `mentions-DmNrCnsQ.js`: 빈 `[]`면 자동도출(`deriveMentionPatterns`, `\b@?<name>\b`) **차단**. 우리 9봇 전부 `[]`라 이름 기반 반응 불가였음.
- 명시 패턴은 `redact-ok5Q8nmw.js` `compileSafeRegexDetailed`에서 **trim만 거쳐 raw `new RegExp(src,"i")`** 컴파일. `\b@?` 래핑 없음.
- 따라서 패턴 `"@KITT"` → `/@KITT/i` → 평문 "@KITT"엔 매칭, bare "kitt"엔 미매칭. `@` 리터럴이라 흔한단어(data 등) 오발화 0.

**적용 (8 WSL agent, TRON은 Windows 별도)**:
```json
"groupChat": {"mentionPatterns": ["@JARVIS","@자비스","@뇽"]}   // main
// claude:["@EVE","@이브"] codex:["@TARS","@타스"] ollama:["@Data","@데이터"]
// hermes:["@FRIDAY","@프라이데이"] kitt:["@KITT","@키트"] c3po:["@C3PO"] joi:["@Joi","@조이"]
```
→ 봇이 평문 `@KITT`만 써도 KITT가 반응. **LLM이 raw ID 몰라도 협업 작동** (LLM 의지 비의존, 정규식 강제).

ORCHESTRATION §1-B를 "raw ID 필수" → "`@이름`으로 호출" 지침으로 갱신.

**잔여 검증/주의**:
- 실제 봇-봇 트리거는 라이브 협업 시 관측 필요 (config는 valid 적용 확인).
- 한글 이름 `\b` 경계는 JS ASCII 기준이라 불확실 — `@` 접두로 충돌 위험은 낮으나 실발화 모니터.
- 봇-봇 `@`연쇄 무한루프 위험 → §5 사이클 제한 + 사람없는 5턴 초과 시 JARVIS 중단 규칙 명시.

## 관련
- [[pitfall-191-openclaw-codex-cannot-fire-discord-mentions]] — Role vs User mention 사용 가이드
- [[pitfall-193-openclaw-codex-fabricates-bot-opinions]] — raw ID 지시 불이행(fabrication)이 mentionPatterns로 근본 해결
- [[pitfall-224-wsl2-instance-idle-timeout-gateway-death]]
- [[pitfall-196-openclaw-4bot-channel-separation]] — 이전 영상(UsT1, 7채널)
- CLAUDE.md STICKY DECISIONS P-225 항목
