---
title: Windows Git Bash 에서 gbrain put stdin redirect 실패 (/dev/stdin 미지원)
date: 2026-04-24
severity: P1
project: harness
tags: [gbrain, hook, session-learning, windows, stdin, platform-compat]
---

## 증상
Windows Git Bash 에서 다음 두 패턴 모두 실패:
```bash
gbrain put slug < file.md                    # ENOENT: no such file or directory, open '/dev/stdin'
cat file.md | gbrain put slug                # 동일 에러
```

반면 `gbrain put slug --content "$VAR"` 는 multi-line (줄바꿈·백틱·따옴표) 모두 무결하게 저장됨 (실증 검증 완료).

## 원인
- gbrain (Node.js 기반) 이 `/dev/stdin` 경로를 파일 시스템 open 으로 접근 시도
- Windows Git Bash (MSYS) 는 `/dev/stdin` 가상 경로를 실제 파일로 제공하지 않음 → `fs.openSync` ENOENT
- macOS/Linux 에서는 정상 동작 (POSIX `/dev/stdin` 존재)

## 과거 오해 (정정)
- 초기 CLAUDE.md/quality.md 규칙에 "gbrain put --content multi-line 깨짐 — 절대 금지" 명시됐으나,
- 실제 검증 결과 `--content` 방식은 multi-line 완벽 보존 (백틱·따옴표·줄바꿈 모두 확인)
- "깨짐" 증상은 재현 안 됨. 금지 규칙은 실증 없이 적용된 것

## 영향
- session-learning.sh 를 stdin redirect 방식으로 수정했을 때 Windows 환경에서 **매 세션 학습 내용이 gbrain 에 저장 안 됨**
- 로컬 백업은 유지되지만 gbrain recall 불가 → 세컨브레인 Search-Before-Solve 원칙 훼손

## 해결
- session-learning.sh 를 `gbrain put "$SLUG" --content "$CONTENT"` 방식으로 복원
- quality.md 의 "gbrain put --content 금지" 규칙 정정: Windows 에서는 **유일하게 동작하는 방식**
- macOS/Linux 에서는 stdin redirect 와 --content 둘 다 가능 → 환경 무관하게 --content 사용 권장 (호환성 최우선)

## 재발 방지
1. **플랫폼 의존 규칙 금지**: 하네스 규칙에 "금지/권장" 표시할 때 실제 환경(Windows Git Bash)에서 검증 없이 확산 금지
2. **실증 우선**: "이론상 안 좋다" 가 아니라 "실제 증상 발견 후" 규칙 수립
3. audit-session.sh 가 "gbrain put --content 사용 검출 시 FAIL" 로직을 넣지 **않도록** 주의 — 이 패턴이 오히려 올바름
4. hook 수정 후 반드시 mock 데이터로 실제 실행 검증 (파일 생성 확인 ≠ 기능 동작 확인)
