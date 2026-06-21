---
slug: pitfall-259-fable5-adoption-harness-diet-stale-model-anchors
title: "메인 모델 전환 시 하네스 전반의 구모델 앵커가 발목 — Fable 5 채택 + 다이어트 감사"
symptom: "메인 세션을 Fable 5[1m]로 전환했으나 CLAUDE.md·rules·commands·옵시디언 17곳+이 'Opus' 메인 전제로 기술 — 새 세션이 Opus로 자기인식/회귀할 위험. 감사 'No Antigravity' 678회·'Rule Impl Gap' 상시 거짓 FAIL."
tags: [fable-5, model-migration, diet, audit-false-positive, self-reference, P-256, reins]
date: 2026-06-11
severity: medium
related: [pitfall-258-reins-engineering-machine-verdict-deterministic-feedback, pitfall-256-deploy-claude-md-oneway-overwrite-manual-undeployed, pitfall-070-statusline-settings-fixed-model-override]
---

> ⛔ **[2026-06-21 SUPERSEDED — pitfall-270]** Fable 5는 대표님 지시로 **사용 금지**, 메인 세션 **Opus 4.8**(`claude-opus-4-8`) 복귀. 본 pitfall의 'Fable 5 채택' 전제는 무효이나, **역할기반 모델명 일반화(하드코딩 금지) 교훈은 유효**. (STICKY 폐기 표 참조)

## 증상

1. 2026-06-11 대표님이 메인 세션을 `claude-fable-5[1m]`로 전환했으나, 하네스 문서가 모델명을 하드코딩("Opus는 판단만", "Opus 최종 판단", "Opus 세션 compact 45%", STICKY "메인 세션 Sonnet 유지"+"Fable 5 관망")해 **다음 세션이 구모델로 회귀하거나 잘못된 라우팅을 따를 위험**.
2. 일일 감사가 매 세션 거짓 FAIL 2종 누적:
   - `check_no_antigravity` **678회 FAIL** — 파일 단위 grep이 CLAUDE.md의 폐기 가드 문구("Antigravity 재도입 금지") 자체에 걸리는 **자기참조 거짓양성**. 가드 텍스트가 치료제인데 질병으로 판정.
   - `check_rule_impl_gap` 상시 FAIL — ①정규식 `\.(sh|ts|js)`가 `.json` 파일명을 `.js`로 오추출(`access.json`→`access.js`) ②WSL2 전용 `openclaw-*.js`를 `~/.claude`에서 찾음.

## 원인

- **모델명 하드코딩**: 정책 문서가 "메인 모델"이라는 역할 대신 특정 모델명(Opus)을 주어로 사용 → 모델 전환 때마다 전수 수정 필요, 누락 시 발목.
- **가드 문구 자기참조**: 폐기 감사가 "사용"과 "폐기 경고 언급"을 구분하지 않음.
- **추출 정규식 경계 부재** + **배포 경계(Windows ~/.claude vs WSL2) 미고려**.

## 해결 (2026-06-11, ultracode 17-에이전트 감사 wf_1ac105cd-954 → 87건 발견 → 적용)

1. **STICKY 갱신**: "메인 세션 Fable 5[1m] 채택(임의 회귀 금지)" 등록, 관망/Sonnet 유지 2행 대체. v2.1.172의 1M auto-compact 수정이 1M 운용 리스크 해소 근거.
2. **역할 기반 일반화**: CLAUDE.md 17곳 + rules 4파일 + commands 3파일의 "Opus" 메인 주어를 **"메인 모델(현 Fable 5)"**로 교체. 다음 전환 시 STICKY 1곳만 수정하면 되는 구조.
3. **감사 거짓양성 수정** (기계 테스트 3/3 PASS + Codex 검수 1건 반영):
   - antigravity: 라인 단위 grep + 가드 키워드 제외 + **호출형 패턴(`opencode serve` 등) 무필터 별도 카운트**(Codex 지적 — 가드 키워드가 포함된 절차 라인의 거짓음성 방어, synthetic 테스트로 검증).
   - rule_impl_gap: `\b` 경계로 `.json` 오추출 차단 + `openclaw-*` WSL2 스크립트 EXCLUDE.
4. **다이어트**: 매뉴얼 v2.1.85~132 히스토리 분리(114KB→74KB, 요약표+포인터 잔존), harness-manual.md(49KB)+.manual-data.md(31KB)+5월 감사로그 27건(231KB) 아카이브, docs/changelog.md 포인터화, statusline 중복본 제거+Fable 케이스 추가, settings.json D:/ 경로 6건 $HOME 정규화(배포본 SAME 실측 후).
5. **적대 검증의 가치**: 파괴 제안 10건 중 8건 차단(verify 단계) — self-evolve.sh "미존재" 주장은 실존 확인으로 기각, agent-team.md 아카이브는 inbound refs로 차단. **스캐너 주장을 기계 실측 없이 적용했으면 운영 hook 2개가 깨졌다.**

## 재발 방지

- **정책 문서에서 메인 세션 주어는 "메인 모델(현 X)" 형식** — 모델명 하드코딩 금지. 현행 모델은 STICKY 모델 티어 표가 단일 소스.
- **폐기 감사 설계 시**: "언급"이 아니라 "호출형 패턴"을 양성 신호로, 가드 문구는 제외 필터로. 가드 문구가 FAIL을 만들면 자기참조다.
- **파일명 추출 정규식엔 `\b` 경계** + 배포 경계 밖(WSL2) 자산은 EXCLUDE 명시.
- 모델 전환 직후 `grep -rn "구모델명" harness/ --include='*.md'`로 앵커 전수 스캔을 표준 절차로.
