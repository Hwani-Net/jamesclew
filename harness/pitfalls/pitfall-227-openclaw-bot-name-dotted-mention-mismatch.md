# P-227: OpenClaw 봇간 멘션 실패 — 이름 점표기 불일치 (@J.A.R.V.I.S. vs @JARVIS 패턴)

- **발견**: 2026-05-29
- **영향**: 봇끼리 협업 시 수신 봇 무응답. 특히 EVE가 응답 끝에 `@J.A.R.V.I.S.`로 종합 요청해도 JARVIS 미트리거 → 협업 체인 끊김.

## 증상
- 대표님 관찰: "마지막 줄에 멘션하면 내용 전달이 안 되는 것 같다. 첫 줄에 멘션해야 하나?"
- 실제: EVE 응답 끝 `@J.A.R.V.I.S.` → JARVIS(opus) 트리거 0 (로그상 `trigger=heartbeat`만, user 트리거 없음).

## 원인 (검증)
**멘션 위치 무관**(mentionPatterns는 normalizeMentionText 후 전체 텍스트 substring 매칭). 진짜 원인은 **이름 표기 불일치**:
- 봇들이 identity.name "J.A.R.V.I.S."를 보고 자연스럽게 `@J.A.R.V.I.S.`(점)로 호출
- JARVIS의 mentionPattern은 `@JARVIS`(점 없음) → `/@JARVIS/i`는 "@J.A.R.V.I.S."에 미매칭
- author.bot=true 메시지는 allowBots="mentions" 게이트에서 wasMentioned=true 필요한데 미매칭 → 드롭

통제 테스트로 격리 확증:
- `@JARVIS`(무점) → JARVIS `trigger=user` ✅
- `@J.A.R.V.I.S.`(점) → 트리거 0 ❌ (수정 전)
- requireMention=False/위치는 무관 (Data reqMention=True도 동일하게 무점은 작동)

## 해결 (3중 안전망)
1. **mentionPatterns에 점버전(이스케이프) 추가** — 점 있는 이름만:
   - main: `["@JARVIS", "@J\\.A\\.R\\.V\\.I\\.S\\.", "@자비스", "@뇽"]`
   - hermes: `["@FRIDAY", "@F\\.R\\.I\\.D\\.A\\.Y\\.", "@프라이데이"]`
   - (점은 정규식 메타라 `\\.`로 이스케이프. 안 하면 any-char 오작동)
2. **identity.name 점 제거** — "J.A.R.V.I.S. (자비스/뇽)" → "JARVIS (자비스/뇽)". LLM이 무점 `@JARVIS`로 부르도록 유도.
3. **Discord 서버 닉네임 점 제거** — JARVIS/FRIDAY (`PATCH /guilds/{id}/members/@me` nick). 사람도 무점으로 보고 부름.
- **양쪽 gateway config 모두 적용** (gw1 main config + gw2 ~/.openclaw-pro/openclaw.json).

## 검증 (수정 후)
- `@JARVIS`(무점) → `trigger=user` ✅
- `@J.A.R.V.I.S.`(점) → `trigger=user` ✅ (이스케이프 패턴으로 매칭)
- 양쪽 다 작동 = 봇이 어떻게 부르든 트리거됨.

## 재발 방지
- 새 봇 추가 시: identity.name·닉네임은 **점·공백 없는 단순 영문**으로. 약어에 점 찍지 말 것(KITT=O, K.I.T.T.=X).
- 점/특수문자 포함 이름이 불가피하면 mentionPatterns에 **이스케이프된 변형**을 반드시 추가.
- 멘션 안 되면 1순위 의심: 호출 표기 vs 패턴 문자 단위 대조 (대소문자는 i플래그로 무관, 점·공백·약어가 함정).

## 관련
- [[pitfall-225-openclaw-12agents-film-rename-scaling]] — mentionPatterns 도입
- [[pitfall-226-openclaw-native-2gateway-split]] — 양쪽 gateway 동기 적용 필요
- [[pitfall-191-openclaw-codex-cannot-fire-discord-mentions]] — 사람의 Role vs User mention (별개 현상)
