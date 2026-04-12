#!/usr/bin/env python3
"""
Managed Agent — Blog Pipeline
Creates a Managed Agent that generates SEO-optimized blog posts asynchronously.
Usage:
  # One-time setup (saves agent/env IDs)
  python managed-blog-agent.py setup

  # Run blog generation for a keyword
  python managed-blog-agent.py run "2026 무선 이어폰 추천 비교"

  # List existing sessions
  python managed-blog-agent.py list

  # Retrieve blog content from an existing session
  python managed-blog-agent.py retrieve <session_id>
"""

import os
import sys
import json
import time
from pathlib import Path

# Fix Windows cp949 encoding for emoji/unicode output
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    sys.stderr.reconfigure(encoding='utf-8', errors='replace')

from dotenv import load_dotenv

# Load API keys — .env-keys has ANTHROPIC_API_KEY, ~/.env has CLAUDE_API_KEY as fallback
_env_keys = Path.cwd() / ".env-keys"
if not _env_keys.exists():
    _env_keys = Path.home() / ".env-keys"
load_dotenv(_env_keys)
load_dotenv(Path.home() / ".env")
if not os.environ.get("ANTHROPIC_API_KEY") and os.environ.get("CLAUDE_API_KEY"):
    os.environ["ANTHROPIC_API_KEY"] = os.environ["CLAUDE_API_KEY"]

import anthropic

# Config paths
CONFIG_DIR = Path.home() / ".harness-state"
CONFIG_FILE = CONFIG_DIR / "managed-agent-config.json"
DRAFTS_DIR = Path(os.environ.get("BLOG_DRAFTS_DIR", "drafts"))

BLOG_SYSTEM_PROMPT = """You are a Korean SEO blog writer agent. You generate high-quality blog posts optimized for Korean search engines.

## Workflow
Given a keyword, execute these phases in order:

### Phase 1: SEO Research
- Use web_search to find top 5 Korean blog results for "{keyword} 블로그 추천 2026"
- Analyze competitor H2/H3 structure, product mentions, content length
- Identify differentiation points competitors miss

### Phase 1.5: Benchmark — Read Human Blogs
- From the top 3 search results, extract 2 actual human-written blog posts using web_fetch
- Analyze their writing style: sentence endings, emotional expressions, structure flow
- Use these as tone/structure reference for Phase 2

### Phase 2: Draft Generation
Write a blog post in Korean with these requirements:
- **Length**: 3000-4000 characters
- **Structure**: H2 x3+ (product intro / comparison / buying guide), H3 per product, FAQ x2+
- **SEO**: Primary keyword 3+ natural mentions, meta description 120-155 chars
- **Include**: [IMAGE:productname] tags for image placement, [INTERNAL_LINK:topic] x2+
- Frontmatter: title, description(120-155자), keywords, date

#### Writing Style Rules (Benchmarked from top Korean bloggers)

**구조: 체험 먼저 → 스펙 뒤로**
- 각 제품 섹션은 반드시 체험 서술 2-3문장으로 시작
- "스펙을 보면" 같은 전환어 후 스펙 요약 1-2줄만 배치
- 잘못된 순서: 출시일 → 프로세서 → 코덱 → 체험 (리포트형)
- 올바른 순서: 체험 에피소드 → 느낀 점 → 관련 스펙 요약 → 단점

**감정/몸감각 표현 필수**
- 제품당 감정 또는 신체적 체감 1-2문장 필수 포함
- 좋은 예: "볼륨 안 올려도 되니까 귀 피로가 확 줄었어요", "줄 걸려서 짜증 났던 적 많아서"
- 나쁜 예: "9시간 41분의 배터리 수명을 기록했으며" (테스트 로그형)
- 단점도 솔직하게: "~수 있습니다" 식 완곡 표현 줄이고 "솔직히 ~가 좀 아쉬웠어요" 식으로

**종결어미 다양성**
- "~합니다/~됩니다" 연속 3회 이상 반복 금지
- 해요체("~거든요", "~더라고요"), 구어체("~인 셈이에요"), 감탄형("~이라니!") 혼용
- 전체 문장 중 구어체 비율 40% 이상 유지

**대화감**
- 소제목마다 같은 패턴(질문형) 반복 금지 — 각각 다른 도입 방식 사용
- 질문형("혹시 ~?") / 에피소드형("~하다가 발견한 제품") / 비교형("~와 나란히 써보니") / 솔직형("솔직히 ~")
- 독자에게 직접 말 거는 표현: "~하시는 분이라면", "~해보신 적 있으시죠?"

**제품 간 전환 (연결 문장 필수)**
- 제품 섹션 사이에 자연스러운 전환 문장 1개 필수
- 좋은 예: "음질은 소니가 앞섰는데, 가격을 생각하면 다음 제품도 한번 볼 만해요."
- 나쁜 예: 구분선(---) 후 바로 다음 제품 소개 시작

**종결어미 반복 금지**
- "~소개했습니다", "~제공합니다", "~지원합니다" 같은 어미 연속 2회 이상 반복 금지
- "~로 소개했습니다" 패턴 자체를 사용하지 마라 — 제품을 "소개"하지 말고 체험을 "이야기"하라

**수치는 체감과 함께**
- 수치를 쓸 때는 체감으로 번역: "흡입력 11,000Pa" → "모래 위에서도 깨끗하게 빨아들이더라고요(흡입력 11,000Pa)"
- 보도자료처럼 수치만 나열하지 마라

**절대 금지 (AI 클리셰)**
- "다양한", "혁신적인", "획기적인", "알아보겠습니다", "살펴보겠습니다"
- "한 차원 끌어올렸다", "새 기준을 세우다", "진가를 발휘하다"
- "핵심 변화는 N가지입니다" 식의 구조 선언
- 동일 문장 구조 반복 (모든 제품을 같은 틀로 설명)
- "~로 소개했습니다", "~로 작성했습니다" (메타 서술 금지)

### Phase 3: Fact Verification
- Use web_search/web_fetch to verify prices, specs, release dates mentioned in draft
- Auto-fix mismatches, flag unverifiable claims with [FACT_CHECK]

### Phase 4: Save Output
- IMPORTANT: Write ALL output files to /mnt/session/outputs/ directory (this is the ONLY path that makes files downloadable)
- Write the final draft to /mnt/session/outputs/draft.md
- Write metadata (SEO data, fact check log, products) to /mnt/session/outputs/meta.json
- Write status to /mnt/session/outputs/status.json
- Do NOT write to /workspace/ or any other path — only /mnt/session/outputs/ files are retrievable

### Batch 2 구조적 교훈 (자동 반영)
- 비교표를 먼저 작성하고, 본문을 비교표 기준으로 쓸 것. 본문과 비교표 수치 불일치 금지.
- 가격/스펙 출처를 괄호로 표기: "139만원(쿠팡 4월 기준)", "CADR 500(제조사 공식)"
- 출처 URL 3종 이상 다양화: 쿠팡만 편중 금지 → 제조사 공식, 다나와, 네이버 쇼핑 병행
- 제품당 스펙 수치는 본문에 2개 이하. 나머지는 비교표에만. 수치는 체감 표현과 함께.
- 비교표에 넣는 제품은 반드시 본문에서도 1문장 이상 언급

## Constraints
- Draft must be 2000+ characters with H2 x3+, FAQ x2+
- All facts must be verified or flagged
- No loading="lazy" in any HTML
- Korean language only for blog content
"""


def load_config() -> dict:
    """Load saved agent/environment IDs."""
    if CONFIG_FILE.exists():
        return json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
    return {}


def save_config(config: dict):
    """Save agent/environment IDs."""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    CONFIG_FILE.write_text(json.dumps(config, indent=2), encoding="utf-8")


def setup():
    """One-time setup: create Environment + Agent."""
    client = anthropic.Anthropic()
    config = load_config()

    # Create Environment (if not exists)
    if "environment_id" not in config:
        print("Creating environment...")
        env = client.beta.environments.create(
            name="blog-pipeline-env",
            config={
                "type": "cloud",
                "networking": {"type": "unrestricted"},
            },
        )
        config["environment_id"] = env.id
        print(f"  Environment: {env.id}")
    else:
        print(f"  Environment exists: {config['environment_id']}")

    # Create Agent
    print("Creating blog-pipeline agent...")
    agent = client.beta.agents.create(
        name="Blog Pipeline Agent",
        model="claude-sonnet-4-6",
        system=BLOG_SYSTEM_PROMPT,
        tools=[
            {"type": "agent_toolset_20260401", "default_config": {"enabled": True}},
        ],
    )
    config["agent_id"] = agent.id
    config["agent_version"] = agent.version
    print(f"  Agent: {agent.id} (v{agent.version})")

    save_config(config)
    print(f"\nConfig saved to {CONFIG_FILE}")
    print("Setup complete. Run: python managed-blog-agent.py run \"keyword\"")


def run(keyword: str):
    """Run blog generation for a keyword."""
    client = anthropic.Anthropic()
    config = load_config()

    if "agent_id" not in config:
        print("Error: Run setup first: python managed-blog-agent.py setup")
        sys.exit(1)

    agent_id = config["agent_id"]
    agent_version = config["agent_version"]
    env_id = config["environment_id"]

    # Create session
    print(f"Creating session for keyword: {keyword}")
    session = client.beta.sessions.create(
        agent={"type": "agent", "id": agent_id, "version": agent_version},
        environment_id=env_id,
        title=f"Blog: {keyword}",
    )
    print(f"  Session: {session.id} (status: {session.status})")

    # Stream-first, then send
    print("Starting stream...")
    prompt = BLOG_SYSTEM_PROMPT.replace("{keyword}", keyword)
    user_message = f"Generate a blog post for the keyword: {keyword}"

    # Collect content for local saving
    agent_texts = []       # fallback: agent conversational messages
    write_contents = []    # primary: content from write tool calls
    bash_outputs = []      # secondary: bash tool outputs that may contain blog text

    # Open stream and send message
    with client.beta.sessions.events.stream(session_id=session.id) as stream:
        # Send the kickoff message
        client.beta.sessions.events.send(
            session_id=session.id,
            events=[{
                "type": "user.message",
                "content": [{"type": "text", "text": user_message}],
            }],
        )

        # Process events
        for event in stream:
            if event.type == "agent.message":
                for block in event.content:
                    if block.type == "text":
                        text = block.text
                        agent_texts.append(text)
                        if len(text) > 200:
                            print(f"  [agent] {text[:200]}...")
                        else:
                            print(f"  [agent] {text}")

            elif event.type == "agent.tool_use":
                # Debug: log all attributes so we can see the event structure
                attrs = {k: getattr(event, k, None) for k in dir(event) if not k.startswith('_')}
                tool_name = (
                    getattr(event, 'tool_name', None)
                    or getattr(event, 'name', None)
                    or attrs.get('tool_name', 'unknown')
                )
                tool_input = getattr(event, 'input', None) or attrs.get('input', None)
                print(f"  [tool_use] name={tool_name} | attrs={list(attrs.keys())}")

                # Capture write tool file content (primary blog capture method)
                if tool_name in ('write', 'Write', 'file_write', 'create_file'):
                    if tool_input:
                        # input is typically a dict with 'path' and 'content' keys
                        if isinstance(tool_input, dict):
                            content = tool_input.get('content') or tool_input.get('text') or tool_input.get('file_content')
                            path = tool_input.get('path') or tool_input.get('file_path') or tool_input.get('filename', '')
                        else:
                            # May be raw string
                            content = str(tool_input)
                            path = ''
                        if content:
                            print(f"  [WRITE CAPTURED] path={path} len={len(content)}")
                            write_contents.append({'path': path, 'content': content})
                    else:
                        print(f"  [tool_use:write] No input found. Full event attrs: {attrs}")

                # Capture bash tool — look for heredoc/echo patterns with blog content
                elif tool_name in ('bash', 'Bash', 'shell', 'computer'):
                    if tool_input:
                        cmd = str(tool_input.get('command', tool_input) if isinstance(tool_input, dict) else tool_input)
                        # Heuristic: bash writing a markdown file
                        if ('cat >' in cmd or 'tee ' in cmd or 'heredoc' in cmd.lower()) and len(cmd) > 500:
                            print(f"  [BASH WRITE DETECTED] len={len(cmd)}")
                            bash_outputs.append(cmd)

            elif event.type == "agent.tool_result":
                # Capture tool result output — may contain echoed file content
                attrs = {k: getattr(event, k, None) for k in dir(event) if not k.startswith('_')}
                output = getattr(event, 'output', None) or attrs.get('output', None)
                print(f"  [tool_result] attrs={list(attrs.keys())}")
                if output and isinstance(output, str) and len(output) > 1000:
                    # Large tool output — likely blog content echoed back
                    print(f"  [tool_result:large] len={len(output)} preview={output[:100]}")

            elif event.type == "session.status_idle":
                stop_reason = getattr(event, "stop_reason", None)
                if stop_reason and getattr(stop_reason, "type", None) == "requires_action":
                    continue  # Transient idle — wait for resolution
                print("  [idle] Agent finished.")
                break

            elif event.type == "session.status_terminated":
                print("  [terminated] Session ended.")
                break

            elif event.type == "session.error":
                print(f"  [error] {event}")

            elif event.type == "span.model_request_end":
                usage = getattr(event, "model_usage", None)
                if usage:
                    print(f"  [usage] in={usage.input_tokens} out={usage.output_tokens} "
                          f"cache_read={usage.cache_read_input_tokens}")

            elif "tool" in event.type.lower():
                # Catch-all for any tool-related events not handled above
                attrs = {k: getattr(event, k, None) for k in dir(event) if not k.startswith('_')}
                print(f"  [TOOL EVENT:{event.type}] attrs={list(attrs.keys())}")

    # Download output files
    print("\nDownloading output files...")
    slug = keyword.replace(" ", "-")[:30]
    date_str = time.strftime("%Y-%m-%d")
    output_dir = DRAFTS_DIR / f"{date_str}-{slug}"
    output_dir.mkdir(parents=True, exist_ok=True)

    # PRIMARY: Save content from write tool calls (actual blog file writes)
    draft_saved = False
    for item in write_contents:
        path = item['path']
        content = item['content']
        # Map /mnt/session/outputs/draft.md → local draft.md
        filename = Path(path).name if path else 'draft.md'
        if not filename or filename == '.':
            filename = 'draft.md'
        out_path = output_dir / filename
        out_path.write_text(content, encoding="utf-8")
        print(f"  Saved (from write tool): {out_path}")
        if 'draft' in filename.lower() or filename.endswith('.md'):
            draft_saved = True

    # SECONDARY: Save fallback from agent conversation text (if no write tool captured)
    if not draft_saved and agent_texts:
        draft_path = output_dir / "draft.md"
        draft_path.write_text("\n".join(agent_texts), encoding="utf-8")
        print(f"  Saved (from stream fallback): {draft_path}")
        draft_saved = True

    # Try downloading files from session outputs (with retry for indexing lag)
    for attempt in range(3):
        try:
            time.sleep(2)
            files = client.beta.files.list()
            session_files = [f for f in files.data if session.id in (getattr(f, 'session_id', '') or '')]
            if not session_files:
                # Fallback: download all recent files
                session_files = [f for f in files.data if f.filename in ('draft.md', 'meta.json', 'status.json')]
            for f in session_files:
                content = client.beta.files.download(f.id)
                out_path = output_dir / f.filename
                content.write_to_file(str(out_path))
                print(f"  Saved (from API): {out_path}")
            if session_files:
                break
        except Exception as e:
            if attempt == 2:
                print(f"  Note: File download unavailable ({e}). Stream content saved instead.")

    # Archive session
    try:
        client.beta.sessions.archive(session_id=session.id)
        print(f"Session archived: {session.id}")
    except Exception:
        pass

    # Log result for harness
    result_path = Path.home() / ".harness-state" / "last_result.txt"
    result_path.write_text(
        f"managed-blog-agent: {keyword} | session={session.id} | {time.strftime('%Y-%m-%d %H:%M')}",
        encoding="utf-8",
    )


def list_sessions():
    """List recent sessions."""
    client = anthropic.Anthropic()
    sessions = client.beta.sessions.list()
    for s in sessions.data[:10]:
        print(f"  {s.id} | {s.status} | {s.title or 'untitled'}")


def retrieve(session_id: str):
    """Send a follow-up message to an existing session asking for the full blog text."""
    client = anthropic.Anthropic()

    retrieve_message = (
        "Output the full content of /mnt/session/outputs/draft.md as plain text. "
        "Print the entire file content without truncation."
    )
    print(f"Retrieving blog from session: {session_id}")

    collected = []

    with client.beta.sessions.events.stream(session_id=session_id) as stream:
        client.beta.sessions.events.send(
            session_id=session_id,
            events=[{
                "type": "user.message",
                "content": [{"type": "text", "text": retrieve_message}],
            }],
        )

        for event in stream:
            if event.type == "agent.message":
                for block in event.content:
                    if block.type == "text":
                        collected.append(block.text)
                        print(block.text[:500] if len(block.text) > 500 else block.text)

            elif event.type == "agent.tool_use":
                tool_name = getattr(event, 'tool_name', None) or getattr(event, 'name', None) or 'unknown'
                tool_input = getattr(event, 'input', None)
                print(f"  [tool] {tool_name}")
                # Also capture write tool content during retrieve
                if tool_name in ('write', 'Write', 'file_write', 'create_file') and tool_input:
                    if isinstance(tool_input, dict):
                        content = tool_input.get('content') or tool_input.get('text', '')
                    else:
                        content = str(tool_input)
                    if content:
                        collected.append(content)
                        print(f"  [WRITE CAPTURED during retrieve] len={len(content)}")

            elif event.type == "session.status_idle":
                stop_reason = getattr(event, "stop_reason", None)
                if stop_reason and getattr(stop_reason, "type", None) == "requires_action":
                    continue
                print("  [idle] Done.")
                break

            elif event.type == "session.status_terminated":
                print("  [terminated]")
                break

    if collected:
        date_str = time.strftime("%Y-%m-%d")
        output_dir = DRAFTS_DIR / f"{date_str}-retrieve-{session_id[:8]}"
        output_dir.mkdir(parents=True, exist_ok=True)
        draft_path = output_dir / "draft.md"
        draft_path.write_text("\n".join(collected), encoding="utf-8")
        print(f"\nSaved: {draft_path}")
    else:
        print("\nNo content retrieved.")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "setup":
        setup()
    elif cmd == "run":
        if len(sys.argv) < 3:
            print("Usage: python managed-blog-agent.py run \"keyword\"")
            sys.exit(1)
        run(sys.argv[2])
    elif cmd == "list":
        list_sessions()
    elif cmd == "retrieve":
        if len(sys.argv) < 3:
            print("Usage: python managed-blog-agent.py retrieve <session_id>")
            sys.exit(1)
        retrieve(sys.argv[2])
    else:
        print(f"Unknown command: {cmd}")
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
