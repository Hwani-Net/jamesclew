---
slug: pitfall-124-extension-spawn-python-stdout-cp949
title: Connect AI extension Node spawn에서 Python 한국어 stdout이 CP949로 출력되어 Node UTF-8 디코드 실패
date: 2026-05-07
severity: high
status: resolved
tags: [connect-ai, extension, python, encoding, windows, node-spawn]
---

# Connect AI 도구 실행 시 한국어 출력 누락 — Python stdout CP949/Node UTF-8 mismatch

## 증상

사무실 모드에서 레오/Designer/Developer 등 에이전트가 도구(`my_videos_check.py` 등) 실행 시 UI에 다음 표시:

```
🔧 레오: my_videos_check.py 실행 중...
📺 레오 — my_videos_check.py 실행 실패
(출력 없음)
✕ exit 0
💡 흔한 원인: API 키 미설정, python3·필수 패키지 미설치
```

**exit 0인데 "실패"로 판정** + "(출력 없음)". 직접 `python3 my_videos_check.py` 실행하면 정상 출력 + exit 0.

## 데이터 기반 진단

`extension.js` L16061 `runCommandCaptured()` 함수:

```js
spawn(cmd, {
  cwd,
  shell: true,                    // Windows cmd.exe 경유 (active code page CP949)
  env: process.env,               // PYTHONIOENCODING 미설정
  stdio: ["ignore", "pipe", "pipe"]
});
child.stdout?.on("data", (d) => append2(d.toString()));   // d.toString() default: utf-8
```

**원인**:
1. Python이 default encoding (Windows cmd 환경에서 cp949)으로 stdout 출력
2. Node `Buffer.toString()`은 default utf-8 디코드 시도
3. 한국어 바이트 mismatch → invalid 바이트 → mojibake 또는 빈 string
4. extension UI: "(출력 없음) + exit 0 → 실행 실패" 판정

## 해결

`runCommandCaptured()`의 spawn env에 `PYTHONIOENCODING=utf-8 + PYTHONUTF8=1` 강제 주입:

```js
const __patchedEnv = Object.assign({}, process.env, {
  PYTHONIOENCODING: "utf-8",
  PYTHONUTF8: "1"
});
const child = spawn(cmd, { cwd, shell: true, env: __patchedEnv, stdio: ["ignore", "pipe", "pipe"] });
```

## 부수 발견

같은 시나리오 추적 중 **한국어 디렉토리 path 인코딩 문제**도 발견:
- `D:\AI 비즈니스\conneteailab` 경로 → Node spawn cwd 전달 시 mojibake
- 해결: `D:\conneteailab` junction 생성 (양방향 동일 데이터, 무손실)
- settings.json `localBrainPath` + `companyDir` 영어 path로 변경

## 재발 방지

1. `repatch-extension.ps1`에 P5 추가 — 자동 업데이트 시 PYTHONIOENCODING 패치 자동 재적용
2. 매시간 + 로그인 시 schtasks 트리거
3. 향후 새 spawn 호출 추가 시 동일 env 패턴 적용
4. 한국어 path는 영어 junction으로 우회

## 검증 사례

- 2026-05-07 14:30 — 사무실 모드 my_videos_check.py exit 0 + 출력 없음
- 2026-05-07 14:42 — 패치 적용 후 reload 검증 (대기)
- 직접 `python3 ...py` (bash) → UTF-8 환경이라 정상 작동 (extension cmd.exe와 차이)

## 관련 PITFALL

- pitfall-118-adapter-korean-stdout-encoding (어댑터 codex CLI stdout — 동일 원인 패턴)
