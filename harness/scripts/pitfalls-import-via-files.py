"""
Re-import all 38 PITFALL pages via `gbrain import <dir>`.
Workaround for `gbrain put --content` newline truncation on Windows.

Steps:
1. Read body from existing gbrain pages? No — bodies are already lost. Use source archive + restore scripts.
2. Write each P-NNN as individual .md file with proper frontmatter and full body.
3. Run `gbrain import <dir>` which reads files directly (no shell args).
4. embed --stale to vectorize.
"""
import re
import shutil
import subprocess
import sys
from pathlib import Path

GBRAIN = "C:/Users/AIcreator/AppData/Roaming/npm/gbrain.cmd"
ARCHIVE = Path("D:/jamesclew/harness/archive/PITFALLS-2026-04-17.md")
PITFALLS_DIR = Path("D:/jamesclew/harness/pitfalls")


def slugify(text: str, max_words: int = 5) -> str:
    cleaned = re.sub(r"[^\w\s-]", " ", text, flags=re.UNICODE)
    words = []
    for w in cleaned.lower().split():
        ascii_only = re.sub(r"[^a-z0-9-]", "", w)
        if ascii_only and len(ascii_only) > 1:
            words.append(ascii_only)
    return "-".join(words[:max_words]) if words else "untitled"


def parse_pitfalls_from_archive(content: str):
    pattern = r"(?=^## \[P-\d+\])"
    chunks = re.split(pattern, content, flags=re.MULTILINE)
    for chunk in chunks:
        chunk = chunk.strip()
        m = re.match(r"^## \[P-(\d+)\]\s*(.+?)$", chunk, flags=re.MULTILINE)
        if not m:
            continue
        id_num = int(m.group(1))
        title = m.group(2).strip()
        body = chunk[m.end():].strip()
        body = re.sub(r"\n---\s*$", "", body).strip()
        yield id_num, title, body


# Bodies recovered from this conversation for P-031~P-040 + file-history for P-013, P-016~P-018
EXTRA_PITFALLS = [
    (13, 'Google OAuth "Web application" 타입 클라이언트는 localhost redirect 불가',
     """- **발견**: 2026-04-13
- **증상**: Blogger OAuth2 토큰 발급 시 `400 redirect_uri_mismatch`. `http://localhost`, `http://localhost:8090`, OOB(`urn:ietf:wg:oauth:2.0:oob`) 전부 실패
- **원인**: OAuth 클라이언트가 "웹 애플리케이션" 타입으로 생성됨. Web 타입은 정확한 redirect URI 등록 필수 + OOB는 2022년 deprecated. "데스크톱 앱" 타입만 localhost 자동 허용
- **해결**: Google Cloud Console에서 "데스크톱 앱" 타입 OAuth 클라이언트 신규 생성 → client_id/secret 교체 → `InstalledAppFlow.run_local_server()` 정상 동작
- **재발 방지**: Google OAuth 클라이언트 생성 시 CLI/스크립트용은 반드시 "데스크톱 앱" 타입 선택. "웹 애플리케이션"은 브라우저 콜백이 있는 웹앱 전용"""),
    (16, "Managed Agents setup() 반복 호출 — $8.66 낭비",
     """- **발견**: 2026-04-12
- **증상**: managed-blog-agent.py에서 agents.create를 매 실행마다 호출. 14회 호출 → 각각 새 세션 + 풀 프롬프트 처리 → $8.66 소비
- **원인**: "Agent는 1회 생성, 이후 ID 재사용" 패턴 미숙지. setup()을 테스트할 때마다 새 Agent 생성
- **해결**: agent_id를 config 파일에 저장하고 재사용하도록 수정
- **재발 방지**: Managed Agents는 "생성 1회, 세션 N회" 원칙. 현재는 Managed Agents 미사용 (서브에이전트로 대체)"""),
    (17, "Managed Agents vs 서브에이전트 혼동 — 불필요한 복잡도",
     """- **발견**: 2026-04-12
- **증상**: 블로그 생성에 Managed Agents API를 사용. 로컬 MCP 접근 불가, 파일 다운로드 필요, 디버깅 어려움
- **원인**: "5H 보존"이 목적이었으나, Agent(model: sonnet)도 Sonnet 풀 사용이라 5H 느린 소비. Managed Agents의 복잡도 대비 이점 부족
- **해결**: managed-blog-agent.py 삭제 (2026-04-16). 서브에이전트 + 외부 모델 검수 패턴으로 전환
- **재발 방지**: CLAUDE.md 용어 정의 테이블 추가 — "Agent"=서브에이전트, "Agent Teams"=TeamCreate, "Managed Agents"=API(미사용)"""),
    (18, "PITFALLS 번호 누락 — P-014/P-015 미기록 (P-013→P-016 점프)",
     """- **발견**: 2026-04-16
- **증상**: managed-agent-manual.md에서 P-014/P-015 참조하지만 PITFALLS.md에 실제 기록 없음. P-013 → P-016 점프
- **원인**: 해당 세션에서 매뉴얼은 작성했으나 PITFALLS 기록을 빠뜨림. P-014, P-015는 영구히 누락된 채로 남음
- **해결**: 소급 기록 (이 항목 P-018로 갭 자체를 문서화). 향후 P-014, P-015 슬롯은 비워둠
- **재발 방지**: user-prompt.ts의 forgot_record 패턴 감지 + 감사 체크에서 번호 연속성 검증"""),
    (31, "Git Bash에서 cmd /c npx 호출 시 /c가 C:/로 자동 변환",
     """- **발견**: 2026-04-17
- **증상**: `claude mcp add wikipedia -s user -- cmd /c npx -y <pkg>` 실행 후 `claude mcp list`에 `cmd C:/ npx ...`로 등록됨 → Failed to connect
- **원인**: Git Bash(MSYS2)의 자동 경로 변환 기능이 POSIX 스타일 `/c`를 Windows 경로 `C:/`로 오인해서 바꿈
- **해결**: `MSYS_NO_PATHCONV=1 claude mcp add ... -- cmd /c npx ...` 로 prefix env var 적용
- **재발 방지**: Windows Git Bash에서 `claude mcp add --` 뒤에 Windows 절대경로/옵션 플래그가 오면 반드시 `MSYS_NO_PATHCONV=1` prefix 사용"""),
    (32, "Perplexity API 최소 충전 $50 — 검색용으로 과도한 비용",
     """- **발견**: 2026-04-17
- **증상**: API 크레딧 탑업 모달에서 $5 입력 시 "최소 $50 이상" 에러
- **원인**: Perplexity API 플랜 정책이 최소 충전 $50
- **해결**: Perplexity MCP 제거. 무료 대체: Tavily(6키 로테이션) + DuckDuckGo MCP + Wikipedia MCP + NotebookLM
- **재발 방지**: 검색 API는 "최소 충전 금액" 사전 확인. 무료 MCP 스택 기본"""),
    (33, "Tavily 로테이터 코드 수정 시 MCP 서버 재시작 필수",
     """- **발견**: 2026-04-17
- **증상**: tavily-rotator.mjs에 432 처리 추가 후에도 "exceeds usage limit" 에러. 6키 중 5개 살아있는데 로테이션 안 됨
- **원인**: MCP 서버는 Claude Code 시작 시 한 번만 로드됨. 세션 중 파일 수정해도 실행 중 node 프로세스는 이전 버전 사용
- **해결**: 로테이터 수정 후 Claude Code CLI 재시작. 임시 대체는 DuckDuckGo/Wikipedia/WebSearch
- **재발 방지**: MCP 프록시 파일 수정 시 "재시작 필요" 경고 출력. session-start hook에서 mtime 비교 추가"""),
    (34, "MusicGen CC-BY-NC 4.0 — 상업 유튜브 사용 금지",
     """- **발견**: 2026-04-17
- **증상**: Meta MusicGen 가중치가 CC-BY-NC 4.0. "오픈소스 AI 음악"으로 검색 최상위지만 비상업 전용
- **원인**: Meta 코드는 MIT지만 학습 가중치는 CC-BY-NC. 많은 튜토리얼이 미언급
- **해결**: Stable Audio Open(상업 OK), Pixabay Music, YouTube Audio Library로 대체
- **재발 방지**: 오픈소스 라이선스 조사 시 코드 vs 가중치 라이선스 분리 확인"""),
    (35, "Meta Developer 등록 이메일 코드 차단 — 평소 사용하지 않는 기기 보안 락",
     """- **발견**: 2026-04-17
- **증상**: developers.facebook.com 등록 Contact info 단계 이메일 코드 입력 정상이나 "평소에 사용하지 않는 기기" 팝업으로 차단
- **원인**: Meta 보안 정책상 "신뢰 기기"에서만 Developer 등록 완료 허용. 새 Chrome 프로필/IP/대량 로그인이 트리거
- **해결**: 24-48시간 동일 기기에서 일반 Facebook 사용으로 신뢰 점수 누적 후 재시도. 즉시 우회 경로 없음
- **재발 방지**: 새 Meta 계정/Developer 등록 전 1일+ 일반 활동 먼저. SMS 실패 보고 시 실제 원인 구분(SMS/이메일/기기 락)"""),
    (36, "영상 렌더 검증을 메타데이터만으로 판정 — 프레임 실측 없이 성공 보고",
     """- **발견**: 2026-04-17
- **증상**: VideoStudio 첫 숏츠 렌더 후 "검증 완료" 보고. 대표님이 재생해보니 전부 [B-roll placeholder] 회색 텍스트만
- **원인**: 검증 범위가 파일 존재 + ffprobe 메타 + 빌드 로그에 국한. 프레임 시각 확인 안 함
- **해결**: 렌더 후 ffmpeg로 5초 간격 프레임 추출 + Read로 5장 이상 시각 검증. AI B-roll 없으면 "placeholder 상태" 명시
- **재발 방지**: regression-autotest.sh에 mp4 자동 프레임 추출 + Read 강제. 빌드 성공 ≠ 콘텐츠 품질"""),
    (37, "FLUX.1 시리즈는 HuggingFace gated repo — 토큰 없이 다운로드 불가",
     """- **발견**: 2026-04-17
- **증상**: black-forest-labs/FLUX.1-schnell 다운로드 시 GatedRepoError 401
- **원인**: Black Forest Labs가 2025년경 FLUX.1-schnell/dev 모두 HF gated repo로 전환. Apache 2.0 라이선스지만 다운로드는 HF 로그인 + 모델 카드 동의 필수
- **해결**: HF 로그인 + 토큰. 게이트 없는 대체: SDXL(완전 공개), Kolors, PixArt-Sigma, AuraFlow
- **재발 방지**: HF 모델 사용 전 페이지에서 "You need to agree" 문구 확인. 코드 라이선스 != 가중치 다운로드 자유"""),
    (38, "Google Cloud Console OAuth UI 2025 개편 — OAuth 동의 화면 → Google 인증 플랫폼",
     """- **발견**: 2026-04-17
- **증상**: 구버전 가이드(External + 테스트 사용자) 따라가다 Step 3 막힘. 실제 화면은 브랜딩/대상/클라이언트 탭 구조
- **원인**: Google이 2025년 중반 OAuth consent screen을 Google 인증 플랫폼으로 개편. 탭 구조로 분리
- **해결**: 새 가이드: Google 인증 플랫폼 → 클라이언트 → 데스크톱 앱. 프로덕션 단계 프로젝트면 테스트 사용자 생략 가능
- **재발 방지**: Google/Anthropic/MS 콘솔 가이드 작성 전 실제 URL로 현재 UI 확인 (자주 개편됨)"""),
    (39, ".claude/ 루트 파일은 bypassPermissions로도 승인 프롬프트 우회 불가",
     """- **발견**: 2026-04-17
- **증상**: defaultMode bypassPermissions + Edit(.claude/**) allow + skipDangerousModePermissionPrompt 모두 설정해도 .claude/PITFALLS.md 편집 시 매번 승인 프롬프트. .claude/commands/PITFALLS.md로 옮긴 후에도 sensitive file 검사로 여전히 발생
- **원인**: Claude Code v2.1.x 하드코딩 보호 디렉토리 (.claude, .git, .vscode, .idea, .husky)는 bypassPermissions로 우회 불가. .claude/commands 예외설은 부분만 맞고 sensitive file 2차 검사 (GitHub Issue #36192, #37029)
- **해결**: PITFALLS를 .claude/ 완전 외부로 이동. 최종 선택은 gbrain 인덱싱(파일 폐기, P-040 함께)
- **재발 방지**: 자율 편집 메모리 파일은 .claude/ 어떤 하위 폴더에도 두지 말 것. 외부 경로(harness/, .harness-state/) 또는 gbrain 사용"""),
    (40, "gbrain pglite WASM Aborted — Windows 경로 형식 + 패키지 오염",
     """- **발견**: 2026-04-17
- **증상**: gbrain query/list/init 모두 Aborted 에러
- **원인 (복합)**: 1) bun install -g gbrain이 npm GPU JS 라이브러리 설치 (실제는 github:garrytan/gbrain) 2) pglite WASM이 Windows C:\\ 경로 처리 못함, /c/Users/... Git Bash 경로만 동작 3) 기존 brain.pglite도 구버전 호환성 문제
- **해결**: github:garrytan/gbrain 직접 클론 + npm global 복사. gbrain init --pglite --path "/c/Users/..." 필수. config.json도 /c/ 형식. gbrain put은 stdin 안 됨, --content 필수
- **재발 방지**: bun install -g gbrain 금지. database_path는 /c/Users/... 형식. import 스크립트는 Python subprocess 사용"""),
]


def main() -> int:
    if PITFALLS_DIR.exists():
        shutil.rmtree(PITFALLS_DIR)
    PITFALLS_DIR.mkdir(parents=True)

    text = ARCHIVE.read_text(encoding="utf-8")

    # Collect from archive (24 items)
    all_items = list(parse_pitfalls_from_archive(text))
    archived_ids = {id_num for id_num, _, _ in all_items}

    # Add extras not in archive
    for id_num, title, body in EXTRA_PITFALLS:
        if id_num not in archived_ids:
            all_items.append((id_num, title, body))

    all_items.sort(key=lambda t: t[0])

    print(f"[write] creating {len(all_items)} markdown files in {PITFALLS_DIR}")
    for id_num, title, body in all_items:
        slug = f"pitfall-{id_num:03d}-{slugify(title)}"
        safe_title = title.replace('"', '\\"')
        # Use front matter — gbrain import respects YAML
        md = (
            "---\n"
            "type: pitfall\n"
            f"id: P-{id_num:03d}\n"
            f'title: "{safe_title}"\n'
            "tags: [pitfall, jamesclew]\n"
            "---\n\n"
            f"# P-{id_num:03d}: {title}\n\n"
            f"{body}\n"
        )
        (PITFALLS_DIR / f"{slug}.md").write_text(md, encoding="utf-8")

    print(f"[delete] removing existing pitfall pages (will be replaced by import)")
    list_result = subprocess.run(
        [GBRAIN, "list", "-n", "200"],
        capture_output=True, text=True, encoding="utf-8", errors="replace"
    )
    for line in list_result.stdout.splitlines():
        slug = line.split("\t")[0] if "\t" in line else ""
        if slug.startswith("pitfall-"):
            subprocess.run([GBRAIN, "delete", slug], capture_output=True)

    print(f"[import] gbrain import {PITFALLS_DIR}")
    result = subprocess.run(
        [GBRAIN, "import", str(PITFALLS_DIR).replace("\\", "/")],
        capture_output=True, text=True, encoding="utf-8", errors="replace"
    )
    print(result.stdout)
    print(result.stderr, file=sys.stderr)

    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
