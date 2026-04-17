---
type: pitfall
id: P-039
title: ".claude/ 루트 파일은 bypassPermissions로도 승인 프롬프트 우회 불가"
tags: [pitfall, jamesclew]
---

# P-039: .claude/ 루트 파일은 bypassPermissions로도 승인 프롬프트 우회 불가

- **발견**: 2026-04-17
- **증상**: defaultMode bypassPermissions + Edit(.claude/**) allow + skipDangerousModePermissionPrompt 모두 설정해도 .claude/PITFALLS.md 편집 시 매번 승인 프롬프트. .claude/commands/PITFALLS.md로 옮긴 후에도 sensitive file 검사로 여전히 발생
- **원인**: Claude Code v2.1.x 하드코딩 보호 디렉토리 (.claude, .git, .vscode, .idea, .husky)는 bypassPermissions로 우회 불가. .claude/commands 예외설은 부분만 맞고 sensitive file 2차 검사 (GitHub Issue #36192, #37029)
- **해결**: PITFALLS를 .claude/ 완전 외부로 이동. 최종 선택은 gbrain 인덱싱(파일 폐기, P-040 함께)
- **재발 방지**: 자율 편집 메모리 파일은 .claude/ 어떤 하위 폴더에도 두지 말 것. 외부 경로(harness/, .harness-state/) 또는 gbrain 사용
