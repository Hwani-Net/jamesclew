# P-242: WSLg Edge에 OS-paste(isTrusted) 입력 불가 — 봇(WSL) 완전자율 발행의 아키텍처 벽

> ✅✅ **해결 (2026-05-31) — OS-paste 자체가 불필요했음!** 봇 완전자율 발행 = **순수 CDP `tinymce.activeEditor.setContent(html)`** 로 가능. 입력도구(xdotool/wtype/ydotool/SendKeys) 전부 삽질이었고 불필요. **검증**: 실제 창문형 HTML(base64로 CORS 우회 주입) → `setContent` → 미리보기 **이미지2·표3·h2 8개 전부 렌더 + `<style>` 보존**. 제목은 `#post-title-inp` value+input이벤트, 발행은 "완료"/"공개 발행" dispatch click. **근본 통찰**: 티스토리 에디터=**TinyMCE**(전역 `tinymce`). HTML 모드 CodeMirror는 **소스뷰라 발행모델과 분리** → `CodeMirror.setValue`/OS-paste는 미동기화. 발행모델=`tinymce.activeEditor`라 `setContent`가 직접 동기화. P-238의 "OS-paste만 됨"은 CodeMirror 경로 한정 오해 — 기본모드 모델(tinymce) 직접 주입이 정답. **봇 발행은 WSLg 입력 한계와 무관하게 CDP만으로 완전 가능.** SendKeys(msrdc 윈도우 Windows interop)도 작동은 했으나(CodeMirror엔 들어감) 불필요.

- **발견**: 2026-05-31 (봇 완전자율 발행 STEP 1 — 입력도구 전수 검증)
- **영향**: 봇(WSL openclaw browser=WSLg Edge)이 티스토리 TinyMCE 소스뷰에 HTML을 OS-paste로 주입 불가. 발행은 isTrusted OS-paste 필수(P-238)인데 WSLg에서 모든 OS 키 입력 경로가 막힘. → 봇 완전자율 발행은 WSLg Edge 아키텍처로 불가.

## 검증 (전수 실측)
| 방법 | 결과 |
|------|------|
| `CodeMirror.setValue(html)` (CDP) | CodeMirror엔 들어가나 미리보기 빈 `<p><br></p>` — 티스토리 모델 미동기화 |
| `ClipboardEvent('paste')` dispatch (CDP) | isTrusted=false → 동일 미동기화 |
| `xdotool` 마우스 (mousemove/click) | ✅ 작동 (XWayland) |
| `xdotool` 키 (type/key ctrl+v) | ❌ WSLg XWayland 키 grab 안 먹음 (exit 0, 입력 0) |
| `xdotool key --window` (XSendEvent synthetic) | ❌ Chromium 무시 |
| `xdotool windowactivate` | ❌ WSLg `_NET_ACTIVE_WINDOW` 미지원 |
| `wtype` (Wayland virtual keyboard) | ❌ "Compositor does not support virtual keyboard protocol" (Weston) |
| `ydotool`+`ydotoold` (uinput, 빌드함) | ❌ exit 0이나 **mousemove조차 실제 마우스 안 움직임 → uinput이 WSLg Weston에 입력 디바이스로 미연결** |

## 근본 원인
- **WSLg = Windows↔Linux 입력 브릿지가 고정.** Weston 컴포지터가 Windows 입력만 받고, Linux 측 새 입력 디바이스(uinput)나 synthetic 키(XTEST/XSendEvent)를 입력으로 인식 안 함.
- xdotool 마우스만 작동하는 건 XWayland 포인터 경로가 별도라서. 키보드 grab/포커스는 Weston이 관리해 막힘.
- TinyMCE 소스뷰(CodeMirror)는 **isTrusted=true paste 이벤트**라야 티스토리 내부 모델 동기화(P-238). CDP/synthetic은 전부 isTrusted=false → 미동기화.

## 해결 방향 (아키텍처 — 대표님 결정 필요)
- **A. Windows 네이티브 브라우저 경로**: 봇이 Windows Chrome/Edge(9222 CDP, cdp-auto-ensure hook이 띄움)를 조작 + 봇 `powershell.exe` interop으로 Windows `SendKeys ^v`(isTrusted OS-paste). WSLg 아닌 Windows 입력이라 가능성. ★단 WSLg Edge(Linux msedge)는 Windows Get-Process에 안 잡힘 → 반드시 Windows 네이티브 브라우저여야.
- **B. 하이브리드**: 봇이 글감→작성→critic→발행자산(HTML/이미지/제목)까지 자율 + **발행 실행만 메인 세션 claude-in-chrome 웨일**(P-238 검증). 봇 95% 자율, 발행 5% 메인. "완전 개입0" 일부 양보.
- **C. 발행처 변경**: API 있는 플랫폼. 단 Firebase/티스토리 정책 충돌.

## 성과 (STEP 0은 성공)
- **봇 자율 로그인 = 성공** (P-237 해소). 카카오 `_kawlt` persistent로 봇이 대표님 개입 0 자동 로그인 (MouseEvent dispatch → 저장계정 클릭 → OAuth 통과 → `__T_` 재발급). 절차는 handoff-bot-autonomy-publish.md STEP 0.
- 막힌 건 발행 입력(OS-paste)뿐. 로그인·네비게이션·DOM조작(evaluate)·이미지생성·Firebase는 봇 자율 가능.

## 관련
- [[pitfall-238-openclaw-cdp-tinymce-source-paste-escape]] (OS-paste 필수 — 웨일 성공)
- [[pitfall-241-wsl-path-openclaw-points-stale-windows-518-binary]] (5.27 절대경로)
- [[pitfall-237-tistory-session-cookie-expires-on-restart]] (STEP 0 카카오 persistent 해소)
- handoff-bot-autonomy-publish.md (STEP 0 성공 절차 + STEP 1 차단)
