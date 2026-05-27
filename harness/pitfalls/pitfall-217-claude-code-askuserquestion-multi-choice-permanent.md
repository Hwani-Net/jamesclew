---
title: pitfall-217 — Claude Code 메인 세션이 다중 선택지를 표/리스트 자유 입력으로 묻는 패턴 폐기
slug: pitfall-217-claude-code-askuserquestion-multi-choice-permanent
date: 2026-05-26
type: pitfall
tags:
  - claude-code
  - main-session
  - askuserquestion
  - ux
  - decision-prompt
severity: medium
related:
  - pitfall-213-openclaw-user-decision-branch-explicit
  - pitfall-167-context-speculation-block
---

# pitfall-217 — 다중 선택지는 AskUserQuestion 도구로만 묻는다

## 증상

Claude Code 메인 세션(jamesclaw-cc / Opus)이 대표님께 다중 선택지를 제시할 때 다음 안티패턴이 반복됐다.

- 마크다운 표로 옵션 A/B/C 나열 후 "어느 것을 선택하시겠습니까?" 자유 입력 유도
- 리스트 + 번호로 옵션 제시 후 "1, 2, 3 중 골라주세요" 자유 입력 유도
- "A 또는 B 또는 C — 의견 주세요" 형태로 자연어 응답 요구

증거:
- 대표님이 응답 시 "A", "1번", "B로 가자", "그냥 너가 정해" 등 다양한 자유 텍스트 입력
- 봇이 자유 텍스트를 파싱해서 옵션 식별 → 파싱 실패 사례 발생
- 옵션 설명이 길면 대표님이 스크롤 + 재확인 → 결정 시간 증가
- 멀티 결정(1Q + 1Q + 1Q)이 직렬화되어 응답 사이클 N배

대표님 2026-05-26 지적: "다중 선택지면 표 만들지 말고 AskUserQuestion 써라."

## 원인

Claude Code Opus는 default로 마크다운 표/리스트가 가독성 높다고 판단하지만, **실제 UX에선 AskUserQuestion 도구가 클릭/탭 1회로 선택 가능**하다.

AskUserQuestion 도구는:
- 옵션 라벨 + 설명 분리 제공
- "Other" 자동 옵션 (자유 입력 fallback)
- 멀티 question 묶음 (1회 prompt 최대 4Q)
- 응답이 구조화 JSON으로 돌아옴 (파싱 실패 0)

이 도구를 사용하지 않고 표/리스트로 묻는 default 행동이 누적됐다.

## 해결

P-217 규칙으로 영구화한다.

1. **다중 선택지 제시 시 반드시 `AskUserQuestion` 도구 사용**.
2. **옵션 구성**: label (짧음, ≤15자) + description (1~2문장 근거/효과).
3. **자유 입력 옵션 추가 금지**: AskUserQuestion에 "Other" 자동 옵션이 있으므로, 추가로 "기타" 옵션을 만들지 않는다.
4. **멀티 question 묶음**: 단일 결정 1Q + 단일 결정 1Q는 1회 prompt에 묶어 발송 (최대 4Q). 직렬 발송 금지.
5. **표/리스트 사용 가능 케이스** (예외):
   - 정보 제공 (선택 요청 X) — 비교 표, 결과 요약
   - 옵션 5개 이상 (AskUserQuestion 옵션 상한 초과 시)
   - 옵션 설명이 코드 블록 / 다이어그램 / 이미지 포함 시 (AskUserQuestion 텍스트 한계)
6. **OpenClaw 채널과의 관계**:
   - OpenClaw nyongjong은 Discord 채널에 발송하므로 AskUserQuestion 도구 미적용 (P-213이 대신 적용 — `[Project: ...] 사용자 결정 필요: A) ... B) ... C) ...` 메시지 형식)
   - jamesclaw-cc 메인 세션(터미널 Claude Code)에서만 P-217 적용

## 재발 방지

- `~/.claude/CLAUDE.md` STICKY DECISIONS > 핵심 정책에 P-217 한 줄 추가됨 (2026-05-26).
- 다음 안티패턴 감지 시 jamesclaw-cc 자기 검토 + 즉시 교정:
  - 표/리스트로 선택지 제시 + "골라주세요" 자유 입력 유도
  - "1번/2번/3번" 번호 입력 유도
  - "A 또는 B" 자연어 응답 요구
- 검증 스크립트는 메인 세션 hook으로 구현 불가 (AskUserQuestion 도구 호출 여부는 모델 행동) — 자기 검토 의존.

## 안티패턴

- 마크다운 표로 옵션 비교 + "어느 것을 선택?" 자유 입력 유도
- "1, 2, 3 중에 골라주세요" 번호 입력 유도
- AskUserQuestion 호출 후 별도로 "Other"를 의미하는 옵션을 추가 (예: "기타 (자유 입력)")
- 단일 결정 1Q를 직렬 발송 (4Q 묶음 가능한데 1Q씩 4회 prompt)
- 옵션 label이 길어서 UI 잘림 (15자 초과)
- description 누락 → 사용자가 라벨만 보고 판단 어려움

## 검증 명령

수동 검토 (자기 검토):

```bash
# 메인 세션 대화 로그에서 표/리스트 + "골라주세요" 패턴 감지
# (Claude Code transcript JSON에서 assistant messages 추출 후 패턴 매칭)
grep -E "골라주세요|선택해주세요|어느 것" ~/.claude/projects/<project>/transcript-*.jsonl | \
  grep -v "AskUserQuestion"
```

## 영상 패턴 외 (메인 세션 UX 규칙)

본 PITFALL은 영상 패턴이 아니라 **우리 메인 세션 UX 규칙**이다. UsT1-E1Txyo 영상 패턴 흡수 작업 중 대표님 지적에서 발견됨.

OpenClaw nyongjong은 Discord 채널 발송이라 AskUserQuestion 도구를 쓸 수 없고, P-213 메시지 형식으로 대신 적용한다 (label + description 분리, 후보 명시 등 핵심 원칙은 동일).

## 관련

- [[pitfall-213-openclaw-user-decision-branch-explicit]] — OpenClaw 채널 버전의 같은 원칙
- [[pitfall-167-context-speculation-block]] — 추측 차단 — 자유 입력보다 구조화 응답이 추측 차단에 도움
