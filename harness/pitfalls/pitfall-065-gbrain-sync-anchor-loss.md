---
title: gbrain import 시 sync anchor 손실로 full reimport 재발
date: 2026-04-24
severity: P2
project: harness
tags: [gbrain, sync, git, anchor, full-reimport, performance]
---

## 증상
`gbrain import D:/jamesclew/harness/pitfalls/` 실행 시 다음 로그 출력:
```
fatal: git cat-file: could not get object info
Sync anchor commit 564083de missing (force push?). Running full reimport.
```
427개 파일 전체 재임포트(약 100초 소요). 증분 sync가 아닌 매번 full scan.

## 원인
- gbrain은 git commit hash를 anchor 로 사용하여 증분 sync
- `git push --force` 또는 백업/리스토어 과정에서 이전 anchor commit이 원격/로컬에 더 이상 존재하지 않음
- gbrain이 anchor 소실 감지 → 안전하게 full reimport 로 폴백

## 영향
- 매 import 가 증분이 아닌 전체 처리 → 100초+ 소요
- 실제 변경 파일이 1-2개여도 전체 1078개 페이지 재처리
- 백업 리스토어 후 gbrain 이 수 분간 먹통

## 해결
- `gbrain sync --reset-anchor` 명령으로 현재 HEAD 에 anchor 재설정
- 또는 새 anchor 자동 감지 후 1회 full 이후 다시 증분으로 복귀 (현재 동작)

## 재발 방지
1. 리스토어 스크립트(`reset-and-install.sh`) 끝에 `gbrain sync --reset-anchor` 호출 추가
2. `git push --force` 수행 전 gbrain 상태 플래그 저장 → 이후 anchor 자동 갱신
3. gbrain integrations 설정으로 git hook에 anchor 자동 갱신 연결 검토
