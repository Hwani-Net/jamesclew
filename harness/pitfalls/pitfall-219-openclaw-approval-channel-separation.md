# PITFALL-219 — OpenClaw 결재·승인 채널 분리 (#결재-필요)

- **날짜**: 2026-05-26
- **출처**: 대표님 직접 결정 (AskUserQuestion 응답)
- **연결**: P-201 (7-channel routing), P-213 (사용자 결정 분기), P-214 (야간 자율 결과 승인), P-218 (WSL2 경로 강제)
- **상태**: 활성

---

## 증상

OpenClaw 7-채널 구조(P-201) 기준 운영 중, 결재·승인이 필요한 항목이 #작업-요청 채널에 누적되면서 다음 문제 발생:

1. **메인 채널 노이즈 폭증** — 일반 사용자 작업 진입(#작업-요청) 본문에 결재 항목이 길게 섞이면서 새 작업 요청 가시성 저하
2. **대표님 알림 우선순위 무너짐** — 결재(즉시 응답 필요) vs 일반 진행 알림(나중에 봐도 됨)이 같은 채널에 섞여 푸시 알림 신호-노이즈 비율 ↓
3. **결재 대기 건수 불가시** — 누적 결재 항목 수 + 가장 오래된 항목이 어디 있는지 추적 불가
4. **P-213 사용자 결정 분기와 P-214 야간 자율 결과 승인이 분리 채널 없이 운영** — 새벽 야간 자율 사이클 결과가 아침에 #작업-요청에 쌓여 메인 흐름과 섞임

---

## 원인

1. P-201 7-채널 설계 시 "결재"가 별도 채널로 분리되지 않음 — #작업-요청에서 결재까지 처리하는 가정
2. P-213/P-214 후속 정책이 새 채널 없이 기존 채널 위에 layered → 노이즈 누적
3. 대표님 알림 정책상 **결재**는 즉시 응답 우선순위인데, 메인 채널 일반 알림과 동일 가중치로 푸시됨

---

## 해결 (대표님 결정 2026-05-26)

**8번째 채널 #결재-필요 신설.** 결재 5건 + P-213 사용자 결정 분기 + P-214 야간 자율 결과 승인 **모두** 이 채널 단독 처리.

### 채널 정보

- **이름**: `#결재-필요`
- **ID**: `1508626494711140444`
- **Topic**: "P-219: 결재 5건 + 사용자 결정 분기 + 야간 자율 결과 승인 전용. 대표님 알림 우선순위"
- **생성 봇**: nyongjong (MANAGE_CHANNELS 권한)
- **생성일**: 2026-05-26

### 결재 5건 정의 (CLAUDE.md Autonomous Operation 정책)

1. **git push**
2. **비용 큰 작업** (외부 API 유료 호출 ₩10,000+ / GCP / 신규 모델 활성)
3. **명시 요청 사항** (대표님 사전 확인 필요로 표시된 작업)
4. **비가역 삭제** (`rm -rf`, 데이터 폐기, 채널 삭제, DB drop)
5. **보안 위험** (시크릿 노출 가능, 권한 변경, 외부 송신)

### 발동 조건 (모두 #결재-필요로 push)

- 결재 5건 도달
- P-213 사용자 결정 분기 (nyongjong이 "후보 제시"까지 끝낸 후 결정 필요한 모든 분기점)
- P-214 야간 자율 사이클 종료 후 결재 대기 누적 항목

### nyongjong 동작 (orchestrator 단독 책임)

1. **결재 도달 감지** 시 즉시 #결재-필요 채널로 짧은 메시지 push (1~5줄):
   ```
   [Project: <slug>] 결재 필요: <항목>
   thread: <thread URL or message link>
   위험: <1줄>
   비용: <1줄>
   롤백: <1줄>
   옵션: A) <…>  B) <…>  C) <…> (필요 시)
   ```
2. **동시에 #작업-요청에 1줄 알림** (메인 채널 노이즈 최소화):
   ```
   ⚠ 결재 필요 → #결재-필요 (thread: <URL>) | <slug>: <항목 한 줄>
   ```
3. **사용자 답신 수신**: #결재-필요에서 직접 또는 thread에서 답신 받음
4. **답신 수신 후**: nyongjong이 자율 진행 재개 + 결과 보고는 thread + #작업-완료
5. **결재 항목 인덱스**: #공지사항 pinned 메시지에 "결재 대기" 섹션 실시간 갱신 (현재 건수 + 가장 오래된 항목)

### Worker 책임 (jamesclaw-cc / codex / ollama)

- **직접 #결재-필요로 push 금지**
- 결재 도달 인지 + nyongjong에게 thread 또는 #작업-진행중에서 "결재 필요: <항목>" 보고만
- 형식 메시지 작성 + #결재-필요 발송 + #작업-요청 1줄 알림은 모두 nyongjong 전담 (책임 분리)
- worker가 자율 진행 중 결재 항목 도달 → 즉시 정지 + nyongjong에 보고 (P-213 패턴 강화)

### 메시지 형식 표준 (nyongjong)

**#결재-필요 push 표준 헤더**:
```
[Project: <slug>] 결재 필요: <항목>
thread: <URL>
위험/비용/롤백 1줄씩
옵션 A/B/C (필요 시)
```

**#작업-요청 1줄 알림 표준**:
```
⚠ 결재 필요 → #결재-필요 | <slug>: <항목 한 줄> | thread: <URL>
```

---

## 재발 방지

### settings + 코드 변경

1. **`~/.claude/channels/discord/access.json`** — `groups` 객체에 `"1508626494711140444": { "requireMention": false, "allowFrom": [] }` 추가 (allowlist 등록 필수, 미등록 시 reply/fetch 실패)
2. **`workspace/AGENTS.md`** (WSL2 `/home/creator/.openclaw/workspace/AGENTS.md`) — §"Approval Channel (P-219)" 추가
3. **`workspace-codex/AGENTS.md`** + **`workspace-claude/AGENTS.md`** — §"P-219 (worker rules)" 추가 (worker 직접 push 차단)
4. **CLAUDE.md STICKY DECISIONS** — P-219 한 줄 기록 (인수인계 보장)
5. **#공지사항 pinned 메시지** — "결재 대기" 섹션 추가 (인덱스 가시화)

### 안전 규칙

- nyongjong이 #결재-필요 push 권한 단독 보유 (worker push 차단)
- 대표님 답신 없이 자율 진행 금지 (timeout 자동 진행 금지)
- 답신 후 자율 진행 재개 시 thread 내부에서 "승인 받음 — 진행 재개" 명시
- 결재 항목 archive 자동 보존 (#결재-필요 채널 자체가 archive 역할, 별도 이동 불필요)

### Anti-patterns (P-219)

- 결재 항목을 #작업-요청 본문에 길게 작성 → 메인 채널 노이즈 폭증, 대표님 알림 누락
- worker가 직접 #결재-필요로 push → 형식 깨짐 + orchestrator 우회
- #결재-필요에 결재 외 일반 보고 push → 채널 신호-노이즈 비율 저하
- 결재 완료 후 #결재-필요에 archive 남기지 않음 → 추적 불가 (반드시 답신 + 자율 진행 재개 보고)
- #공지사항 pinned 인덱스 갱신 누락 → 결재 대기 건수 미가시

---

## 검증

```bash
# Discord 채널 존재 확인 (WSL2)
wsl -d Ubuntu -e bash -c "python3 -c \"
import json, urllib.request
with open('/home/creator/.openclaw/openclaw.json') as f:
    cfg = json.load(f)
TOKEN = cfg['channels']['discord']['accounts']['default']['token']
req = urllib.request.Request(
    'https://discord.com/api/v10/channels/1508626494711140444',
    headers={'Authorization': f'Bot {TOKEN}', 'User-Agent': 'DiscordBot'},
)
print(urllib.request.urlopen(req, timeout=10).read().decode())
\""

# access.json에 등록 확인
grep '1508626494711140444' C:/Users/AIcreator/.claude/channels/discord/access.json

# AGENTS.md 3개 파일에 P-219 등록 확인 (WSL2 경로 P-218)
wsl -d Ubuntu -e bash -c "grep -c 'P-219' /home/creator/.openclaw/workspace/AGENTS.md \
  /home/creator/.openclaw/workspace-codex/AGENTS.md \
  /home/creator/.openclaw/workspace-claude/AGENTS.md"
```

---

## 관련

- [[pitfall-201-openclaw-7-channel-routing]] — 원본 7-채널 라우팅 패턴
- [[pitfall-213-openclaw-user-decision-branch-explicit]] — 사용자 결정 분기 (이번에 #결재-필요로 흡수)
- [[pitfall-214-openclaw-autonomous-continuation-prompt-overnight]] — 야간 자율 결과 승인 (이번에 #결재-필요로 흡수)
- [[pitfall-218-claude-code-sub-agent-wsl2-path-explicit-required]] — WSL2 경로 강제 (이번 작업 적용)

---

## 결정 근거 (대표님 발언 인용)

> 대표님 결정 (2026-05-26 AskUserQuestion 응답):
> "#결재-필요 채널 신설 (8번째 채널). 결재 5건 + P-213 사용자 결정 분기 + P-214 야간 자율 결과 승인 모두 이 채널 분리. 대표님 알림 우선순위 모니터링."

**핵심 의도**:
1. 결재 = 즉시 응답 우선순위 → 메인 채널과 분리
2. 한 채널에서 결재 대기 건수 + 가장 오래된 항목 가시화
3. P-213/P-214를 새 채널로 통합 흡수 → 운영 단순화 (정책 3개 → 채널 1개)

작성: nyongjong-orchestrator 위임 (sub-agent), 검토: Opus
