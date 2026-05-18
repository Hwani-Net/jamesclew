---
slug: pitfall-130-silent-stderr-spawn-debugging
title: "spawn captureStream='stdout'로 모든 fail이 '출력 없음 + exit 1' 침묵"
date: 2026-05-08
tags: [debugging, nodejs, python, spawn, stderr]
severity: critical
related: [pitfall-129-windows-cp949-stdout-reconfigure]
---

## 증상
어떤 도구가 fail해도 사용자에겐 항상 동일 메시지: `(출력 없음) + ❌ exit 1`. 진단 단서 0.

## 원인
Connect AI extension `_runShortcutTool` (extension.ts line 20632)이
`runCommandCaptured(..., "stdout")`로 호출 → child.stderr listener 미등록 → 자식이 stderr에만
traceback 출력하면 부모 buf 빈 채로 종료.

침묵하는 fail 종류: UnicodeEncodeError, ImportError, FileNotFoundError, 모든 raise·sys.exit.

부수 — Python on Windows + pipe stdout = block buffer (4KB) → 짧은 print는 종료 시 lost.

## 해결
```diff
- `python3 ${JSON.stringify(entry.tool)}`,
+ `python3 -u ${JSON.stringify(entry.tool)}`,   # unbuffered
  toolsDir, () => {}, 90000,
- "stdout",                                     # default 'both' 사용
```

## 디버깅 정정 이력 (자기교정)
이 함정 도달 전 *틀린* 가설 3개:
1. 자동 스케줄러 120s SIGTERM → 틀림 (별개 경로, 90s, timedOut=false)
2. 명령에 `.py` 누락 → 틀림 (catalog는 `.py` 포함)
3. stdout buffering → 부분 사실, 주 원인은 stderr 무시

**판별 기법**: 사용자 가시 메시지 문자열(`흔한 원인:`)을 Grep → caller 직행 → 5번째 인자 확인.
추측 쌓지 말고 메시지 문자열 → 코드 → 재현 순서로 좁힐 것.

## 재발 방지
- spawn wrapper의 captureStream을 'stdout'으로 좁히지 말 것 (stderr가 진단 1차 단서)
- DeprecationWarning 거슬리면 listener를 끊지 말고 출력 필터로 마스킹
- Python spawn은 `-u` 또는 `PYTHONUNBUFFERED=1` 기본
- fail 메시지에 `stdout_len`·`stderr_len` 메타 노출 권장

## 적용 (2026-05-08)
- extension.ts line 20632-20638 패치 → `npm run compile` (esbuild 384ms)
- active dist 교체: `connectailab.connect-ai-lab-2.89.58-universal/out/extension.js`
- 백업: `extension.js.repatch-bak-20260508-112634`
- `python3 -u` 패턴 dist 1회 매치 검증
- Antigravity Reload Window 후 사용자 검증 필요
