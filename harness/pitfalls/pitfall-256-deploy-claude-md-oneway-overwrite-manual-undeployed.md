---
slug: pitfall-256-deploy-claude-md-oneway-overwrite-manual-undeployed
title: "deploy.sh가 CLAUDE.md를 글로벌로 단방향 덮어쓰기 + 매뉴얼은 배포본에 미복사"
symptom: "①claude-code-manual.md를 편집·deploy해도 ~/.claude/docs 배포본에 반영 안 됨 ②harness/CLAUDE.md가 글로벌(~/.claude/CLAUDE.md)보다 구버전인데 deploy.sh 실행하면 글로벌의 최신 정책이 전멸"
tags: [deploy, claude-md, manual, sync, infrastructure, data-loss, template-drift]
date: 2026-06-04
severity: high
related: [pitfall-173-settings-template-auto-revert]
---

## 증상

Claude Code 버전 정리 작업(매뉴얼 v2.1.145~158 반영) 중 발견한 deploy.sh 동기화 비대칭 2건.

1. **매뉴얼 미배포**: `harness/docs/claude-code-manual.md`(정본)를 편집하고 `deploy.sh`를 실행해도 배포본 `~/.claude/docs/claude-code-manual.md`는 갱신되지 않는다. 실제로 정본이 배포본보다 최신(gbrain 폐기 반영 완료)인데 배포본엔 stale gbrain 흔적이 남아 있었다.
2. **CLAUDE.md 역방향 손실 위험**: `harness/CLAUDE.md`(소스, 402줄)가 글로벌 `~/.claude/CLAUDE.md`(427줄)보다 **구버전**이었다. 글로벌에만 P-223/224/225/229/230/254 + "서브에이전트 위임 금지" 섹션 등 최신 7개 정책 존재. 이 상태에서 `deploy.sh`를 실행하면 구버전 소스가 글로벌을 덮어써 **최신 정책 7개가 전부 사라진다.**

## 원인

`harness/deploy.sh`의 동기화가 **비대칭**:

- **CLAUDE.md** (line 23): `cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"` — harness → 글로벌 **단방향 무조건 덮어쓰기**. 비교·가드 없음.
- **docs/**: `docs/adr/`만 배포본에 cp. `claude-code-manual.md` 등 나머지 docs는 **옵시디언 미러(`cp -ru`)만** 하고 배포본 `~/.claude/docs/`는 건드리지 않음.

세션 중 글로벌 `~/.claude/CLAUDE.md`는 직접 Edit으로 실시간 진화하는데(STICKY DECISIONS·P-2xx 정책 추가), harness 소스로의 **역동기화가 명시적으로 일어나지 않으면** 소스가 stale 상태로 누적된다. 그 상태에서 deploy = 글로벌 최신 손실. P-173(settings.json 덮어쓰기로 fix revert)과 **동일한 단방향 덮어쓰기 뿌리**다. [[pitfall-173-settings-template-auto-revert]]

## 해결

1. **매뉴얼 업데이트 절차**: `harness/docs/claude-code-manual.md` 편집 → **배포본으로 수동 cp** (`cp harness/docs/claude-code-manual.md ~/.claude/docs/`). 옵시디언 미러는 deploy.sh가 처리. deploy.sh에 의존하지 말 것.
2. **CLAUDE.md 수정**: 글로벌(`~/.claude/CLAUDE.md`) + harness(`harness/CLAUDE.md`) **양쪽 동시 Edit**. 한쪽만 고치면 분기.
3. **deploy 전 필수 가드** (수동): `diff ~/.claude/CLAUDE.md harness/CLAUDE.md` — 글로벌이 더 최신(줄 수 ↑, 신규 P-2xx)이면 **역동기화 먼저** (`cp ~/.claude/CLAUDE.md harness/CLAUDE.md`) 후 deploy. 이번 건은 역동기화로 427줄 100% 일치 복원.

## 재발 방지

- **deploy.sh 보강 후보** (하네스 수정 → Codex 사전 검토 필요): CLAUDE.md cp 전에 글로벌 vs 소스의 줄 수/mtime 비교 → 글로벌이 최신이면 경고·중단. 매뉴얼도 docs/ 일괄 배포본 cp 추가.
- **인수인계 룰**: 글로벌 CLAUDE.md를 세션 중 편집했으면, 그 세션 안에서 harness 소스로 역동기화 또는 커밋. P-172(gbrain 부활)와 같은 "소스 stale → 다음 세션 오작동" family.
- deploy.sh는 **단방향 신뢰 금지** — settings.json(P-173), CLAUDE.md, docs 모두 소스가 진실이라는 가정이 깨질 수 있다.
