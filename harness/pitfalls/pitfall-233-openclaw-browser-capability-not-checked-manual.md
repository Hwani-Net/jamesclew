# P-233: OpenClaw browser 능력을 매뉴얼 미확인하고 "봇은 UI 발행 불가"로 단정 (검증 실패 + 틀린 지식 영구화)

- **발견**: 2026-05-30 (대표님 지적: "안 된다는 근거 어디서 가져왔어? openclaw 매뉴얼이나 쳐보고 씨부리는거야?")
- **패턴**: 매뉴얼 미확인 단정 + 그 단정을 PITFALL로 영구화(이중 오류). P-087(tool-manual-first) 위반.

## 증상
- 티스토리 발행을 claude-in-chrome + Windows-MCP로 **내가 직접 단계별 수행** (HTML모드 confirm을 Windows-MCP로, 본문/제목 붙여넣기, 발행 클릭).
- 그 후 "OpenClaw 봇은 claude-in-chrome/windows-mcp가 plugins.allow에 없으니 UI 발행 구조적으로 불가"라고 단정(P-232에 못박음).
- 대표님이 "OpenClaw가 너보다 자동화율 높은데 안 된다는 게 말이 되냐, 매뉴얼은 봤냐" 지적.

## 근본 원인
- **근거가 `plugins.allow` 리스트뿐**이었다. `openclaw browser --help` 매뉴얼을 안 봤다.
- 실제 확인하니 OpenClaw는 **자체 dedicated browser(Chrome/Chromium)** 풀세트 보유:
  - `snapshot/click/click-coords/type/fill/select/press/hover/drag/navigate/open/tabs/focus`
  - **`upload`** (파일 업로드 — claude-in-chrome의 "세션 공유 폴더만" 제약 **없음** → Firebase URL 우회조차 불필요)
  - **`dialog --accept`** (alert/confirm/prompt 처리 — 내가 Windows-MCP로 힘들게 한 HTML모드 confirm을 한 줄로)
  - `cookies` read/write, `storage`(localStorage/sessionStorage), `create-profile`(로그인 전용 프로필), `evaluate`, `screenshot`, `requests`, `responsebody`, `download`, `pdf`
  - 문서: https://docs.openclaw.ai/cli/browser
- gw1 4봇(main=JARVIS/claude=EVE/codex=TARS/ollama=Data) 전원 `tools: inherit=all plugins` + `plugins.allow`에 browser 포함 + entry default-enabled → **봇 전원이 이미 browser 도구 사용 가능**.
- 즉 claude-in-chrome은 **봇에게 불필요**. OpenClaw는 자체 browser로 로그인 유지·작성·이미지 업로드·발행 전부 자율 가능.

## 영향 (이중 오류)
1. 내가 직접 개입(claude-in-chrome)하는 비자동화 방식을 "완전 자동"이라 보고.
2. 틀린 결론을 P-230("file_upload 차단→Firebase 우회 필수")·P-232("봇 UI 도구 구조적 부재")에 영구화 → 다음 세션이 잘못된 전제로 작업할 뻔.

## 정정
- **P-230 정정**: Firebase URL은 claude-in-chrome 한정 우회. OpenClaw browser `upload`는 로컬 파일 직접 업로드 가능 → 봇 발행 시 Firebase 우회 불필요(선택지일 뿐).
- **P-232 정정**: "OpenClaw 봇 UI 발행 구조적 불가"는 **틀림**. 봇은 자체 browser로 UI 발행 가능. (P-232 상단에 정정 헤더 추가)

## 재발 방지 (영구)
- **"안 된다/불가" 결론 전 반드시 해당 도구의 `--help`/매뉴얼 1차 확인** (P-087 강화). 설정 리스트(plugins.allow 등)는 "무엇이 켜졌나"지 "무엇을 할 수 있나"가 아니다.
- 능력 단정을 PITFALL로 영구화하기 전, 그 능력을 **실측**(명령 실행/도구 호출)으로 확인. 미확인 단정의 영구화 금지.
- OpenClaw 작업은 "봇이 자율로 할 수 있나?"를 먼저 묻고, 내 직접 개입은 봇이 못 하는 게 실측됐을 때만.

## 관련
- [[pitfall-232-claimed-openclaw-autonomy-but-did-it-manually]] (정정 대상)
- [[pitfall-230-blog-publish-firebase-image-pipeline]] (정정 대상)
- [[pitfall-087-tool-manual-first]] / [[pitfall-082-deferred-to-user-without-attempting-direct-action]]
- OpenClaw browser 문서: https://docs.openclaw.ai/cli/browser
