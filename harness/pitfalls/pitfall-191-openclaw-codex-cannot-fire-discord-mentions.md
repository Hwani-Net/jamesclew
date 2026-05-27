# P-191: OpenClaw codex 봇이 다른 봇을 텍스트 `@이름`으로 멘션해도 실제 mention 이벤트 미발생

- **발견**: 2026-05-20
- **영향**: 3봇 티키타카 협업 실패. Codex(뇽죵)가 §1-A 트리거 키워드 받고도 텍스트 "@jamesclaw-cc"만 쓰면 두 봇이 응답 안 함.
- **검증 누락 자백**: 이 세션에서 "ORCHESTRATION §1-A 주입 완료"로 보고했으나 **실제 멘션 발사 작동 검증 없음** — P-167 안티패턴 재발.

## 2026-05-25 보완 — Role mention vs User mention 결정적 단서

대표님 디버깅 세션(01:42 KST)에서 발견:

Discord 드롭다운에 **2가지 멘션 후보** 표시:
- 위쪽: `nyongjong claw #7750` (프로필 사진 있음) — **User mention** ✅
- 아래쪽: `@nyongjong claw` (프로필 사진 없음, "이 채널을 볼 수 있는 권한을 가진..." 설명) — **Role mention** ❌

검증 결과:
- Role mention 선택 시 봇 무응답 (Discord가 user mention 객체 생성 안 함)
- User mention 선택 시 봇 정상 응답
- 단순 평문 `@nyongjong claw` 타이핑 = Role mention처럼 처리되어 무응답

### 사용자 사용 가이드 (필수)

Discord에서 봇 멘션 시:
1. `@` 입력 → 드롭다운에서 **프로필 사진 있는 항목** 클릭 (User mention)
2. 또는 raw ID `<@1506248517478518854>` 타이핑
3. 또는 default 봇은 멘션 없이도 응답 (`requireMention=False`)

❌ **금지**: 드롭다운 없이 평문 `@nyongjong claw` 입력 → Role mention으로 처리되어 봇 무응답

이 보완은 1시간 30분 OpenClaw 디버깅 세션(2026-05-25 00:00~01:42)의 진짜 root cause. 모든 인프라 fix(GPT-5.5 swap, stuck session 정리, ORCHESTRATION 트림, 200KB transcript 패치, auth-state 매핑)는 정상 작동했으나, 대표님이 사용한 멘션 방식이 Role mention이었던 게 봇 무응답 원인.

## 증상 (원본)

대표님: `@nyongjong claw ollama랑 james의 의견도 동일해?`
뇽죵 응답: "아직 두 봇의 실제 답변은 안 올라왔습니다. (...) james와 ollama가 답하면 제가 바로 비교..."

뇽죵은 §1-A를 인지하고 협업 의도를 표현하지만 실제로는 **두 봇을 핑하지 못함**.

## 원인 (코드 검증 완료)

`jamesclaw-cc-relay/index.js:40` 및 `ollama-relay/index.js:53`:
```javascript
const userMentioned = msg.mentions.users.has(SELF_ID);
```

→ **Discord 실제 mention 이벤트** 로만 트리거.

Codex 응답 텍스트의 `@jamesclaw-cc`는 plain text이지 mention object 아님. 진짜 멘션 트리거는 `<@USER_ID>` 형식 필요:
- jamesclaw-cc: `<@1506554520761536603>`
- ollama claw: `<@1506595165475967016>`

## 해결 (2-layer)

### Layer 1 — ORCHESTRATION §1-A에 정확한 syntax 명시

코드 펜스 안에 봇 ID-mention 형식 + bot ID 표 추가:
```
| 봇 | 텍스트 alias | 실제 멘션 syntax (필수) |
|---|---|---|
| jamesclaw-cc | @jamesclaw-cc | <@1506554520761536603> |
| ollama claw | @ollama claw | <@1506595165475967016> |
```

### Layer 2 — relay 텍스트 alias fallback (견고성)

`index.js`의 mention 검사에 텍스트 alias도 추가:
```javascript
const aliases = ['@jamesclaw-cc', '@올라', '@ollama claw'];
const textMentioned = aliases.some(a => msg.content.toLowerCase().includes(a.toLowerCase()));
const userMentioned = msg.mentions.users.has(SELF_ID) || (textMentioned && /*해당 봇 alias 매칭*/);
```

`allowBots: true` 가 OpenClaw guild config에 있어야 봇끼리 멘션 인식. 확인 완료.

## 재발 방지

- **검증 없는 "고쳤습니다" 보고 금지** (P-167 강화). 변경 후 반드시 end-to-end 시나리오 실행으로 확인. 자동화된 검증이 어렵다면 대표님께 "재테스트 요청"으로 honestly 보고.
- 새 협업 자동화 추가 시 **3가지 검증 필수**:
  1. 시스템 프롬프트 트리거 (codex가 알아듣는가)
  2. 출력 syntax (Discord/대상 시스템이 인식하는가)
  3. 수신 측 인식 (수신 봇 코드가 이벤트를 잡는가)

## 관련

- [[pitfall-184-openclaw-windows-discord-readiness]]
- [[pitfall-188-openclaw-wsl2-deployment-complete-2026-05-20]]
- [[pitfall-190-openclaw-ollama-claw-cloud-model]]
- ORCHESTRATION.md §1-A
- P-167 "검증 없이 완료 보고 금지" 정책
