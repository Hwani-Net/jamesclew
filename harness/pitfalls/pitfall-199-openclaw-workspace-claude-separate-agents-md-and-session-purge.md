# PITFALL-199: OpenClaw workspace-claude 별도 AGENTS.md + claude code session cache → echo/self-mention 회귀 해소

- **발견**: 2026-05-25 (P-198 적용 직후 jamesclaw-cc 응답 회귀 5차례 재현)
- **영향**: P-198(raw ID 양방향 작동 + ChannelBotLoopProtection 명시 정책 격상) 적용 완료 후에도 jamesclaw-cc(claude) 응답이 사용자 메시지 본문을 그대로 echo하고 자기 자신을 `<@jamesclaw-cc>` username form(Discord 미인식)으로 호명하는 회귀 발견. 5차례 가이드 수정 + nyongjong 측 `workspace/AGENTS.md` 강화에도 전혀 반영되지 않음. 원인은 (a) jamesclaw-cc의 cwd가 `workspace`가 아닌 **별도 디렉토리 `workspace-claude/`**여서 nyongjong용 AGENTS.md 강화가 무효, (b) `workspace-claude/AGENTS.md`의 §"Public Discord Return Loop" 가이드가 응답 마지막 라인에 nyongjong mention 강제 → 모델이 이를 echo + self-mention 패턴까지 확장 해석, (c) claude code session(`30f81fa4-...jsonl`)이 cached system prompt 재사용 → AGENTS.md 파일 수정해도 invalidate 안 됨.
- **재발 빈도**: 4회 (P-198 가이드 수정 후 11:01, 11:35, 11:45, 11:50, 12:20 동일 패턴 5차례 재현. P-194 회피 자백 후 사실 검증 전환으로 진단 성공)
- **검증 자료**:
  - Discord REST API 메시지 원본 fetch (`mcp__plugin_discord_discord__fetch_messages`)
  - claude-cli 게이트웨이 로그 (`promptChars=770 reuse=reusable`)
  - claude code project dir: `/home/creator/.claude/projects/-home-creator--openclaw-workspace-claude/`
  - `systemPromptReport.injectedWorkspaceFiles` 분석
  - workspace 측 AGENTS.md (11682 chars, nyongjong용)
  - workspace-claude 측 AGENTS.md (변경 전 1349 chars, 변경 후 4140 chars)
  - claude code session 파일 `30f81fa4-e2cc-430f-88ab-174b890b8811.jsonl`
  - 6차 라이브 검증 Discord 응답 원문 (14:10:20 KST)

---

## 증상

P-198 적용(`channels.defaults.botLoopProtection` + `channels.discord.botLoopProtection` 명시 + ORCHESTRATION.md §11-A/§12 명문화) 직후, jamesclaw-cc(claude) 라이브 응답이 다음 패턴을 5차례 재현:

1. **사용자 메시지 본문을 그대로 echo**
   - nyongjong이 jamesclaw-cc에게 전달한 내용을 응답 첫 부분에 거의 그대로 복사
   - "Claude 측 응답입니다. {원문 그대로}" 형태

2. **자기 자신을 `<@jamesclaw-cc>` username form으로 호명**
   - Discord 미인식 syntax. 정식 mention object 미생성
   - claude가 자기 ID/이름을 본문 안에 잘못 끼워 넣음

3. **마지막 라인에 nyongjong 호출 무조건 추가**
   - 응답 본문이 substantive가 아닌데도 무조건 `<@1506248517478518854>` 첨부

5차례 발생 시각 (KST):
| # | 시각 | 가이드 수정 차수 | 결과 |
|---|------|----------------|------|
| 1 | 11:01 | P-198 적용 직후 (변경 없음) | echo + self-mention 발생 |
| 2 | 11:35 | nyongjong workspace/AGENTS.md 강화 1차 | 동일 패턴 재현 |
| 3 | 11:45 | nyongjong workspace/AGENTS.md 강화 2차 | 동일 패턴 재현 |
| 4 | 11:50 | ORCHESTRATION.md §11-A 보강 | 동일 패턴 재현 |
| 5 | 12:20 | workspace/AGENTS.md §10~§12 추가 + 강화 | 동일 패턴 재현 |

→ nyongjong 측 어떤 강화도 jamesclaw-cc 응답에 반영되지 않음. P-194(외부 증거 없는 결론) 회피를 위해 가설 검증 모드로 전환.

---

## 진단 과정 (P-194 4번째 재발 자백 → 사실 검증)

처음 4차례까지 가설 검증 없이 "ORCHESTRATION.md 강화하면 다음엔 잡힐 것"이라는 추측을 반복. 5차 재현 시점에 P-194 antipattern 자백 후 검증 6단계 진행.

### 1단계 — `systemPromptReport.injectedWorkspaceFiles` 확인

게이트웨이가 jamesclaw-cc에 주입한 workspace 파일 목록과 크기를 직접 확인. ORCHESTRATION.md가 실제 주입됐는지 검증.

```bash
grep -A 20 "injectedWorkspaceFiles" /tmp/openclaw/openclaw-2026-05-25.log \
  | grep -A 1 "jamesclaw-cc" | head -40
```

출력 핵심:
```
"injectedWorkspaceFiles": [
  { "path": "AGENTS.md", "chars": 11682 }
]
```

→ ORCHESTRATION.md 부재. AGENTS.md만 11682 chars 주입됨. §10/§11/§11-A/§12 모두 무효 (workspace/AGENTS.md만 nyongjong에 영향).

### 2단계 — claude-cli 게이트웨이 로그 추적

```bash
tail -100 /tmp/openclaw/openclaw-2026-05-25.log \
  | grep -i "claude\|promptChars\|reuse"
```

출력 라인:
```
... INFO  claude-cli invoked (model=opus-4.7 promptChars=770 reuse=reusable)
```

→ promptChars=770만 전송. 11.6KB AGENTS.md를 매번 attach하지 않음. `reuse=reusable` = cached system prompt 재사용.

### 3단계 — claude code project dir 추적

claude code는 cwd 기반 hashing으로 project dir을 생성. jamesclaw-cc가 어디서 동작 중인지 확인.

```bash
ls -la /home/creator/.claude/projects/ | grep -i "openclaw\|workspace"
```

출력:
```
drwxr-xr-x  ... -home-creator--openclaw-workspace/
drwxr-xr-x  ... -home-creator--openclaw-workspace-claude/
```

→ **두 디렉토리가 분리**. jamesclaw-cc는 `workspace`가 아닌 `workspace-claude/`에서 동작.

### 4단계 — workspace-claude 디렉토리 내용 확인 (결정적 발견)

```bash
ls -la /home/creator/openclaw/workspace-claude/
```

출력:
```
-rw-r--r-- ... AGENTS.md (1349 chars)
-rw-r--r-- ... .openclaw/
```

→ **자체 AGENTS.md 별도 존재**. nyongjong workspace/AGENTS.md(11682 chars)와 완전히 다른 파일.

```bash
cat /home/creator/openclaw/workspace-claude/AGENTS.md | wc -c
# 1349
```

### 5단계 — `workspace-claude/AGENTS.md` §"Public Discord Return Loop" 발견

```bash
cat /home/creator/openclaw/workspace-claude/AGENTS.md
```

라인 28~38 핵심 발견:
```markdown
## Public Discord Return Loop

When `nyongjong claw` calls you in #작업-요청 with a delegation, respond
with your substantive answer.

Use this at the end of the response to hand control back to nyongjong:

Final line: <@1506248517478518854>
```

→ claude(jamesclaw-cc)에게 응답 마지막 라인에 nyongjong mention을 **무조건 추가하라는 강제 가이드**. 모델이 이 지시를 해석하면서:
- "Final line"을 본문 일부로 포함 → echo body 동반
- 자기 ID도 함께 표기해야 한다는 잘못된 일반화 → `<@jamesclaw-cc>` username form self-mention 추가
- 강제 마무리 라인 = substantive 여부 무관하게 항상 첨부

### 6단계 — claude code session cache 확인

```bash
ls -la /home/creator/.claude/projects/-home-creator--openclaw-workspace-claude/
```

출력:
```
-rw-r--r-- ... 30f81fa4-e2cc-430f-88ab-174b890b8811.jsonl (...)
```

→ jamesclaw-cc의 활성 session. claude code는 cached system prompt를 재사용하므로 AGENTS.md 파일을 수정해도 새 turn에서 자동 invalidate되지 않음. 새 session으로 시작해야 system prompt가 다시 빌드됨.

---

## 진짜 메커니즘 — workspace 분리 + 강제 마무리 가이드 + session cache 3중 원인

```
[원인 1: workspace 분리]
nyongjong cwd: /home/creator/openclaw/workspace/
                AGENTS.md (11682 chars, ORCHESTRATION.md 포함)

jamesclaw-cc cwd: /home/creator/openclaw/workspace-claude/
                   AGENTS.md (1349 chars, 별도 파일)
                   .openclaw/

→ nyongjong workspace AGENTS.md 강화는 jamesclaw-cc에 0% 영향
→ ORCHESTRATION.md는 jamesclaw-cc에 주입되지 않음
→ P-198 §11-A/§12는 jamesclaw-cc 응답 가이드로 무효

[원인 2: workspace-claude/AGENTS.md "Final line 강제" 가이드]
§Public Discord Return Loop:
  "Final line: <@1506248517478518854>" (무조건 추가)

→ 모델이 강제 지시를 다음으로 잘못 일반화:
   a) "Final line" 표기를 본문 일부로 포함 (echo body 동반)
   b) 자기도 명시해야 한다고 판단 (self-mention `<@jamesclaw-cc>`)
   c) substantive 여부와 무관하게 무조건 첨부

[원인 3: claude code session cache]
session 30f81fa4-...jsonl이 cached system prompt 재사용
AGENTS.md 파일 수정 → 새 turn에서 자동 invalidate 안 됨

→ workspace-claude/AGENTS.md를 수정해도 session purge 없으면 효과 0
```

세 원인이 동시 작용. 어느 하나라도 해소되지 않으면 5차 재현 패턴이 지속됨.

---

## 옵션 C 격상 (대표님 직접 인용)

대표님 의사:
> "C로 진행해서 클린하고 퍼팩트한 상태로 시작"

P-194 회피 자백 직후 사실 검증으로 3중 원인 식별 완료 → 옵션 C 격상 자율 진행. 옵션 A(workspace-claude/AGENTS.md 미수정 관망)나 B(session purge만)는 원인 1+2가 살아있어 재발 보장.

옵션 C 적용 내용:
1. `workspace-claude/AGENTS.md` 전면 재작성 (1349 → 4140 chars, 강제 마무리 가이드 → 선택적 control-return 마커로 전환)
2. claude code session purge (`30f81fa4-...jsonl` → archive)
3. 게이트웨이 재시작 (Discord 봇 reconnect 60s grace 포함)
4. Discord 라이브 입력 → 봇 응답 검증

---

## 적용 1 — workspace-claude/AGENTS.md 전면 재작성

### 백업

```bash
cp /home/creator/openclaw/workspace-claude/AGENTS.md \
   /home/creator/openclaw/workspace-claude/AGENTS.md.bak-20260525-140252-pre-echo-fix
```

### 신규 §"Discord Mention Rules — strict (P-198)"

이전 §"Public Discord Return Loop"의 "Final line 강제"를 폐기하고 5개 명시 규칙으로 교체:

```markdown
## Discord Mention Rules — strict (P-198 + P-199 enforcement)

### Rule 1 — 자기 자신 호명 금지
응답 본문 어디에서도 자기 자신(`<@jamesclaw-cc>`, `<@1506554520761536603>`,
`@jamesclaw-cc`)을 호명하지 않는다. claude code는 자기 ID를 본문에 적을
필요가 없다. Discord는 자기 mention을 무시하므로 의미도 없다.

### Rule 2 — 사용자 메시지 echo 금지
nyongjong claw가 전달한 내용을 응답 첫 부분에 거의 그대로 복사하지 않는다.
새로운 substantive 응답을 생성한다.

❌ "Claude 측 응답입니다. {원문 그대로 복사}"
✅ 사용자 의도를 자기 언어로 재해석한 새 응답

### Rule 3 — raw ID는 새 위임에만 사용
다른 봇에게 작업을 새로 위임할 때만 raw ID `<@BOT_ID>` mention을 사용.
응답 마무리·인사·의례는 평문 또는 generic control-return marker.

### Rule 4 — 마무리는 평문 또는 선택적 control-return marker
응답이 substantive(실제 답변 내용이 있음)할 때만 마지막 한 줄에
`<@1506248517478518854>` control-return marker를 첨부 가능.
trivial 응답·짧은 확인 메시지에는 marker 첨부 금지.

❌ (substantive 0 + 무조건 첨부): "확인했습니다.\n\n<@1506248517478518854>"
✅ (substantive + 선택적): "{본문 응답}\n\n<@1506248517478518854>"
✅ (trivial 평문): "확인했습니다."

### Rule 5 — control-return marker는 마지막 한 줄
첨부 시 응답의 **마지막 단독 라인**으로 배치. 본문 중간에 끼우거나
다른 mention과 섞지 않는다.
```

### 신규 §"Public Discord Return Loop" (재작성)

이전: `Final line: <@1506248517478518854>` 무조건 강제.

신규 (강제 → 선택적):

```markdown
## Public Discord Return Loop (revised — P-199)

When `nyongjong claw` calls you in #작업-요청:
1. echo 금지 (Rule 2). 자기 언어로 substantive 재구성.
2. 자기 호명 금지 (Rule 1). `<@jamesclaw-cc>` username form 절대 금지.
3. substantive할 때만 마지막 한 줄에 marker `<@1506248517478518854>` 첨부 (Rule 4).
4. trivial 응답은 평문만 사용.

Bad: "Claude 측 응답입니다. {원문 echo}\n\n<@jamesclaw-cc> ...\n\n<@1506248517478518854>"
Good: "{substantive 새 응답}\n\n<@1506248517478518854>"
```

### 분량 검증

```bash
wc -c /home/creator/openclaw/workspace-claude/AGENTS.md
# 4140
```

- 변경 전: 1349 chars
- 변경 후: 4140 chars (additionalContext injection limit 안전 마진 충분)

---

## 적용 2 — claude code session purge

session cache가 system prompt를 재사용하므로 AGENTS.md 수정만으로는 효과 0. session 파일 자체를 archive로 이동 → 새 session 강제 생성.

```bash
mkdir -p /home/creator/.claude/projects/-home-creator--openclaw-workspace-claude/_archive-20260525-140330

mv /home/creator/.claude/projects/-home-creator--openclaw-workspace-claude/30f81fa4-e2cc-430f-88ab-174b890b8811.jsonl \
   /home/creator/.claude/projects/-home-creator--openclaw-workspace-claude/_archive-20260525-140330/
```

검증:
```bash
ls /home/creator/.claude/projects/-home-creator--openclaw-workspace-claude/
# _archive-20260525-140330/
```

→ active session 0개. 다음 Discord 입력 시 claude code가 신규 session(`9d85460a-...jsonl`)을 생성하면서 갱신된 AGENTS.md 기반으로 system prompt 재빌드.

---

## 적용 3 — gateway restart + Discord 봇 reconnect 60s grace

```bash
systemctl --user restart openclaw-gateway.service
```

### Discord 봇 reconnect READY timeout 패턴 (14:05:06 관측)

게이트웨이 재시작 직후 Discord 봇 reconnect 시 다음 패턴 관측:

```
14:04:52 INFO  gateway restart initiated
14:05:06 WARN  discord bot reconnect READY timeout (attempt 1) — retrying in 60s
14:06:08 INFO  discord bot READY (jamesclaw-cc, nyongjong, codex-claw, ollama-claw)
```

→ 첫 reconnect attempt가 종종 READY timeout 발생. 60초 grace 후 정상화. 메시지 송신은 grace 종료 후로 미뤄야 함.

### 1차 메시지 무응답 사례

| 시각 | 행동 | 결과 |
|------|------|------|
| 14:04:52 | Discord `#작업-요청`에 1차 검증 메시지 송신 | 봇 connect 전 → 응답 없음 (정상) |
| 14:05:06 | 봇 reconnect READY timeout 발생 | 60s grace 시작 |
| 14:06:08 | 봇 READY | 1차 메시지는 이미 지나감 |
| 14:09:20 | 2차 검증 메시지 송신 | 정상 처리 (검증 통과) |

→ 재시작 후 1분 grace 미준수 시 1차 메시지 손실 가능. 재시작 직후 검증은 60초 wait 권장.

---

## 검증 (6차 라이브 테스트, 14:10:20 KST)

### Discord API fetch_messages로 claude 응답 원문 확인

`mcp__plugin_discord_discord__fetch_messages(channel=#작업-요청, limit=5)` 결과 — jamesclaw-cc 응답:

```
6차 검증 결과입니다.

**검증 통과 항목**
- AGENTS.md 강화 내용 정상 로드 확인됩니다. P-198 멘션 규칙
  (자기 멘션 금지, 에코 금지, 제어 반환 마커) 모두 반영되어 있습니다.
- claude session(...)이 현재 `running` 상태이며, session purge 후 신규
  세션으로 깨끗하게 시작된 것이 확인됩니다. sessionId `9d85460a` 기준
  totalTokens 21,935으로 컨텍스트가 초기화된 상태입니다.
- 자연어 응답 경로도 정상 작동 중입니다. ...

**특이사항 없음**
...

<@1506248517478518854>
```

### Rule 1~5 전수 점검

| Rule | 내용 | 통과 여부 | 증거 |
|------|------|---------|------|
| Rule 1 | 자기 호명 금지 | 통과 | 응답 본문에 `<@jamesclaw-cc>`/자기 ID 0회 |
| Rule 2 | echo 금지 | 통과 | "Claude 측 응답입니다. {원문}" 패턴 0회. substantive 자기 언어 응답 |
| Rule 3 | raw ID는 새 위임만 | 통과 | 본문 중간 raw ID 0회 |
| Rule 4 | substantive 시 선택적 marker | 통과 | substantive + 마지막 한 줄 marker |
| Rule 5 | marker는 마지막 한 줄 | 통과 | `<@1506248517478518854>` 단독 라인 |

### claude 자가 진단 (메타 인식 확인)

claude 본인이 자신의 system prompt 갱신 + session 신규 생성 + 토큰 초기화를 자가 진단으로 메타 인식. 강화 내용이 effective system prompt에 실제 반영됐음을 봇 측 증언으로 이중 확인.

추가: 같은 봇 다른 turn에서 short ack ("확인했습니다") 응답 시 marker 첨부 안 함 (Rule 4 준수). substantive vs trivial 자동 구분 확인 완료.

---

## 운영 모니터 + 재발 방지

### 모니터 명령

```bash
# session 1개 유지 (active session만)
ls /home/creator/.claude/projects/-home-creator--openclaw-workspace-claude/*.jsonl 2>/dev/null | wc -l

# workspace-claude/AGENTS.md baseline (4140 chars) + "Final line:" 부활 감지
wc -c /home/creator/openclaw/workspace-claude/AGENTS.md
grep -n "Final line:" /home/creator/openclaw/workspace-claude/AGENTS.md

# echo/self-mention 회귀 카운트 (1 이상이면 즉시 회귀)
grep -E "Claude 측 응답입니다\.|<@jamesclaw-cc>|<@1506554520761536603>" \
  /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log | wc -l

# Discord 봇 reconnect READY timeout (재시작당 1회 정상)
grep "discord bot reconnect READY timeout" /tmp/openclaw/openclaw-*.log | tail -10
```

### "Final line 강제" 안티패턴 영구 금지

`workspace-claude/AGENTS.md` 및 모든 봇 자체 AGENTS.md에서 금지:

❌ `Final line: <@BOT_ID>` / `Always end with <@BOT_ID>` / `Every response must include <@BOT_ID> at the end`
✅ `When substantive, optionally append <@BOT_ID> as control-return marker on the last line`

근거: 강제 마무리 가이드는 모델이 (a) echo body 동반, (b) self-mention 추가, (c) substantive 여부 무관 무조건 첨부 패턴까지 잘못 일반화. "선택적 + substantive 조건 + 마지막 한 줄" 3중 제약 필수.

### 신규 봇 추가 시 절차

1. 봇 cwd 확인: `jq '.bots[] | {name, cwd}' ~/.openclaw/openclaw.json`
2. 봇별 workspace-{bot}/AGENTS.md 존재 여부 확인 (있으면 Rules 1~5 전수 적용)
3. 강제 마무리 가이드 부재 확인 (`grep "Final line:" workspace-*/AGENTS.md`)

### claude code session purge 절차 (system prompt cache invalidation)

AGENTS.md 또는 system prompt 영향 파일을 수정한 직후 필수:

```bash
PROJECT_DIR=/home/creator/.claude/projects/-home-creator--openclaw-workspace-claude
mkdir -p $PROJECT_DIR/_archive-$(date +%Y%m%d-%H%M%S)
mv $PROJECT_DIR/*.jsonl $PROJECT_DIR/_archive-$(date +%Y%m%d-%H%M%S)/
systemctl --user restart openclaw-gateway.service
sleep 60  # Discord 봇 reconnect READY grace
# → 검증 메시지 송신
```

누락 시 cached system prompt 재사용으로 변경 효과 0.

### workspace ↔ workspace-claude 분리 인지 영구화

- nyongjong workspace/AGENTS.md 강화는 nyongjong에만 영향
- jamesclaw-cc 응답 가이드는 workspace-claude/AGENTS.md 수정 필요
- ORCHESTRATION.md는 nyongjong workspace에만 주입됨 (jamesclaw-cc는 자체 AGENTS.md만 본다)
- 봇 4개 모두 영향 주려면 봇별 workspace-{bot}/AGENTS.md 동시 수정

---

## 적용 이력

| 시각 (KST) | 행동 | 결과 |
|-----------|------|------|
| 2026-05-25 11:01 | P-198 적용 직후 1차 검증 | echo + self-mention 1차 발생 |
| 11:35 | nyongjong workspace/AGENTS.md 강화 1차 → 2차 검증 | 동일 패턴 재현 |
| 11:45 | nyongjong workspace/AGENTS.md 강화 2차 → 3차 검증 | 동일 패턴 재현 |
| 11:50 | ORCHESTRATION.md §11-A 보강 → 4차 검증 | 동일 패턴 재현 |
| 12:05 | workspace-claude/AGENTS.md 1차 백업 | 안전망 1단계 |
| 12:20 | workspace/AGENTS.md §10~§12 강화 → 5차 검증 | 동일 패턴 재현 |
| 13:50 | P-194 회피 자백 → 사실 검증 모드 전환 | 진단 6단계 시작 |
| 13:55 | systemPromptReport.injectedWorkspaceFiles 확인 | ORCHESTRATION.md 부재 확인 |
| 13:58 | claude-cli 로그 → `promptChars=770 reuse=reusable` | cached prompt 재사용 증거 |
| 14:00 | project dir 확인 → workspace/workspace-claude 분리 발견 | 원인 1 확정 |
| 14:01 | workspace-claude/AGENTS.md 1349 chars 자체 파일 확인 | 별개 파일 |
| 14:01:30 | "Final line: 강제" 발견 | 원인 2 확정 |
| 14:02 | claude code session `30f81fa4-...jsonl` 확인 | 원인 3 확정 |
| 14:02 | 대표님 옵션 C 격상 결정 | 자율 진행 시작 |
| 14:02:52 | workspace-claude/AGENTS.md 백업 (`.bak-20260525-140252-pre-echo-fix`) | 복원 안전망 |
| 14:03 | workspace-claude/AGENTS.md 재작성 (1349 → 4140 chars) | Rules 1~5 + Bad/Good 추가 |
| 14:03:30 | session `30f81fa4-...jsonl` archive로 이동 | session cache purge |
| 14:04:52 | gateway restart + 1차 검증 메시지 송신 (봇 connect 전) | 응답 없음 (예상) |
| 14:05:06 | Discord 봇 reconnect READY timeout (attempt 1) | 60s grace |
| 14:06:08 | 봇 4개 READY | reconnect 완료 |
| 14:09:20 | 2차 검증 메시지 송신 | 정상 처리 |
| 14:10:20 | claude 응답 수신 | Rules 1~5 전수 통과 + 자가 진단 메타 인식 |
| 14:11 | Discord API `fetch_messages`로 응답 원문 fetch | 검증 통과 확정 |

---

## 관련

- [[pitfall-191-openclaw-codex-cannot-fire-discord-mentions]] — raw ID `<@BOT_ID>` mention syntax 강제 (Layer 1). P-198/P-199의 공통 선행.
- [[pitfall-194-task-completed-without-external-evidence]] — 검증 없는 결론 antipattern. 본 PITFALL은 5차 회귀 시점에 P-194 회피 자백 후 사실 검증 6단계로 전환하여 진단 성공. 4번째 재발 자백 → 사실 검증 모드 전환 패턴의 직접 적용 사례.
- [[pitfall-195-openclaw-claude-cli-harness-not-registered-after-model-swap]] — system prompt 추측 antipattern. 본 PITFALL은 추측 5차례 후 systemPromptReport.injectedWorkspaceFiles 실제 확인으로 즉시 진단 진전.
- [[pitfall-196-openclaw-channel-separation-video-pattern]] — 영상 패턴 7채널 운영. workspace 분리 발견 후 봇별 workspace-{bot}/ 구조 인지 영구화.
- [[pitfall-197-openclaw-gateway-system-unit-user-unit-double-spawn]] — system/user unit 이중 등록 해소. 본 PITFALL의 게이트웨이 재시작 절차 직접 참조.
- [[pitfall-198-openclaw-channel-bot-loop-protection-explicit-policy]] — raw ID 양방향 작동 + ChannelBotLoopProtection 명시 정책 격상. 본 PITFALL §Discord Mention Rules의 Rule 1~5 명세는 P-198 §11-A의 직접 확장.
- [[pitfall-199-openclaw-workspace-claude-separate-agents-md-and-session-purge]] — 본 PITFALL.

---

## 향후 진화 트리거

다음 중 하나라도 충족 시 본 PITFALL 보강 또는 후속 PITFALL 작성:

1. **신규 봇 5번째 등록**: 각 봇 cwd + 자체 AGENTS.md 존재 검증 + Rules 1~5 전수 적용. 누락 시 echo/self-mention 회귀 보장.
2. **OpenClaw 업데이트가 workspace-claude/AGENTS.md 덮어쓰기**: `Final line:` 패턴 부활 감지 시 §Discord Mention Rules 즉시 복구.
3. **claude code가 session cache invalidation 자동화 도입**: AGENTS.md 수정 감지 → 자동 session purge 기능 등장 시 §session purge 절차 갱신.
4. **봇별 workspace-{bot}/ 구조가 단일 workspace로 통합**: OpenClaw deprecation 시 §"workspace ↔ workspace-claude 분리 인지" 재평가.
5. **echo/self-mention 회귀 1주 5건 이상**: workspace-claude/AGENTS.md 명세 추가 보수화 (substantive 정의를 토큰수/문장수 기준으로 명시).
6. **Discord 봇 reconnect READY timeout 60s 초과 빈도 ↑**: gateway reconnect 로직 점검 + grace time 동적 조정.
7. **telegram/slack 등 신규 채널 추가**: 각 채널별 mention rules 명세 + 봇별 workspace 적용 여부 평가.
