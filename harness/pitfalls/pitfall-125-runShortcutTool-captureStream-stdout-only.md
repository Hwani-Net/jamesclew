---
slug: pitfall-125-runShortcutTool-captureStream-stdout-only
title: Connect AI _runShortcutTool이 stderr 출력 무시 — captureStream "stdout"으로 강제됨
date: 2026-05-07
severity: high
status: resolved
tags: [connect-ai, extension, stderr, capture, python-tools]
---

# Connect AI 도구가 stderr로 출력하는 진행 메시지를 extension이 무시

## 증상

사무실 모드 또는 메인 채팅에서 Python 도구(`my_videos_check.py` 등) 실행 시:
```
🔧 레오: my_videos_check.py 실행 중...
📺 레오 — my_videos_check.py 실행 실패
(출력 없음)
✕ exit 0
💡 흔한 원인: API 키 미설정, python3·필수 패키지 미설치
```

직접 실행하면 stderr로 출력됨:
```
[STDERR] 🔍 채널 정보 가져오는 중...
[STDERR] 🔍 최근 30일 영상 가져오는 중...
[STDERR] ⚠️  업로드된 영상이 없어요.
Exit 0, total output: 63 chars
```

## 데이터 기반 진단

`extension.js` L38130 `_runShortcutTool()`:

```js
r = await runCommandCaptured(
  `python3 ${JSON.stringify(entry.tool)}`,
  toolsDir,
  () => {},
  9e4,
  "stdout",   // ⚠️ stderr 무시
);
```

`runCommandCaptured` (L16061):
```js
child.stdout?.on("data", (d) => append2(d.toString()));
if (captureStream === "both") {                            // ⚠️ "stdout"이면 skip
  child.stderr?.on("data", (d) => append2(d.toString()));
}
```

**결과**: my_videos_check.py가 stderr로 출력 → extension이 stderr 이벤트 무시 → `r.output = ""` → `toolOk = (exitCode === 0 && output.length > 0)` = false → "실행 실패 (출력 없음)" UI 표시 (실제 exit 0).

## 해결

`_runShortcutTool` 호출의 `captureStream`을 `"stdout"` → `"both"`로 변경:

```js
r = await runCommandCaptured(
  `python3 ${JSON.stringify(entry.tool)}`,
  toolsDir, () => {}, 9e4,
  "both",   // ← stderr도 캡처
);
```

## 추적 경로 (잘못된 진단 회피용)

이 문제는 다음 가짜 단서를 따라가면 시간 낭비:
1. ❌ "gpt-4.1 모델이 작동 안 함" — 모델 호출은 정상, 도구 spawn 결과 문제
2. ❌ Python stdout 인코딩 (cp949 vs utf-8) — PYTHONIOENCODING 패치만으로 해결 안 됨 (stderr 자체를 무시하므로)
3. ❌ 한국어 path 문제 — junction 만들고 영어 path로 변경해도 해결 안 됨 (cwd는 정상이고 captureStream이 진짜 원인)

**진짜 원인은 항상 spawn에서 stdout만 캡처하고 stderr 버리는 것**. Node.js spawn에서 stderr 이벤트 listener 부재 시 출력 사라짐.

## 재발 방지

1. `repatch-extension.ps1`에 P6 추가 — 자동 업데이트 시 captureStream 패치 자동 재적용
2. 향후 새 도구 호출 추가 시 `captureStream="both"` 또는 default 사용 (default가 "both")
3. 도구 spawn 결과 진단 시 항상 stderr+stdout 둘 다 확인

## 검증 방법

extension과 100% 동일한 spawn으로 시뮬레이션:
```js
const { spawn } = require("child_process");
const child = spawn(`python3 my_videos_check.py`, {
  cwd: "D:/conneteailab/_agents/youtube/tools",
  shell: true,
  env: Object.assign({}, process.env, { PYTHONIOENCODING: "utf-8", PYTHONUTF8: "1" }),
  stdio: ["ignore", "pipe", "pipe"]
});
child.stdout.on("data", d => console.log("[STDOUT]", d.toString()));
child.stderr.on("data", d => console.log("[STDERR]", d.toString()));   // ← 이걸 봐야 진단 가능
```

stdout만 listener 있으면 stderr 출력은 영원히 안 보임 (Node 이벤트 모델).

## 검증 사례

- 2026-05-07 14:51 — extension reload 후에도 같은 증상 ("출력 없음")
- 2026-05-07 14:55 — Node spawn 시뮬레이션 — `[STDERR] 🔍 채널 정보...` 발견 (총 63 chars)
- 2026-05-07 14:57 — L38150 captureStream "stdout" → "both" 패치 + repatch script P6 추가

## 관련 PITFALL

- pitfall-118-adapter-korean-stdout-encoding (codex CLI stdout — 다른 인코딩 이슈)
- pitfall-124-extension-spawn-python-stdout-cp949 (Python stdout encoding — 같은 도구 호출 추적 중 부수 발견)
