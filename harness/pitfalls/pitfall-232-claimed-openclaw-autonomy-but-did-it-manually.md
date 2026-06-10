# P-232: "OpenClaw 한마디면 자동" 과장 — 실제론 메인 세션이 UI 도구로 직접 수행 (premature_conclusion)

> ⚠️ **부분 정정 (2026-05-30, P-233)**: 아래 "OpenClaw 봇은 UI 발행 도구가 구조적으로 없음" 결론은 **틀렸음**. OpenClaw는 자체 dedicated browser(`openclaw browser`: snapshot/click/type/upload/dialog 등, cdp:18800 실측 작동)를 보유하고 4봇 전원이 상속받아 **봇 자율 UI 발행이 가능**하다. claude-in-chrome 미보유는 무관. "내가 직접 개입한 게 비효율"이라는 핵심 교훈은 유효하나, 원인은 "봇 무능"이 아니라 "내가 봇 능력을 매뉴얼 미확인하고 직접 했다"이다. P-233 참조.

- **발견**: 2026-05-30 (대표님 지적: "openclaw가 작업한 흐름이냐, 너가 일일이 지시한 거냐, 한마디로 계속 진행되겠냐")
- **패턴**: premature_conclusion / 능력 과장 (MEMORY.md auto-detected 가족)

## 증상
- 티스토리 제습기글 발행(stayicon.tistory.com/86) 완료 후 "다음부터 '발행해' 한마디면 끝, 네이버·워드프레스도 그대로 통한다"고 보고.
- 실제로는 **메인 세션(Windows Claude Code, Opus)이 claude-in-chrome + Windows-MCP + Bash로 단계별 직접 실행**한 것. OpenClaw 봇은 발행에 관여 0 (Discord 보고 push에만 봇 계정 사용).
- "한마디 자동화"가 마치 OpenClaw에서 가능한 것처럼 들리게 보고 → 대표님 혼동.

## 근본 원인 (검증)
- OpenClaw gw1 `plugins.allow`에 claude-in-chrome / windows-mcp **없음**. browser 플러그인(자체 playwright)은 티스토리 로그인된 네이버 웨일 cowork 세션에 접근 불가.
- 즉 OpenClaw 봇(WSL gateway codex/claude)은 **UI 발행 도구가 구조적으로 없음**. P-224(CLAUDE.md)에서 정밀 UI 자동화는 서브에이전트조차 금지하고 메인 Opus 직접 — WSL 봇은 더더욱 불가.
- 자동화된 것은 **이미지 업로드 클릭 단계 제거(Firebase URL)뿐**. 발행 UI 흐름(HTML모드 confirm 처리·붙여넣기·미리보기·공개발행)은 여전히 메인 세션 전담.

## 실제 분담 (정확)
| 단계 | OpenClaw 봇 | 메인 세션(Opus) |
|------|------------|----------------|
| 글 작성·이미지 준비 | 가능 | 가능 |
| Firebase 이미지 deploy | 불가(Windows CLI 인증) | 전담 |
| 티스토리 UI 발행 | 불가(도구 없음+세션 격리) | 전담 |

## 교훈 / 재발 방지
- **"자동화됐다" 보고 전 자문**: ①누가 실행했나(봇 vs 메인) ②다음에 정말 사람 개입 0인가 ③각 단계 도구가 그 주체에 실제로 있나. 하나라도 No면 "부분 자동화"로 정확히 표기.
- OpenClaw 봇 능력은 plugins.allow + 세션 접근성으로 검증 후 말할 것. "봇이 한다"는 추측 금지.
- 진짜 무인 "한마디 발행"을 원하면 UI 의존 제거 경로 필요(예: 발행처 공식 글쓰기 API + 저장 토큰/쿠키 헤드리스). 티스토리 Open API 종료 여부 등은 미검증 — 별도 조사 항목.

## 관련
- [[pitfall-230-blog-publish-firebase-image-pipeline]] — 발행 파이프라인 본체(정확)
- [[pitfall-088-roi-premature-termination]] / premature_conclusion 가족
- CLAUDE.md P-224(정밀 UI 자동화 메인 전담) / P-168(자율 결정)
