# P-238: openclaw browser(CDP)가 티스토리 TinyMCE 소스뷰에 HTML 주입 불가 — OS paste 필요

> ✅ **해결 확정 (2026-05-31)**: 이동식에어컨 글 **발행 성공** (https://stayicon.tistory.com/87). 해결책 = **claude-in-chrome 웨일(OS paste, `computer key ctrl+v`)**. 절차: ①웨일 cowork 탭에 티스토리 로그인 살아있음 확인(별도 세션) ②`navigate manage/newpost` → 이어쓰기 confirm freeze → **desktop-control `key Return`**으로 처리(웨일=Windows앱이라 desktop-control에 보임, WSLg Edge는 안 보임) ③기본모드→HTML 드롭다운 클릭 → HTML 전환 confirm도 desktop-control `key Return` ④HTML 코드에디터 클릭 + `computer key ctrl+v`(OS paste) → KEDITOR 정상 등록 ⑤제목란 `find`→ref→click+`ctrl+v` ⑥미리보기 렌더 확인(히어로 이미지 정상) ⑦완료→공개 발행. **openclaw browser는 발행에 부적합(CDP escape), claude-in-chrome 웨일이 정답.** 해결책 2(Windows-MCP)는 WSLg Edge 격리로 불가였으나, 웨일은 Windows앱이라 claude-in-chrome+desktop-control 조합으로 성공.

- **발견**: 2026-05-31 (이동식에어컨 글 발행 마지막 단계)
- **영향**: openclaw browser로 티스토리 HTML 발행이 본문 주입에서 막힘. 미리보기가 `<style>...` raw 텍스트로 표시.

## 증상
- openclaw 프로필(Edge) 로그인 OK, 제목 입력 OK, 이미지 OK. 본문만 안 들어감.
- HTML 모드(CodeMirror)에 HTML 주입 후 미리보기 = HTML이 렌더 안 되고 `<style>` 코드가 텍스트로 노출.

## 시도한 것 (전부 실패)
1. `press "Control+v"` (CDP 키 이벤트) → CodeMirror len=8903 들어가나 미리보기 raw.
2. `CodeMirror.setValue(html)` → raw.
3. `CodeMirror.save()` + input/change 이벤트 → textarea len=8903 동기화되나 raw.
4. `tinymce.activeEditor.setContent(html)` → len 8903→8648 (escape), raw.

## 근본 원인
- 티스토리 에디터 = **TinyMCE** ("POWERED BY TINY"). HTML 모드 = TinyMCE source-code 뷰(CodeMirror).
- TinyMCE 소스뷰에 raw HTML(`<style>`+`<main>` 구조 포함)을 넣으려면 **소스뷰의 네이티브 paste 핸들러**를 통과해야 HTML 코드로 인식됨.
- **claude-in-chrome `computer key ctrl+v` = OS 레벨 키보드 이벤트** → TinyMCE paste 핸들러 정상 트리거 → HTML 코드 인식 (제습기 P-230 성공).
- **openclaw browser `press Control+v` = CDP `Input.dispatchKeyEvent`** → 클립보드 paste 핸들러를 제대로 안 거치거나 텍스트로 삽입 → escape.
- `setContent`는 TinyMCE body 콘텐츠 API라 `<style>` 같은 head 요소를 strip/escape.

## 해결 (검증 대기)
1. **claude-in-chrome으로 발행** (제습기 검증 방식, OS paste) — 단 로그인이 openclaw Edge 프로필에 있어 claude-in-chrome(웨일)과 분리 → 웨일에 별도 로그인 필요.
2. **Windows-MCP로 WSLg Edge 창에 OS paste** — Edge 창 활성화 → HTML 에디터 클릭 → Windows-MCP Shortcut Ctrl+V (OS 레벨). WSLg Edge가 Windows-MCP Snapshot에 잡히는지 검증 필요.
3. **TinyMCE 소스뷰 적용 메커니즘** — CodeMirror에 raw HTML 후 "기본모드 전환" 시 TinyMCE가 소스 파싱하는지 (HTML 모드→기본 모드 토글). 미검증.
4. 차선: 발행 자체는 정상일 수 있으나(미리보기만 raw일 가능성) — **비가역이라 임시저장 후 비공개 라이브 확인**으로 안전 검증 후 공개.

## 재발 방지
- **openclaw browser(CDP)로 TinyMCE/리치에디터 소스뷰 HTML 발행은 기본적으로 막힘.** 텍스트 input(제목 등)은 base64 evaluate로 OK, 리치에디터 본문은 OS paste 필요.
- 발행 자동화는 **claude-in-chrome(OS paste) 우선**, openclaw browser는 로그인 세션 확보용으로 역할 분리 검토.
- P-230(claude-in-chrome 발행)과 P-234(openclaw 발행)의 차이가 여기서 드러남 — 본문 주입 방식이 핵심.

## 관련
- [[pitfall-230-blog-publish-firebase-image-pipeline]] (claude-in-chrome OS paste 성공)
- [[pitfall-234-openclaw-browser-headful-session-bot-autopublish]] (openclaw 로그인)
- [[pitfall-237-tistory-session-cookie-expires-on-restart]]
