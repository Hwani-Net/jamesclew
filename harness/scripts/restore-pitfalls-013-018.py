"""
Restore P-013, P-016, P-017, P-018 from file-history backups.
P-014 and P-015 never existed (P-018 itself documents the gap).
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
- **증상**: 블로그 생성에 Managed Agents API를 사용. 로컬 MCP(Perplexity/Tavily) 접근 불가, 파일 다운로드 필요, 디버깅 어려움
- **원인**: "5H 보존"이 목적이었으나, Agent(model: sonnet)도 Sonnet 풀 사용이라 5H 느린 소비. Managed Agents의 복잡도 대비 이점 부족
- **해결**: managed-blog-agent.py 삭제 (2026-04-16). 서브에이전트 + 외부 모델 검수 패턴으로 전환
- **재발 방지**: CLAUDE.md 용어 정의 테이블 추가 — "Agent"=서브에이전트, "Agent Teams"=TeamCreate, "Managed Agents"=API(미사용)"""),

    (18, "PITFALLS 번호 누락 — P-014/P-015 미기록 (P-013→P-016 점프)",
     """- **발견**: 2026-04-16
- **증상**: managed-agent-manual.md에서 P-014/P-015 참조하지만 PITFALLS.md에 실제 기록 없음. P-013 → P-016 점프
- **원인**: 해당 세션에서 매뉴얼은 작성했으나 PITFALLS 기록을 빠뜨림. P-014, P-015는 영구히 누락된 채로 남음
- **해결**: 소급 기록 (이 항목 P-018로 갭 자체를 문서화). 향후 P-014, P-015 슬롯은 비워둠
- **재발 방지**: user-prompt.ts의 forgot_record 패턴 감지 + 감사 체크에서 번호 연속성 검증"""),
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
