---
title: pitfall-161 — VS Code/Antigravity extension 두 버전 공존 시 옛 버전이 fallback 활성화돼 신 패치 안 보임
slug: pitfall-161-vscode-extension-dual-version-old-fallback
date: 2026-05-17
tier: distilled
tags: [vscode, antigravity, extension, version-conflict, obsolete, command-palette, patch]
---

## 증상

VS Code/Antigravity extension의 `out/extension.js` 또는 `package.json`을 수정·패치한 뒤 Reload Window를 해도:
- Command Palette에 새 명령이 안 나타남
- 새 설정 키가 settings.json 자동완성에 안 보임
- 새 메뉴 항목이 contributes에 등록됐는데 UI에 안 보임

`out/extension.js`에서 grep으로는 `registerCommand("X.newCmd", ...)` 정상 발견. `package.json`의 `contributes.commands`에 항목 추가됐고 JSON parse OK.

## 원인

같은 publisher.name의 extension이 **두 개 이상 버전 공존**:

```
C:/Users/USER/.antigravity/extensions/
  ├── publisher.name-2.89.58-universal/   ← 옛 버전 (디스플레이 이름)
  │   └── package.json: version=2.89.77   ← 실제 내부 버전 (디렉토리 이름과 다를 수 있음)
  └── publisher.name-2.89.157-universal/  ← 새 버전 (패치된 것)
```

`.obsolete` 파일이 옛 버전을 `obsolete: true`로 마킹해도 디렉토리 자체가 남아있으면 Antigravity/VSCode가 fallback으로 로드하는 경우 발견. 특히:

- 새 버전 activate가 어떤 이유로 실패하면 옛 버전 fallback
- 새 버전의 `engines.vscode` 호환성 미달 시 옛 버전 fallback
- extension host 캐시가 stale (예전 manifest 보유)

옛 버전엔 우리 패치 없음 → 명령 안 나타남.

## 해결

### 1차 — 옛 버전 디렉토리 비활성화 (즉시 효과)
```bash
cd C:/Users/USER/.antigravity/extensions
mv publisher.name-OLD-VERSION-universal _DISABLED_publisher.name-OLD-VERSION-universal-bak
```

이름 변경만으로 충분 (Antigravity가 `publisher.name-` prefix로만 검색). 백업 의미로 `_DISABLED_` prefix + `-bak` suffix.

### 2차 — Reload Window 또는 Antigravity 완전 재시작
```
Ctrl+Shift+P → "Reload Window"
또는 Antigravity 프로세스 완전 종료 후 재실행
```

### 3차 — 검증
```
Ctrl+Shift+P → "Developer: Show Running Extensions"
→ publisher.name 항목이 1개만 보여야 정상
```

## 재발 방지

1. **Extension 패치 전 디렉토리 목록 확인** — `ls .antigravity/extensions/ | grep publisher.name` 으로 중복 버전 사전 점검.
2. **여러 버전 있으면 패치 전에 옛 버전 비활성화** — 패치 후 명령 안 보이는 디버그 시간 절약.
3. **`.obsolete` 파일은 신뢰하지 말 것** — Antigravity가 obsolete 마킹과 별개로 fallback 가능.
4. **디렉토리 이름 vs 내부 버전 불일치 인지** — `2.89.58-universal` 디렉토리가 실제로는 `package.json: 2.89.77` 일 수 있음. 둘 다 확인.
5. **패치 후 검증 순서**:
   a. JSON syntax (BOM 없는지, parse 가능한지) → pitfall-160
   b. extension.js syntax (`node --check`)
   c. 중복 버전 비활성화
   d. Reload Window
   e. Developer: Show Running Extensions에서 1개만 활성 확인

## 관련 실제 사례

2026-05-17 Connect AI Lab v2.89.157에 selectEngineProfile 명령 패치 후 Command Palette에 안 보임. 원인은 옛 버전 디렉토리(`2.89.58-universal/` 내부 version=2.89.77, commands=19) 공존. `.obsolete`에 `2.89.77: true` 마킹돼 있었으나 디렉토리 남아있어 fallback. `_DISABLED_` rename 후 Reload로 해결.

## 관련 pitfall

- [[pitfall-160-powershell-set-content-utf8-adds-bom]] — 같은 패치 작업의 다른 원인
- [[pitfall-159-agent-prompt-md-not-loaded-hardcoded-persona]]
