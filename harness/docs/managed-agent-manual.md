# Anthropic Managed Agents 실전 사용 매뉴얼

> 출처: 공식 문서 + $8.66 실수 학습 (P-016/P-017) | 최종 갱신: 2026-04-12

---

## 1. 비용 구조

### 과금 축 2가지

| 항목 | 단가 | 비고 |
|------|------|------|
| **세션 런타임** | $0.08/시간 | active time만 (ms 단위 과금) |
| **토큰** | 표준 API와 동일 | Sonnet: $3/$15, Haiku: $1/$5 (per MTok) |
| web_search | $0.01/회 ($10/1000회) | 세션 내 호출 시 추가 |
| web_fetch | 무료 | 토큰만 소비 |

### 핵심 인식: 토큰이 지배한다

- 2시간 세션 런타임 = **$0.16**
- 2시간 동안 소비되는 토큰 = **$20~50**
- **런타임보다 토큰 절감이 99% 중요**

### 실비용 예시

```
블로그 글 1건 생성 (Sonnet, 30분 active):
  런타임:  0.5h × $0.08 = $0.04
  토큰:    입력 50K + 출력 5K = $0.225
  web_search: 10회 = $0.10
  합계: 약 $0.37/건

$8.66이 나온 이유:
  → setup()을 14회 호출 (agents.create 14회)
  → 매 호출마다 새 세션 + 풀 롤플레이
  → 토큰 × 14배 낭비
```

---

## 2. 비용 절감 필수 패턴

### 패턴 1: Agent는 평생 1개

```python
# GOOD — 최초 1회만 생성, 이후 재사용
config = load_config()
if "agent_id" not in config:
    agent = client.beta.agents.create(...)  # 단 1회
    config["agent_id"] = agent.id
    save_config(config)

# BAD — 실행할 때마다 생성 (P-016)
def run(keyword):
    agent = client.beta.agents.create(...)  # 호출마다 새 agent = 돈 낭비
```

### 패턴 2: 프롬프트 변경 시 agents.update()

```python
# GOOD — 기존 agent의 버전만 올림
agent = client.beta.agents.update(
    agent_id=config["agent_id"],
    system=NEW_SYSTEM_PROMPT,  # 변경된 부분만
)
config["agent_version"] = agent.version
save_config(config)

# BAD — 프롬프트 1줄 바꾸려고 agents.create() 재호출 (P-017)
```

### 패턴 3: 세션 재사용 (캐시 히트 60~80%)

```python
# 동일 작업 반복 시 세션을 재사용
# 같은 세션에 여러 메시지 → 프롬프트 캐시 히트

# 1) 세션 생성 (1회)
session = client.beta.sessions.create(
    agent={"type": "agent", "id": agent_id, "version": agent_version},
    environment_id=env_id,
)

# 2) 여러 키워드를 같은 세션에서 순차 처리
for keyword in keywords:
    client.beta.sessions.events.send(
        session_id=session.id,
        events=[{"type": "user.message", "content": [{"type": "text", "text": keyword}]}],
    )
    # ... 결과 수집
# 세션 1개 = 캐시 누적 → 비용 절감
```

### 패턴 4: web_search 최소화

```python
# GOOD — URL 알면 web_fetch 사용 (무료)
# 시스템 프롬프트에 명시:
"URL을 알고 있으면 web_search 대신 web_fetch를 사용하라."
"web_search는 URL을 모를 때만 사용. 최대 5회로 제한."

# BAD — 매번 web_search로 URL 탐색 ($0.01 × N회)
```

### 패턴 5: output 간결화 지시

```python
# 시스템 프롬프트 끝에 추가:
"""
## Output Constraints
- Reasoning/thinking 출력 금지 — 최종 결과만
- 중간 확인 메시지 최소화
- 결과 파일을 /mnt/session/outputs/에 저장하고 완료 신호만 출력
"""
# → 출력 토큰 40~60% 절감
```

### 패턴 6: 모델 믹싱 (Haiku 서브작업)

```python
# 복잡한 작업만 Sonnet, 단순 작업은 Haiku
# 시스템 프롬프트에:
"단순 요약/형식 변환은 가장 간단한 방식으로 처리."
# 멀티에이전트 구성 시 sub-agent에 Haiku 지정 → 비용 70% 절감
```

---

## 3. 활용 패턴

### 패턴 A: Opus 어드바이저 (Sonnet 세션 → Opus 판단)

Sonnet 세션에서 복잡한 판단이 필요할 때, Managed Agent(Opus)에 질문하여 답을 받는 구조.

```python
# 1회 설정: Opus 어드바이저 Agent 생성
advisor = client.beta.agents.create(
    name="Opus Advisor",
    model="claude-opus-4-6",
    system="당신은 JamesClaw 에이전트의 어드바이저입니다. 질문에 대해 간결하게 판단/방향을 제시하세요. 3문장 이내로 답하세요.",
    tools=[],  # 도구 없음 — 순수 판단만
)
# agent_id 저장

# Sonnet 세션에서 필요할 때 호출
def ask_opus(question: str) -> str:
    session = client.beta.sessions.create(agent=advisor_id, environment_id=env_id)
    with client.beta.sessions.events.stream(session_id=session.id) as stream:
        client.beta.sessions.events.send(
            session_id=session.id,
            events=[{"type": "user.message", "content": [{"type": "text", "text": question}]}],
        )
        for event in stream:
            if hasattr(event, 'content'):
                return event.content[0].text
```

비용: Opus $5/$25 per MTok + $0.08/h. 짧은 판단 질문은 ~$0.05/회.
대안(무료): copilot-api의 gpt-4.1 또는 codex-rotate.sh로 대체 가능.

### 패턴 B: 멀티에이전트 파이프라인

서로 다른 역할의 Agent를 만들어 파이프라인 구성:
- Agent 1 (Sonnet): 블로그 초안 생성
- Agent 2 (Opus): 품질 검수 + 판단
- Agent 3 (Haiku): 메타데이터/SEO 체크

### 패턴 C: 1세션 다중 작업 (배치 처리)

같은 세션에 여러 키워드를 순차 전송 → 캐시 누적으로 비용 절감.
```python
session = create_session(agent_id)
for keyword in ["키워드1", "키워드2", "키워드3"]:
    send_message(session, f"Generate blog for: {keyword}")
    collect_results(session)
    # 세션 유지 → 다음 키워드에서 캐시 히트
```

### 패턴 D: 장기 실행 에이전트 (연구/분석)

세션을 닫지 않고 여러 턴에 걸쳐 대화 → 분석 결과 누적.
file_upload로 대용량 데이터 전달 가능.

---

## 4. 금지 패턴 (P-016/P-017 교훈)

### P-016: setup() 반복 호출

```
증상: "테스트해볼게요" → setup() 호출 → 프롬프트 수정 → setup() 재호출
원인: agents.create()가 매번 새 Agent ID 생성 = 비용 누적
비용: 14회 × 토큰비용 = $8.66
방지: config 파일에 agent_id 저장 → 없을 때만 create()
```

### P-017: one-shot 세션 반복

```
증상: 키워드마다 새 세션 생성 → 즉시 archive
원인: 세션당 환경 초기화 비용 + 캐시 미사용
방지: 같은 작업 배치는 1세션에서 처리
```

### P-018: 비용 추정 없는 반복 테스트

```
증상: 동작 확인 목적으로 실제 API 반복 호출
방지:
  1. 로컬 Gemma4(Ollama)로 프롬프트 사전 테스트
  2. 1회 실제 실행 후 비용 확인
  3. 확인 후 배치 실행
```

---

## 4. 사용 전 체크리스트

```
실행 전 반드시 확인:

[ ] 잔액 확인
    → https://console.anthropic.com/billing

[ ] 예상 비용 계산
    → 입력 토큰 추정: 시스템 프롬프트(~2K) + 대화(~1K) = ~3K/턴
    → 출력 토큰 추정: 블로그 글 ~3K 토큰
    → 런타임 추정: 작업 시간(분) / 60 × $0.08
    → 총합 = 런타임 + (입력+출력) × 단가

[ ] Gemma4 로컬 사전 테스트
    → curl http://localhost:11434/api/generate -d '{"model":"gemma3:4b","prompt":"..."}'
    → 프롬프트 구조/논리 검증 (API 호출 전)

[ ] config 파일 확인
    → cat ~/.harness-state/managed-agent-config.json
    → agent_id 있으면 setup() 호출 금지

[ ] 1회 테스트 후 실제 비용 검증
    → span.model_request_end 이벤트의 usage 필드 확인
    → 추정과 괴리 2배 이상이면 프롬프트 재검토
```

---

## 5. managed-blog-agent.py 수정 가이드

### 5-1. setup을 agents.update()로 전환

```python
def setup(force_update: bool = False):
    """One-time setup OR prompt update only."""
    client = anthropic.Anthropic()
    config = load_config()

    # Environment: 한 번만 생성
    if "environment_id" not in config:
        env = client.beta.environments.create(
            name="blog-pipeline-env",
            config={"type": "cloud", "networking": {"type": "unrestricted"}},
        )
        config["environment_id"] = env.id
        print(f"  Environment created: {env.id}")

    # Agent: 있으면 update, 없으면 create
    if "agent_id" in config and not force_update:
        print(f"  Agent exists: {config['agent_id']} (v{config['agent_version']})")
        print("  프롬프트 업데이트만 하려면: python managed-blog-agent.py setup --update")
        return

    if "agent_id" in config:
        # 프롬프트 변경 시 update (새 ID 생성 안 함)
        agent = client.beta.agents.update(
            agent_id=config["agent_id"],
            system=BLOG_SYSTEM_PROMPT,
        )
        config["agent_version"] = agent.version
        print(f"  Agent updated: v{agent.version}")
    else:
        # 최초 1회만 create
        agent = client.beta.agents.create(
            name="Blog Pipeline Agent",
            model="claude-sonnet-4-6",
            system=BLOG_SYSTEM_PROMPT,
            tools=[{"type": "agent_toolset_20260401", "default_config": {"enabled": True}}],
        )
        config["agent_id"] = agent.id
        config["agent_version"] = agent.version
        print(f"  Agent created: {agent.id}")

    save_config(config)
```

### 5-2. 비용 로깅 추가

```python
# run() 함수 내 이벤트 처리에 추가
cost_log = {"input_tokens": 0, "output_tokens": 0, "cache_read": 0, "search_calls": 0}

elif event.type == "span.model_request_end":
    usage = getattr(event, "model_usage", None)
    if usage:
        cost_log["input_tokens"] += usage.input_tokens
        cost_log["output_tokens"] += usage.output_tokens
        cost_log["cache_read"] += getattr(usage, "cache_read_input_tokens", 0)

elif event.type == "agent.tool_use":
    tool_name = getattr(event, 'tool_name', None) or getattr(event, 'name', '')
    if tool_name == "web_search":
        cost_log["search_calls"] += 1

# 완료 후 비용 출력
def print_cost_summary(cost_log: dict, runtime_seconds: float):
    input_cost  = cost_log["input_tokens"] / 1_000_000 * 3.0   # Sonnet 입력
    output_cost = cost_log["output_tokens"] / 1_000_000 * 15.0  # Sonnet 출력
    cache_saving = cost_log["cache_read"] / 1_000_000 * 0.3     # 캐시 절감
    search_cost = cost_log["search_calls"] * 0.01
    runtime_cost = (runtime_seconds / 3600) * 0.08

    total = input_cost + output_cost + search_cost + runtime_cost - cache_saving
    print(f"\n--- 비용 요약 ---")
    print(f"  입력 토큰:   {cost_log['input_tokens']:,} → ${input_cost:.4f}")
    print(f"  출력 토큰:   {cost_log['output_tokens']:,} → ${output_cost:.4f}")
    print(f"  캐시 절감:   {cost_log['cache_read']:,} → -${cache_saving:.4f}")
    print(f"  web_search:  {cost_log['search_calls']}회 → ${search_cost:.4f}")
    print(f"  런타임:      {runtime_seconds:.0f}초 → ${runtime_cost:.4f}")
    print(f"  ────────────────────")
    print(f"  합계:        ${total:.4f}")

    # ~/.harness-state/api_cost_log.jsonl 기록
    import datetime
    log_path = Path.home() / ".harness-state" / "api_cost_log.jsonl"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("a", encoding="utf-8") as f:
        f.write(json.dumps({
            "date": datetime.datetime.now().isoformat(),
            "service": "anthropic-managed-agent",
            "model": "claude-sonnet-4-6",
            "cost_usd": round(total, 4),
            "tokens": cost_log,
            "runtime_sec": runtime_seconds,
        }) + "\n")
```

### 5-3. CLI에 --update 옵션 추가

```python
# main() 수정
if cmd == "setup":
    force_update = "--update" in sys.argv
    setup(force_update=force_update)
```

---

## 6. 빠른 참조 카드

```
자주 쓰는 커맨드:
  python managed-blog-agent.py setup          # 최초 1회
  python managed-blog-agent.py setup --update # 프롬프트만 업데이트
  python managed-blog-agent.py run "키워드"   # 블로그 생성
  python managed-blog-agent.py list           # 세션 목록

config 위치: ~/.harness-state/managed-agent-config.json
비용 로그:   ~/.harness-state/api_cost_log.jsonl

비용 공식:
  건당 예상 = $0.37 (Sonnet, 30분, web_search 10회 기준)
  월 10건   = ~$3.70 + 런타임

절대 금지:
  setup() 반복 = P-016
  one-shot 세션 반복 = P-017
  비용 확인 없이 배치 = P-018
```

---

*출처: [Anthropic Pricing](https://platform.claude.com/docs/en/about-claude/pricing) | [$0.08/session-hour 분석](https://tygartmedia.com/claude-managed-agents-pricing-cost-analysis/) | [Managed Agents Deep Dive](https://dev.to/bean_bean/claude-managed-agents-deep-dive-anthropics-new-ai-agent-infrastructure-2026-3286)*
