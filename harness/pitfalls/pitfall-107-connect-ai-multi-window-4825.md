---
slug: pitfall-107-connect-ai-multi-window-4825
title: Connect AI 다중 창 4825 포트 EADDRINUSE 충돌 — 사이드바 cached state로 fallback
tags: [connect-ai, antigravity, multi-window, port-conflict, eaddrinuse]
date: 2026-05-04
---

# 증상
Antigravity를 닫고 다른 폴더에서 새 창 열면 Connect AI 사이드바 모델 dropdown에 **defaultModel(gpt-4.1) 1개만 표시**.
어댑터(4142)는 정상 가동 + 11개 모델 노출 중인데도 사이드바 fetch 안 함.
좌측 하단에 빨간 알림 "🚫 Connect AI Bridge: 포트 4825가 이미 사용 중입니다" 표시.

# 원인
Connect AI extension의 `server.listen(4825, "127.0.0.1", ...)` (extension.js L19293) 가 다중 인스턴스에서 충돌:
- 첫 Antigravity 창: 4825 listen 성공
- 두 번째 창부터: EADDRINUSE → `vscode.window.showErrorMessage()` 호출
- 사이드바 webview가 일부 에러 상태 → 모델 fetch도 영향 → cached defaultModel만 표시

원본 코드 (L19285):
```js
server.on("error", (err) => {
  const msg = err?.code === "EADDRINUSE"
    ? `🚫 Connect AI Bridge: 포트 4825가 이미 사용 중입니다...`
    : `🚫 Connect AI Bridge 시작 실패: ${err?.message || err}`;
  vscode.window.showErrorMessage(msg);
});
```

# 해결
extension.js의 `server.on("error")`에서 EADDRINUSE를 silently skip:
```js
server.on("error", (err) => {
  if (err?.code === "EADDRINUSE") {
    console.log("[Connect AI Bridge] port 4825 already in use — skip (multi-window OK)");
    return;
  }
  const msg = `🚫 Connect AI Bridge 시작 실패: ${err?.message || err}`;
  vscode.window.showErrorMessage(msg);
});
```

효과:
- 다중 Antigravity 창 동시 운영 OK
- A.U/EZER bridge는 첫 창만 동작 (현재 미사용 기능이라 무영향)
- 채팅/모델 fetch는 4142 어댑터 공유로 모든 창 정상

# 재발 방지
1. Connect AI extension 업데이트(v2.46.4+) 시 `patch_extension.ps1` 재실행 → 자동 패치 (수동 항목 안내)
2. 임시 워크어라운드: `Ctrl+Shift+P → Reload Window` (사이드바 강제 재초기화)
3. 어댑터 죽은 경우 별개 — `adapter_watchdog.py`가 NSSM 동등 자동 복구

# 관련 파일
- `D:/jamesclew/harness/scripts/connect-ai-adapter/patch_extension.ps1`
- `~/.antigravity/extensions/connectailab.connect-ai-lab-*-universal/out/extension.js` L19285
