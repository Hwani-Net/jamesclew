---
slug: pitfall-271-sandbox-mount-desync-from-authoritative-file
date: 2026-06-22
severity: medium
tags: [cowork, sandbox, bash-mount, file-desync, verification, windows-global]
related: [pitfall-256-deploy-claude-md-oneway-overwrite-manual-undeployed]
---

# P-271: Cowork 샌드박스 bash 마운트가 권위 Windows 파일과 간헐 데스싱크

## 증상
Cowork에서 파일툴(Edit/Write)로 수정한 직후, 샌드박스 bash(`mcp__workspace__bash`)로 grep/cat/실행하면 **stale 내용**이거나 **존재하는 매치를 0건** 반환. 본 세션 3회:
1. CLAUDE.md Fable grep → 0건(실제 존재, 파일툴 Grep은 정상 표시)
2. gstack `~/.claude/skills` 미검출(서브에이전트) — Windows 글로벌 미마운트 탓
3. `task-checkpoint.sh` 샌드박스 bash "syntax error: unexpected EOF" vs 파일툴 Read 정상 + git-bash `bash -n` SYNTAX_OK

## 원인
- Cowork **파일툴(Read/Write/Edit/Grep)** ↔ **샌드박스 bash 마운트(`/sessions/.../mnt/`)** 는 별개 동기화 레이어 → 쓰기 전파 지연·불일치 가능(시스템 프롬프트도 "file tools and shell may use different paths" 명시).
- 샌드박스는 **Windows 글로벌 경로(C:\Users\…\.claude, ~/.codex 등) 미마운트** → 거기 파일을 "없음"으로 오판. 서브에이전트도 동일 한계(D:\jamesclew 마운트만 봄).

## 해결 / 재발 방지
1. **하네스 파일 검증은 권위 뷰**: 파일툴 **Grep/Read** 또는 **git-bash**(`& "C:\Program Files\Git\bin\bash.exe" -lc "…"`, Windows 실파일). 샌드박스 bash 결과가 파일툴과 어긋나면 **파일툴/git-bash 신뢰**.
2. 샌드박스 bash "syntax error / 0건 / 없음"이 파일툴 Read와 모순 → **데스싱크 의심**, git-bash 재확인.
3. **Windows 글로벌(~/.claude, ~/.codex) 존재 확인은 PowerShell**로 — 샌드박스/서브에이전트 불가.
4. 쓰기·검증은 한 계열로 일관(파일툴 또는 git-bash); 혼용 시 검증 꼬임.

## 관련
- 시스템 프롬프트 "prefer file tools over shell for file ops"
- P-256(소스↔배포 동기화)
