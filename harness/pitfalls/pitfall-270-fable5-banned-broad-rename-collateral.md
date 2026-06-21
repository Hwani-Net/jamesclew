---
slug: pitfall-270-fable5-banned-broad-rename-collateral
title: "Fable 5 금지 → Opus 4.8 복귀 + 광범위 모델명 rename의 사실 참조 손상"
symptom: "Fable 5가 대표님 금지 모델인데 STICKY·CLAUDE.md·rules·commands 28곳이 '메인=Fable 5'로 기술 → 다음 세션이 금지 모델 사용 시도 위험. 정정 중 broad sed claude-fable-5→claude-opus-4-8가 폐기표 금지 모델명·버전 changelog 사실(출시 모델 ID)까지 손상."
tags: [model-migration, fable-5, banned-model, sticky, broad-rename, sed-collateral, bash-mount-desync]
date: 2026-06-21
severity: high
related: [pitfall-259-fable5-adoption-harness-diet-stale-model-anchors, pitfall-256-deploy-claude-md-oneway-overwrite-manual-undeployed]
---

## 증상
2026-06-21 대표님: "Opus 4.8, GPT-5.5다. Fable 5는 금지되서 사용 못해." 그러나 2026-06-11 'Fable 5 채택' 결정(P-259)이 STICKY 모델 티어 표 + CLAUDE.md/rules/commands 28곳에 `현 Fable 5`/`claude-fable-5[1m]`로 박혀 있어 다음 세션이 금지 모델로 자기인식·라우팅할 위험. 추가로 에이전트가 "Fable 5로 갱신하겠다"고 제안(금지 사실 모름).

## 원인
1. **모델 현황을 stale 문서로 가정**: 에이전트가 "현행=Fable 5"를 CLAUDE.md STICKY에서 읽고 그대로 신뢰. 실제는 Opus 4.8 + Fable 금지.
2. **광범위 rename 부수 손상**: 정정 시 `sed claude-fable-5→claude-opus-4-8`를 전 파일 적용 → 운영 참조는 맞게 바뀌었으나 **폐기 표의 '금지 모델명'(claude-fable-5여야 함)**과 **버전 changelog 사실(v2.1.170 출시 모델 ID)**까지 치환해 자기모순("Fable 5 출시 … claude-opus-4-8 GA") 생성.
3. **bash 마운트 ↔ 파일툴 view 데스싱크**: 검증용 grep(샌드박스 bash)이 빈 결과 반환했으나 파일툴 Grep/Read엔 매치 존재 → bash mount가 권위 파일과 일시 불일치.

## 해결 (2026-06-21)
1. STICKY 폐기 표에 **Claude Fable 5(`claude-fable-5`) 금지** 등록 + 모델 티어 결정행 → 메인 `claude-opus-4-8`, Codex=GPT-5.5.
2. inline `현 Fable 5`→`현 Opus 4.8` 스윕 (rules/·commands/ 0건 확인).
3. sed 부작용 2곳 복구: 폐기표 금지 모델명 + changelog 사실(claude-fable-5 + 금지 주석).
4. codex-vision Opus 4.7→4.8, 매뉴얼 헤더 정정. deploy.sh 배포 + 라이브 검증(`현 Fable 5` 0, 금지 결정행 1, `현 Opus 4.8` 8).

## 재발 방지
1. **모델 현황 = 대표님/실측 확인, 문서 가정 금지.** STICKY가 곧 진실이 아니라 정정 대상일 수 있음.
2. **광범위 rename 전 스코프 3종 구분**: 모델 ID 문자열 = (a)운영 참조 / (b)폐기·금지 기록 / (c)버전 사실(history). (b)(c)는 보존. rename 후 자기모순 grep 필수.
3. **하네스 파일 검증은 파일툴 Grep/Read 기준** (bash mount 데스싱크 가능).
4. 모델 전환은 STICKY 1곳 + 역할기반 `메인 모델(현 X)` 일반화로 (P-259 교훈 유효, 단 'Fable 채택' 전제는 무효).
