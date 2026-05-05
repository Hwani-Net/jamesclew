# P-117: OneDrive Documents 동기화로 PowerShell `$PROFILE` 변경 손실 — Files On-Demand 가상화 충돌

- **발견**: 2026-05-05 (P-116 후속 — 옵션 A PowerShell wrapper 시도 중 발견)
- **프로젝트**: 하네스 자체 (대표님 환경 OneDrive 동기화)
- **사건 요약**: P-116 해결 옵션 A로 `Start-ClaudeOpus` function을 `$PROFILE` (PS5/PS7)에 추가. install 직후 같은 프로세스에서 verify 통과(Select-String hit). 그러나 즉시 외부 프로세스(`pwsh -Command "Get-Command Start-ClaudeOpus"`)에서 인식 실패 + raw bash `grep`도 0건. 원인: `$PROFILE`이 `C:\Users\AIcreator\OneDrive\문서\PowerShell\...`을 가리키며, OneDrive Files On-Demand 가상화로 install 프로세스 캐시 ≠ 클라우드 sync 본체. P-014/P-111 변형.

## 증상

1. **install 프로세스 내 verify는 통과**: `Add-Content` 후 같은 프로세스에서 `Select-String`으로 추가한 block 확인됨
2. **외부 프로세스에선 보이지 않음**: 새 `pwsh` 프로세스에서 `Get-Command Start-ClaudeOpus` → `[FAIL]`. raw bash `grep -c "Start-ClaudeOpus" "$PROFILE"` → `0`
3. **`Test-Path $PROFILE` 거짓 음성**: PS5의 경우 외부 프로세스에서 파일 자체가 `Exists: False`로 보고됨 (Files On-Demand placeholder 미materialize)
4. **PowerShell `$PROFILE` 자동 변수가 OneDrive 경로 가리킴**: Windows 11 + OneDrive Documents 백업 활성 환경에서 default

## 원인

1. **OneDrive Files On-Demand 가상화**: 로컬 변경 → 클라우드 sync 큐 → 클라우드 버전으로 placeholder 갱신 — 이 과정에서 변경 손실 또는 외부 프로세스 view 충돌
2. **PowerShell `$PROFILE` 경로**: `[Environment]::GetFolderPath("MyDocuments")` 결과가 OneDrive 동기화에 의해 `OneDrive\문서` 또는 `OneDrive\Documents`로 redirect됨
3. **한글 경로 추가 변수**: `OneDrive\문서` (Korean Personal folder) — UTF-8 콘솔 인코딩 미설정 시 추가 깨짐 가능성 (별개 문제)
4. **출처 검증**: Stack Overflow #74896830, GitHub PowerShell/PowerShell #19603, Stack Overflow #79744316 모두 동일 증상 보고

## 해결

### 권장: OneDrive 외부 batch wrapper + PATH 등록 (검증 완료)

```cmd
REM C:\Users\AIcreator\.harness\bin\claude-opus.cmd
@echo off
set "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=45"
set "CLAUDE_CODE_AUTO_COMPACT_WINDOW=1000000"
claude %*
```

```powershell
# User PATH 영구 등록
$harnessBin = 'C:\Users\AIcreator\.harness\bin'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not ($userPath -split ';' -contains $harnessBin)) {
    [Environment]::SetEnvironmentVariable('Path', "$userPath;$harnessBin", 'User')
}
```

**장점**:
- OneDrive 무관 (`.harness/` 외부 경로)
- PowerShell profile 의존 0
- cmd/PowerShell/Git Bash 모두에서 `claude-opus` 호출 가능
- 환경변수가 child 프로세스(claude)로 전파, parent shell 오염 없음

### 대안 1: OneDrive Documents 백업 비활성화

OneDrive 설정 → 백업 → Documents 동기화 해제. **위험**: 다른 sync 영향 + 사용자 환경 변경.

### 대안 2: Symbolic Link로 `$PROFILE` redirect

`mklink` 또는 `New-Item -ItemType SymbolicLink`로 OneDrive 외부 ps1 가리킴. 가능하나 OneDrive가 symlink 자체를 sync 시도할 위험.

### 대안 3 (이번 사건에서 선택): 옵션 B (`.claude/settings.local.json`)

프로젝트 폴더(jamesclew)는 git 관리 + OneDrive 외부면 무관. **실제 권장도는 batch wrapper(=옵션 A 변형)와 동등 또는 더 단순.**

## 재발 방지

1. **이 PITFALL을 SessionStart에 surface**: P-014, P-115, P-116과 함께
2. **PowerShell profile 수정 시 의무 사전 점검**:
   - [ ] `$PROFILE` 경로가 OneDrive 안인가?
   - [ ] 그렇다면 OneDrive 외부 wrapper로 우회
3. **install 스크립트 verify 강화**: 같은 프로세스 verify는 false positive 가능 → 외부 프로세스(`pwsh -NoProfile -Command "Test-Path ..."`)로 재검증
4. **CLAUDE.md Quality Gates 보강**: "사용자 환경 PowerShell profile 수정 전 — `$PROFILE` 경로의 OneDrive sync 여부 확인 + 외부 프로세스 cross-check"

## 관련 PITFALL

- P-014: 학습 데이터 의존 금지 — OneDrive 충돌은 추측이 아닌 검증으로 확인
- P-111: 코드 존재 ≠ 코드 동작 — `Add-Content` 성공 ≠ 외부 프로세스 인식
- P-116: 환경변수 모델별 분리 미지원 — 옵션 A의 전제
- P-115: REPL 전용 slash command — 자동 compact 트리거 메커니즘의 출발점

## 적용 위치

- 모든 사용자 PowerShell profile 수정 시도
- OneDrive Documents 백업 환경 (Windows 11 default)
- Files On-Demand 가상화 영향 받는 다른 폴더(Pictures, Desktop) 변경 시도

## 외부 검증

- Stack Overflow #74896830: `$profile` points to OneDrive's Documents on Windows 11
- GitHub PowerShell/PowerShell #19603: `$PROFILE` returns OneDrive path even after uninstall
- Stack Overflow #79744316: OneDrive changes local PowerShell file to its configuration
- 자체 검증: install 같은 프로세스 OK / 외부 프로세스 FAIL — sync race 직접 재현
