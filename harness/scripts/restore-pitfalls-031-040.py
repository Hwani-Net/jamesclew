"""
Restore P-031 ~ P-040 to gbrain (lost in earlier migration).
Bodies reconstructed from this conversation's system-reminders.
"""
import re
import subprocess
import sys

GBRAIN = "C:/Users/AIcreator/AppData/Roaming/npm/gbrain.cmd"


def slugify(text: str, max_words: int = 5) -> str:
    cleaned = re.sub(r"[^\w\s-]", " ", text, flags=re.UNICODE)
    words = []
    for w in cleaned.lower().split():
        ascii_only = re.sub(r"[^a-z0-9-]", "", w)
        if ascii_only and len(ascii_only) > 1:
            words.append(ascii_only)
    return "-".join(words[:max_words]) if words else "untitled"


PITFALLS = [
    (31, "Git Bash에서 cmd /c npx 호출 시 /c가 C:/로 자동 변환",
     """- **발견**: 2026-04-17
- **증상**: `claude mcp add wikipedia -s user -- cmd /c npx -y <pkg>` 실행 후 `claude mcp list`에 `cmd C:/ npx ...`로 등록됨 → Failed to connect
- **원인**: Git Bash(MSYS2)의 자동 경로 변환 기능이 POSIX 스타일 `/c`를 Windows 경로 `C:/`로 오인해서 바꿈. stitch 등 기존에 등록된 서버는 다른 셸(PowerShell/cmd.exe)에서 등록됐거나 타이밍상 변환이 안 일어난 것으로 추정
- **해결**: `MSYS_NO_PATHCONV=1 claude mcp add ... -- cmd /c npx ...` 로 prefix env var 적용. 변환 완전 차단됨
- **재발 방지**: Windows Git Bash에서 `claude mcp add --` 뒤에 Windows 절대경로·옵션 플래그(`/c`, `/k` 등)가 오면 반드시 `MSYS_NO_PATHCONV=1` prefix 사용. 하네스 스크립트·문서에 명시"""),

    (32, "Perplexity API 최소 충전 $50 — 검색용으로 과도한 비용",
     """- **발견**: 2026-04-17
- **증상**: API 크레딧 탑업 모달에서 "$5" 입력 시 "최소 $50 이상" 에러. 팩트 검증 용도로 $50은 ROI 낮음
- **원인**: Perplexity API 플랜 정책이 최소 충전 $50. `$0.006/search`로 단가는 저렴하지만 진입 문턱이 높음. 하네스는 주로 팩트 검증용이라 월 $50 소진도 어려움
- **해결**: Perplexity MCP 제거. 무료 대체 스택 구축:
  - Tavily (6키 로테이션, 월 ~6000회 무료) — 일반 웹 검색 1순위
  - DuckDuckGo MCP (`duckduckgo-websearch`, 무키·무제한) — 백업
  - Wikipedia MCP (`wikipedia-mcp`, 무키) — 확정 팩트 (인물·역사·지명·과학)
  - NotebookLM (무료) — 소스 누적 지식 베이스
- **재발 방지**: 검색·팩트 용도 API는 "최소 충전 금액" 반드시 사전 확인. 무료 MCP 스택을 기본으로 설계, 유료는 필요 시점에만 검토"""),

    (33, "Tavily 로테이터 코드 수정 시 MCP 서버 재시작 필수",
     """- **발견**: 2026-04-17
- **증상**: `tavily-rotator.mjs`에 432 처리 추가 후에도 "This request exceeds your plan's set usage limit" 에러 발생. 6키 중 5개가 살아있는데도 로테이션 안 됨
- **원인**: MCP 서버는 Claude Code 시작 시 한 번만 로드됨. 세션 중 로테이터 파일을 수정해도 실행 중인 node 프로세스는 이전 버전 사용. 파일 수정 시각(13:04) > MCP 프로세스 시작 시각(10:11)이면 구버전이 돌고 있는 것
- **해결**:
  1. 로테이터 수정 후 Claude Code CLI 재시작 (가장 확실)
  2. 또는 해당 node 프로세스만 kill → Claude Code가 자동 재생성 (위험: 다른 MCP 서버도 node.exe라 식별 어려움)
  3. 세션 중 임시 대체: DuckDuckGo MCP, WebSearch, Wikipedia MCP
- **재발 방지**: 로테이터/MCP 프록시 파일 수정 시 반드시 "재시작 필요" 경고 출력. session-start hook에 "MCP 프로세스 시작 시간 vs 주요 MCP 파일 mtime 비교" 체크 추가 검토"""),

    (34, "MusicGen CC-BY-NC 4.0 — 상업 유튜브 사용 금지",
     """- **발견**: 2026-04-17
- **증상**: Meta MusicGen/AudioCraft 가중치가 CC-BY-NC 4.0 라이선스. "오픈소스 AI 음악 생성"이라고 검색 시 최상위로 뜨지만 **비상업 전용**. 상업 유튜브 채널/광고에 사용 시 라이선스 위반
- **원인**: Meta는 MusicGen 코드는 MIT로 공개했으나 학습된 가중치는 CC-BY-NC로 제한. 많은 블로그/튜토리얼이 이 점을 언급하지 않음
- **해결**:
  1. **Stable Audio Open** (Stability Community License, 상업 사용 허용) 1순위
  2. **Pixabay Music** + **YouTube Audio Library** (완전 무료, 상업 OK)
  3. AudioGen (Meta, MusicGen과 같은 AudioCraft 스택 — **같은 비상업 제약 적용**, 금지)
- **재발 방지**: 오픈소스 라이선스 조사 시 "코드 라이선스"와 "가중치 라이선스" 분리 확인. Apache/MIT ≠ 상업 사용 가능 (가중치는 별도)"""),

    (35, "Meta Developer 등록 이메일 코드 차단 — \"평소 사용하지 않는 기기\" 보안 락",
     """- **발견**: 2026-04-17
- **증상**: developers.facebook.com 등록 다이얼로그 Contact info 단계. admin@gpt-korea.com으로 이메일 코드 발송·입력까지 정상, 그러나 "현재 이 변경 사항을 적용할 수 없습니다 / 평소에 사용하지 않는 기기를 사용 중이신 것으로 확인되어 계정 안전을 위한 조치를 적용해야 합니다. 이 기기를 잠시 사용한 후에 이 설정을 변경할 수 있습니다" 팝업으로 차단. 이메일 업데이트 버튼도 동일 이유로 차단됨
- **원인**: Meta는 계정 보안 정책상 "신뢰 기기"에서만 Developer 등록 완료 허용. 새 Chrome 프로필·새 IP·최근 대량 로그인 시도 등이 트리거. **메모리의 "SMS 5회 실패"는 이 기기 락의 이전 증상** — 실제 요구는 SMS가 아니라 기기 신뢰 확보였음
- **해결**: 24-48시간 동일 기기에서 일반 Facebook 사용(피드 열람, 메시지 등)으로 기기 신뢰 점수 누적. 그 후 재시도. 즉시 우회 경로 없음 (다른 번호/VoIP/카드 인증 모두 동일 락에서 차단)
- **재발 방지**:
  1. 새 Meta 계정 생성 또는 Developer 등록 **전**에 해당 기기에서 최소 1일간 일반 Facebook 활동 먼저 수행
  2. "SMS 실패" 또는 "인증 차단" 보고 시 스크린샷 원문 확인 — 실제 원인이 SMS인지, 이메일 코드인지, 기기 락인지 구분
  3. Meta 블로커 상태에서는 B/D/E 의존 작업 보류하고 C(이미지 교체) 등 독립 작업으로 전환"""),

    (36, "영상 렌더 검증을 메타데이터만으로 판정 — 프레임 실측 없이 \"성공\" 보고",
     """- **발견**: 2026-04-17
- **증상**: VideoStudio 첫 숏츠 렌더 후 "검증 완료 ✅, YouTube Shorts 업로드 가능"으로 보고. 대표님이 실제 재생해보니 전부 "[B-roll placeholder]" 회색 텍스트 + 자막 박스만 있는 개판 영상. B-roll 미생성 상태에서 템플릿 플레이스홀더만 노출됨
- **원인**: 검증 범위가 (1) 파일 존재 (2) ffprobe 메타 (1080×1920, H.264, 59초, AAC) (3) 빌드 성공 로그에 국한. **프레임을 Read 도구로 한 번도 시각 확인 안 함.** 오디오 재생도 안 함
- **해결**:
  1. 렌더 후 반드시 `ffmpeg -vf fps=1/5 frames/frame_%02d.png`로 5초 간격 프레임 추출 + 최소 5장 Read로 시각 검증
  2. 훅 오버레이(첫 3초), scene별 배경 차이, 자막 위치, 전환 효과 모두 눈으로 확인
  3. AI B-roll이 아직 없으면 "placeholder 상태로 렌더 테스트만 통과, 업로드 불가" 명시
- **재발 방지**:
  - CLAUDE.md quality.md에 이미 "저장 후 Read로 이미지 내용 확인" 규칙 있음 (P-002 파생). 영상에도 동일 규칙 적용 명시 필요
  - regression-autotest.sh 또는 별도 hook에 "mp4 렌더 후 자동 프레임 추출 + 첫/중간/끝 프레임 Read 강제" 추가 검토
  - "빌드 성공 ≠ 콘텐츠 품질" — 메타데이터 검증과 시각 검증을 분리해서 양쪽 다 통과해야 PASS"""),

    (37, "FLUX.1 시리즈는 HuggingFace gated repo — 토큰 없이 다운로드 불가",
     """- **발견**: 2026-04-17
- **증상**: `black-forest-labs/FLUX.1-schnell` 다운로드 시 `GatedRepoError 401: Access to model is restricted. You must have access to it and be authenticated to access it. Please log in.`
- **원인**: Black Forest Labs가 FLUX.1-schnell / FLUX.1-dev 모두 2025년경부터 HF gated repo로 전환. 라이선스(Apache 2.0) 자체는 그대로지만 다운로드 경로가 HF 로그인 + 모델 카드 동의 후 가능
- **해결**:
  1. HF 계정 생성 → `huggingface.co/black-forest-labs/FLUX.1-schnell` "Agree and access" 클릭 → 토큰 발급 → `huggingface-cli login` 또는 `HF_TOKEN=xxx` 환경변수
  2. **게이트 없는 대체**: Stable Diffusion XL (`stabilityai/stable-diffusion-xl-base-1.0`) — 완전 공개, 로고 생성 가능, 텍스트 렌더링은 약함
  3. **SD 3.5 Medium**: `stabilityai/stable-diffusion-3.5-medium` — 더 최신이지만 역시 gated일 수 있음
  4. **Kolors / PixArt-Sigma / AuraFlow**: 완전 오픈, 게이트 없음
- **재발 방지**: HuggingFace 모델 사용 전 `huggingface.co/<repo>` 페이지에서 "You need to agree..." 문구 확인. Apache/MIT 코드 라이선스 ≠ 가중치 다운로드 자유 (P-034와 같은 맥락)"""),

    (38, "Google Cloud Console OAuth UI 2025 개편 — \"OAuth 동의 화면\" → \"Google 인증 플랫폼\"",
     """- **발견**: 2026-04-17
- **증상**: "OAuth 동의 화면 → External → 테스트 사용자 추가" 가이드 제공 후 대표님이 Step 3에서 막힘. 실제 화면에는 "브랜딩 / 대상 / 클라이언트 / 데이터 액세스 / 인증 센터 / 설정" 메뉴로 구성되어 있고 "테스트 사용자" 섹션이 안 보임
- **원인**: Google이 2025년 중반에 Google Cloud Console OAuth 섹션을 대대적으로 개편. 구 "OAuth consent screen"이 "Google 인증 플랫폼"으로 이름 바뀌고 탭 구조로 분리:
  - **브랜딩**: 앱 이름, 로고, 지원 이메일
  - **대상**: 외부/내부 + 게시 상태 (프로덕션/테스트) + 테스트 사용자
  - **클라이언트**: OAuth 클라이언트 ID 생성 (구 "사용자 인증 정보" 메뉴)
- **추가 발견**: 프로젝트가 이미 "프로덕션 단계"면 테스트 사용자 추가 불필요. 누구나 OAuth 동의 가능
- **해결**:
  1. 가이드 작성 시 현재 UI 용어 사용: "Google 인증 플랫폼 → 클라이언트 → + 클라이언트 만들기 → 데스크톱 앱"
  2. 프로덕션 단계 프로젝트 재사용 시 테스트 사용자 Step 생략 가능
  3. 새 프로젝트면 "대상" 탭에서 "외부" + 테스트 사용자로 본인 이메일 추가
- **재발 방지**: 2025 이후 Google/Anthropic/MS 콘솔 UI 개편 잦음. 가이드 작성 전 실제 URL `console.cloud.google.com/auth/*`로 현재 UI 확인"""),

    (39, ".claude/ 루트 파일은 bypassPermissions로도 승인 프롬프트 우회 불가",
     """- **발견**: 2026-04-17
- **증상**: `defaultMode: "bypassPermissions"` + `Edit(.claude/**)` allow rule + `skipDangerousModePermissionPrompt: true` 모두 설정했는데도 `~/.claude/PITFALLS.md` 편집 시 매번 승인 프롬프트 발생. 대표님이 버튼 누를 때까지 에이전트 대기. 처음엔 "이미 성공 중"이라 오판했으나 대표님이 매번 승인 눌러주고 있던 것. `.claude/commands/PITFALLS.md`로 옮긴 후에도 sensitive file 검사로 여전히 프롬프트 발생
- **원인**: Claude Code v2.1.x의 **하드코딩된 보호 디렉토리** (공식 permission-modes.md): `.claude`, `.git`, `.vscode`, `.idea`, `.husky` 5개는 bypassPermissions로도 우회 불가. `.claude/commands` 예외설은 부분만 맞고 "sensitive file" 2차 검사가 또 따라옴 (GitHub Issue #36192, #37029). 공식 비활성화 방법 없음
- **해결**: PITFALLS를 .claude/ 완전 외부로 이동. 최종 선택은 gbrain 인덱싱 (파일 자체 폐기)으로 결정 (P-040과 함께)
- **재발 방지**:
  1. 자율 편집이 필요한 메모리 파일은 `.claude/` 어떤 하위 폴더에도 두지 말 것 — 외부 경로 (`harness/`, `.harness-state/`) 또는 gbrain 인덱싱 사용
  2. "이미 성공했다"는 추정 대신 실제 프롬프트 유무를 대표님에게 확인 후 판단 (P-036 원칙 적용)
  3. claude-code-guide의 답변도 100% 정확하지 않을 수 있음 — 공식 GitHub Issue 검증"""),

    (40, "gbrain pglite WASM Aborted — Windows 경로 형식 + 패키지 오염",
     """- **발견**: 2026-04-17
- **증상**: `gbrain query`, `gbrain list`, `gbrain init` 모두 `Aborted(). Build with -sASSERTIONS` 에러
- **원인 (복합)**:
  1. `bun install -g gbrain` 이 npm의 GPU JS 라이브러리(gbrain@1.3.1)를 설치 — 실제 패키지는 `github:garrytan/gbrain`
  2. pglite WASM이 Windows C:\\ 경로를 처리 못함. `/c/Users/...` Git Bash 경로로만 동작
  3. 기존 brain.pglite, brain2.pglite도 Aborted — 구버전 pglite로 생성된 DB 파일과 현재 버전 호환성 문제
- **해결**:
  1. `git clone https://github.com/garrytan/gbrain /tmp/gbrain-src && cd /tmp/gbrain-src && bun install`
  2. npm global node_modules에 직접 복사: `cp -r /tmp/gbrain-src/. ~/.npm-global/gbrain/`
  3. gbrain init 시 반드시 `/c/Users/...` 형식 사용: `gbrain init --pglite --path "/c/Users/AIcreator/.gbrain/brain4.pglite"`
  4. config.json database_path도 `/c/Users/...` 형식으로 저장
  5. `gbrain put`은 stdin 파이프 안 됨 — `--content "..."` 옵션 필수
- **재발 방지**:
  - `bun install -g gbrain` 금지 — `github:garrytan/gbrain` 명시 또는 npm global 직접 복사
  - gbrain database_path는 항상 `/c/Users/...` 형식 (C:\\ Windows 경로 금지)
  - 기존 brain.pglite 접속 실패 시 새 brain4.pglite로 재초기화 (데이터 손실 감수)
  - 모든 import 스크립트는 Python subprocess 사용 (shell escape 회피)"""),
]


def main() -> int:
    success = 0
    failed = []
    for id_num, title, body in PITFALLS:
        slug = f"pitfall-{id_num:03d}-{slugify(title)}"
        page = (
            "---\n"
            "type: pitfall\n"
            f"id: P-{id_num:03d}\n"
            f"title: {title}\n"
            "tags: [pitfall, jamesclew]\n"
            "---\n\n"
            f"# P-{id_num:03d}: {title}\n\n"
            f"{body}\n"
        )
        result = subprocess.run(
            [GBRAIN, "put", slug, "--content", page],
            capture_output=True, text=True, encoding="utf-8", errors="replace"
        )
        if result.returncode == 0:
            success += 1
            print(f"  OK   {slug}")
        else:
            failed.append((slug, (result.stdout or "") + (result.stderr or "")))
            print(f"  FAIL {slug}: {(result.stderr or result.stdout)[:120]}")

    print(f"\n[summary] success={success}, failed={len(failed)}, total={len(PITFALLS)}")
    return 0 if not failed else 2


if __name__ == "__main__":
    sys.exit(main())
