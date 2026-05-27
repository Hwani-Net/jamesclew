---
title: pitfall-213 — OpenClaw 봇 자율 결정 vs 사용자 결정 분기를 명시하지 않으면 취향·미적·전략 선택까지 자율 진행
slug: pitfall-213-openclaw-user-decision-branch-explicit
date: 2026-05-26
type: pitfall
tags:
  - openclaw
  - nyongjong
  - user-decision
  - autonomous-policy
  - p168
  - discord
severity: high
related:
  - pitfall-168-autonomous-decision-policy
  - pitfall-200-openclaw-nyongjong-pre-simulation-antipattern-mock-delegation
  - pitfall-205-openclaw-project-isolation-thread-per-project
---

# pitfall-213 — 사용자 결정 분기를 명시하지 않으면 자율 진행이 취향까지 침범한다

## 증상

OpenClaw nyongjong이 P-168 "결재 5건 외 자율 진행" 규칙만 따랐을 때 다음 시나리오가 반복됐다.

- 카피·슬로건 톤 선택을 봇이 단독 결정 → 대표님 의도와 어긋난 결과물 생성 → 재작업
- 디자인 시안 A/B/C 후보 중 봇이 임의 1개 채택 → 시안 비교 검토 기회 상실
- 블로그 글 톤(전문가형/친근형/스토리텔링형)을 봇이 단독 결정 → 톤이 매번 변동
- 영상 컨셉 후보가 여러 개 추출됐는데 봇이 그중 1개로 즉시 작업 진행 → 다른 후보 평가 누락

핵심 패턴: 결재 5건(push / 비용 큰 작업 / 명시 요청 / 비가역 삭제 / 보안 위험)에 해당하지 않는다는 이유로, **취향·미적·전략 선택**까지 자율 진행됐다.

## 원인

P-168 자율 결정 정책은 "비가역적 위험" 회피에 초점이 맞춰져 있다. 하지만 다음 두 영역은 자율 진행하기에 부적절하다.

1. **취향**: 톤, 글투, 컬러, 음악, 폰트 — 대표님 개인 감각이 일관성의 근거
2. **전략**: A/B 시안 비교, 컨셉 후보 선정, 카피 변형, 슬로건 선택 — 비교를 거쳐야 의미가 있는 선택

이 영역들에서 봇이 단독 결정을 내리면 대표님이 "왜 이렇게 했나?" 사후 추궁이 발생하고, 결과물 자체는 비가역이 아닌데도 재작업 비용이 크게 든다.

## 해결

P-213 규칙으로 영구화한다.

1. 결재 5건(push / 비용 큰 작업 / 명시 요청 / 비가역 삭제 / 보안 위험) **외에 다음 영역도 사용자 결정**으로 분류한다.
   - **취향**: 톤, 글투, 컬러 팔레트, 폰트, 음악, 시각적 무드
   - **미적**: 시안 비교 (A/B/C+), 레이아웃 후보, 캐릭터/일러스트 스타일
   - **전략**: 카피 변형 선택, 슬로건 후보, 컨셉 방향, 타겟 페르소나 결정
2. nyongjong은 사용자 결정이 필요한 시점에 다음 형식으로 #작업-요청에 알림을 발송한다.
   ```
   [Project: <slug>] 사용자 결정 필요
   상황: <한 문장 맥락>
   후보:
   A) <옵션 A 설명 + 근거 1줄>
   B) <옵션 B 설명 + 근거 1줄>
   C) <옵션 C 설명 + 근거 1줄>
   ```
3. 후보 추출은 nyongjong이 자율로 수행한다. **후보 선정 자체는 자율, 그중 1개 채택은 사용자 결정**.
4. 사용자 답신을 받기 전까지 그 갈래(branch)는 멈춘다. 다른 갈래는 계속 진행 가능.
5. 답신은 mention(@nyongjong) 또는 thread 안 reply 모두 허용.

## 재발 방지

- `/home/creator/.openclaw/workspace/AGENTS.md`에 `User Decision Branch (P-213)` 섹션 추가.
- nyongjong 시스템 프롬프트 / SOUL.md에 "취향·미적·전략 = 사용자 결정" 룰 추가.
- jamesclaw-cc 메인 세션 CLAUDE.md "핵심 정책"에 P-213 한 줄 추가됨 (2026-05-26).
- 사용자 결정 요청 메시지는 `#작업-요청` 채널에 발송, **다른 채널엔 mirror 금지** (잡음 방지).

## 안티패턴

- 봇이 "비가역이 아니니 일단 진행 후 보여드린다" → 재작업 비용 발생
- 봇이 후보 1개만 보여주고 "이걸로 진행해도 될까요?" → 선택지가 없는 사용자 결정 요청
- 봇이 사용자 결정 요청을 thread 안에만 묻고 마스터 채널엔 미통지 → 부재 중 놓침
- 봇이 답신 없는 사이 다른 갈래까지 멈춤 → 자율성 손실

## 검증 명령

```bash
# 사용자 결정 요청 형식 준수 검증
grep -rE "\[Project: .+\] 사용자 결정 필요" /tmp/openclaw/openclaw-*.log | wc -l

# 답신 전 진행 위반 감지
node /home/creator/.openclaw/workspace/scripts/openclaw-p213-user-decision-audit.js \
  --window 1h --threads-only
```

## 영상 패턴 출처

UsT1-E1Txyo 영상에서 "에이전트가 자율 진행하되, 취향·전략은 사용자에게 묻는 분기" 패턴 등장. 본 PITFALL은 우리 OpenClaw 7채널 운영에 맞춰 #작업-요청 채널 발송으로 구체화했다.

## 관련

- [[pitfall-168-autonomous-decision-policy]] — 결재 5건 정책 원본
- [[pitfall-200-openclaw-nyongjong-pre-simulation-antipattern-mock-delegation]] — 위임 누락 안티패턴
- [[pitfall-217-claude-code-askuserquestion-multi-choice-permanent]] — 메인 세션 동일 원칙의 UX 버전
