# P-235: 자율진행 루프(openclaw agent + codex critic) 검증 + critic 오탐 양방향 검증 + 검수 추출 바이트절단 함정

- **검증**: 2026-05-31 (대표님 지시: "자율진행 프롬프트 연속 지시 + codex critic 논의 + 흐름 끊김 없이 검증")
- **결과**: 9라운드 자율진행 루프 성공. 봇 자율 + critic 양방향 검증 작동 입증.

## 자율진행 루프 구조 (검증됨)
```
내가 대표님役 프롬프트 생성
  → openclaw agent --agent main -m "..."  (JARVIS 자율 구동, Discord allowFrom 우회)
  → JARVIS 자율 수행 (browser/리서치/파일)
  → codex exec "..." critic (적대적 검증)
  → critic 반영 지시 → 반복
```
- **`openclaw agent --agent main -m`**: Discord 봇간 allowFrom 막힘을 우회해 JARVIS 직접 구동. 자율진행 루프의 핵심 채널.
- 9라운드: 글감선정→critic반영→본문전체→codex검수(REWORK)→반영→재검수→오탐반박→최종PASS.

## 핵심 교훈 1 — critic도 오탐한다, 봇/운영자가 증거로 검증하라
- codex가 "51행 깨진 문자" 지적 → JARVIS가 `grep -P "\x{fffd}"` 0개 + 바이트 `c2 b7` = U+00B7(가운뎃점, 정상) 증거로 **반박**.
- codex가 "파일 끝 깨짐(ED 단독바이트)" 지적 → 원본 strict UTF-8 decode OK + U+FFFD 0개로 **오탐 확정**.
- **critic 맹목 수용 금지.** REWORK 지적도 grep/바이트 증거로 검증. 봇이 critic을 반박하는 것이 건강한 루프.

## 핵심 교훈 2 — 검수용 파일 추출에 `head -c`(바이트 절단) 금지
- 내 실수: `head -c 3800`으로 본문 추출 → 한글(ED 시작 3바이트) **중간에서 절단** → `�` + 단독바이트 생성 → codex가 "파일 깨짐"으로 오탐.
- **해결: 검수용 추출은 `head -n`(줄 단위) 또는 전체 파일 사용.** 바이트 단위 절단은 멀티바이트(한글/이모지) 깨짐 아티팩트를 만든다.
- 원본은 멀쩡한데 추출 방식이 가짜 결함을 만들어 critic을 오도 → 시간 낭비.

## 핵심 교훈 3 — 운영자(나)의 성급 판단도 루프가 교정
- 라운드7에서 내가 "JARVIS 자가체크(U+FFFD 0개)가 거짓, codex가 잡았다"고 성급 판단.
- 라운드8에서 JARVIS가 바이트 증거로 "codex 오탐, 내 자가체크가 맞다" 입증 → 내 판단 뒤집힘.
- **증거(grep/xxd/strict decode) 없이 누가 옳다 단정 금지.** critic도 봇도 나도 틀릴 수 있다.

## 결과물
- `money/affiliate-seasonal-appliances/window-ac-2026-draft.md` (창문형 에어컨 글, 3313자)
- 최종: 가격 단정 제거(안내형), AI냄새 0, 모델명 완충, 쿠팡 대가성문구, strict UTF-8 정상 = 발행 가능 수준 (가격/모델은 쿠팡 실시간 확인 전제).

## 관련
- [[pitfall-234-openclaw-browser-headful-session-bot-autopublish]] (봇 자율 발행 인프라)
- [[pitfall-163]] codex 1순위 critic / 로컬 보조
- ORCHESTRATION.md §14-B
