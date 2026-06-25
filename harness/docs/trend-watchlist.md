# Trend Watchlist (자동 트리아지 산출)

`/trend-triage`가 매일 디제스트에서 추린 JamesClaw 관련 항목. 🎯=격차충족 후보(결재 대상), 🔍=관찰. **URL 기준 dedup** — 같은 repo 재상신 금지.

| 날짜 | repo | cat | 근거/격차 | 액션 | rel | URL |
|------|------|-----|----------|------|-----|-----|
| 2026-06-22 | DeusData/codebase-memory-mcp | memory | 코드베이스 영속 지식그래프 MCP, 158언어, 토큰절감 — Understand-Anything(정적 1회 스냅샷) 보완하는 라이브 메모리 MCP | 🎯 토큰절감 실측 + agentmemory와 역할 비교 후 채택 검토 | 3 | https://github.com/DeusData/codebase-memory-mcp |
| 2026-06-22 | vercel/eve | agent-os | **durable execution(스텝 체크포인트·crash 재개) = landscape #1 격차의 레퍼런스 구현** | 🎯 직접채택(TS) 아님 — #1 격차(체크포인트-재개) 설계 결정 위해 모델 정독·채택 검토 | 3 | https://github.com/vercel/eve |
| 2026-06-22 | shadcn/improve | coding-wf | 고성능 감사→저비용 실행 계획 = 우리 Multi-Model+Reins 패키지판 | 🔍 패키징/프롬프트 구조 마이닝 | 2 | https://github.com/shadcn/improve |
| 2026-06-22 | BuilderIO/skills | skills | 코딩 에이전트 스킬 모음 | 🔍 우리 스킬 소스로 마이닝 | 2 | https://github.com/BuilderIO/skills |
| 2026-06-22 | Waishnav/devspace | coding-wf | ChatGPT를 Codex처럼+사용량 별도관리 = codex quota(P-262) 관련 | 🔍 codex 비용관리 패턴 참고 | 2 | https://github.com/Waishnav/devspace |
| 2026-06-22 | lenucksi/aur-malware-check | security | AUR 공급망 악성탐지 — 우리 보안 격차 신호 | 🔍 공급망 감사 스킬 필요성 근거 | 2 | https://github.com/lenucksi/aur-malware-check |
| 2026-06-22 | XiaomiMiMo/MiMo-Code | agent | 모델+에이전트 공진화 | 🔍 autonomous-evolution 참고 | 2 | https://github.com/XiaomiMiMo/MiMo-Code |
| 2026-06-22 | heygen-com/hyperframes | video | HTML→video | 🔍 영상 파이프라인 기법 참고 | 2 | https://github.com/heygen-com/hyperframes |
| 2026-06-24 | calesthio/OpenMontage | video | **agentic 영상 파이프라인(12 pipeline·52 tool·500+ skill·웹리서치 1급) = landscape 3순위 영상격차의 성숙한 오픈소스 대조군** (OpenClaw P-196~208 벤치마크 대상) | 🎯 구조 대조(웹리서치 1급화·스킬 모듈화) 벤치마크 후 선택 흡수 | 3 | https://github.com/calesthio/OpenMontage |
| 2026-06-24 | mukul975/Anthropic-Cybersecurity-Skills | security | 817 구조화 사이버보안 스킬(MITRE ATT&CK/NIST/ATLAS 매핑, Claude Code/Codex 호환) = landscape ④보안격차(능동 취약점·공급망 감사 스킬 부재) 충족 후보. lenucksi/aur-malware-check(rel-2 신호)보다 강한 실제 스킬셋 | 🎯 보안 스킬셋 평가 — **단 landscape 자체 우선순위 '낮음' → 低긴급 플래그** | 3 | https://github.com/mukul975/Anthropic-Cybersecurity-Skills |
| 2026-06-24 | affaan-m/ECC | agent-os | 병렬 에이전트 하네스(skills·instincts·memory·security·research-first, Claude Code/Codex/Cursor) — 직접 비교군. "instincts" 개념 신규 (보안언급은 명목 P-220 → rel-2) | 🔍 instincts·perf·보안 패턴 마이닝 | 2 | https://github.com/affaan-m/ECC |
| 2026-06-24 | NousResearch/hermes-agent | memory | "agent that grows with you"(적응형 메모리) — 메모리는 우리 ✅강점(agentmemory+BASB), 갭 아님 | 🔍 적응형 메모리 구조 agentmemory와 대조 | 2 | https://github.com/NousResearch/hermes-agent |
| 2026-06-24 | anthropics/claude-plugins-official | skills | Anthropic 공식 Claude Code 플러그인 디렉터리 — 스킬/플러그인 라이브 소스(BuilderIO/skills와 동류) | 🔍 하네스 호환 스킬·플러그인 소스로 주기적 마이닝 | 2 | https://github.com/anthropics/claude-plugins-official |
| 2026-06-24 | revfactory/harness | agent-os | 에이전트팀 설계+스킬 생성 메타스킬 — 우리 /agent-team+/skill-creator+메타하네스 ✅보유와 정합(갭 아님) | 🔍 메타스킬 팀생성 구조 /agent-team과 대조 | 2 | https://github.com/revfactory/harness |
| 2026-06-25 | vercel-labs/agent-browser | browser | **영속 데몬 세션·네이티브 Rust CLI·접근성트리 스냅샷(~200-400토큰) = landscape ②브라우저 격차 직접구현** — 느린 claude-in-chrome MCP 통증 정조준, gstack /browse 채택모델과 동형(CLI shell-out). 검수 확인: 구조매칭(명목 아님) | 🎯 /browse vs agent-browser 실측 벤치 후 브라우저 우선순위 채택 검토 | 3 | https://github.com/vercel-labs/agent-browser |
| 2026-06-25 | KeygraphHQ/shannon | security | 자율 화이트박스 AI 펜테스터(소스분석+실제 익스플로잇 실행) = landscape ④보안격차 '능동 취약점 감사'의 **실행형** 충족. Anthropic-Cybersecurity-Skills(지식 카탈로그)와 구조적 구별(실행 vs 참조) — 검수 확인 별개 후보 | 🎯 능동 취약점 감사 평가 — **landscape 보안 우선순위 '낮음' → 低긴급** | 3 | https://github.com/KeygraphHQ/shannon |
| 2026-06-25 | anthropics/skills | skills | Anthropic 공식 재사용 에이전트 스킬 리포(claude-plugins-official=플러그인 디렉터리와 별개, 스킬 본체) | 🔍 하네스 호환 스킬 소스로 주기 마이닝 | 2 | https://github.com/anthropics/skills |
| 2026-06-25 | mksglu/context-mode | coding-wf | 컨텍스트윈도 최적화(98% 도구출력 샌드박싱·세션메모리·17플랫폼 MCP 라우팅) — 우리 토큰절감(codebase-memory-mcp)과 다른 컨텍스트 관리 기법 | 🔍 도구출력 샌드박싱 기법 마이닝 | 2 | https://github.com/mksglu/context-mode |
| 2026-06-25 | bradautomates/claude-video | video-voice | Claude 영상 시청 능력(다운로드·프레임추출·전사) = 영상 이해/**입력**. landscape ③격차(영상 **생산**)와 다른 축 → 명목승격 금지(P-220)로 rel-2 유지 | 🔍 영상 입력 능력 — codex-vision(이미지) 보완 관찰 | 2 | https://github.com/bradautomates/claude-video |
| 2026-06-25 | alibaba/page-agent | browser | 인페이지 GUI 에이전트(자연어 웹 제어) — agent-browser(CLI shell-out)와 다른 패러다임(인페이지). 브라우저 도메인 참고군 | 🔍 NL 인페이지 제어 접근법 마이닝(agent-browser 채택 비교군) | 2 | https://github.com/alibaba/page-agent |
| 2026-06-25 | jamiepine/voicebox | video-voice | 오픈소스 AI 음성 스튜디오(클로닝·받아쓰기·생성) — video-voice 카테고리 음성 도구 참고 | 🔍 음성 클로닝/스튜디오 기법 OpenClaw 음성패턴과 대조 | 2 | https://github.com/jamiepine/voicebox |
| 2026-06-25 | ruvnet/ruflo | agent-os | Claude 메타하네스(멀티에이전트 스웜·적응형메모리·RAG) — 메타하네스 우리 ✅보유라 갭 아님. **경쟁정보용 rel-2만**(ECC·revfactory/harness 동일취급, 능력획득 아님) | 🔍 스웜/적응형메모리 패턴 마이닝(경쟁정보) | 2 | https://github.com/ruvnet/ruflo |
| 2026-06-25 | fivetaku/insane-search | fetch | 차단사이트 **fetch 우회** 스킬(Phase0→3: WebFetch→Jina→curl UA변형→curl_cffi TLS임퍼소네이션→Playwright). gstack /browse(인터랙티브 브라우징)와 **다른 축=read fetch fallback** — 블로그/리서치가 Naver·Coupang·LinkedIn 차단 시 자동 우회 | ✅ 설치완료(plugin, 대표님 요청) | 3 | https://github.com/fivetaku/insane-search |

## 드롭 로그 (rel 0~1, 기록만 — 재상신 방지)
- ✅ 보유(검증): bytedance/deer-flow(=우리 superagent), omnigent-ai/omnigent(=메타하네스), DietrichGebert/ponytail(=Karpathy G2)
- ❌ 무관: tursodatabase/turso, ZhuLinsen/daily_stock_analysis, tamnd/kage, zhongerxin/Cowart
- 2026-06-25 ✅보유/중복 드롭: garrytan/gstack(이미 설치=우리 /browse 경로), langbot-app/LangBot(=OpenClaw 게이트웨이 ✅강점), firecrawl·Panniantong/Agent-Reach(=tavily+web_fetch 보유, P-109), NVIDIA/skills(스킬소스 중복), web-infra-dev/midscene(=claude-in-chrome 비전), aws/agent-toolkit-for-aws(AWS특화·저관련), stanford-oval/storm(=우리 deep-research), abhigyanpatwari/GitNexus(=codebase-memory-mcp). 재출현 검증드롭: bytedance/deer-flow.
- 2026-06-25 ❌무관 드롭: koala73/worldmonitor, scrapy, wezterm, grafana, Stirling-PDF, paperless-ngx, MentraOS, karpathy/autoresearch(GPU훈련 특화), JCodesMore/ai-website-cloner-template; 재출현: tursodatabase/turso, ZhuLinsen/daily_stock_analysis.

## 평가 결과 (2026-06-22, watchlist 🎯 후보)
- **DeusData/codebase-memory-mcp → ✅ 설치+CLI검증 완료 (2026-06-22)**: binary v0.8.1 설치(`--skip-config`, OpenClaw 무영향), CLI로 harness 인덱싱 **2초/7498노드·8706엣지**(vs Understand-Anything 31min/$12) + search_graph·get_architecture 정상. ⚠️ **MCP 네이티브 등록 보류** — ~/.claude.json(157KB 라이브 상태)+OpenClaw config 수정이라 대표님 확인 후(또는 Claude Code 종료 시 백업+머지). 당장은 `codebase-memory-mcp cli …`로 활용. 원본 권장근거: 코드베이스 영속 지식그래프 MCP, **120x 토큰절감**(구조 쿼리 ~3.4k vs 파일탐색 412k), 단일 static 바이너리(deps·API키 0), 설치 시 Claude Code/Codex/OpenClaw MCP·hook 자동구성. **Understand-Anything($12 pnpm·1회 스냅샷) 대체/보완** — 라이브·저토큰·경량. 위험 낮음(단일 binary·무인증·로컬) → 설치 시도+검증 권장. (단 최근 codex MCP 사태 고려: 단일 binary·무인증임을 확인하고 도입, 동시 갱신 경쟁 없음.)
- **vercel/eve → study only**: TS 프레임워크라 직접 채택 X. 가치는 **durable execution 모델**(이벤트로그·스텝 체크포인트·last-good 재개·crash/deploy 생존) — 이를 `rules/durable-execution.md`(#1 격차 설계)에 반영 완료.

## 평가 결과 (2026-06-25)
- **fivetaku/insane-search → ✅ 설치완료 (2026-06-25, 대표님 요청)**: `claude plugin marketplace add fivetaku/gptaku_plugins` + `claude plugin install insane-search@gptaku-plugins`(user scope, **v0.8.2**, skill 1·agent/hook/MCP 0, **~250 always-on / ~4.3k on-invoke**, **다음 Claude 재시작 적용**). **공식 first-party plugin CLI** 경로 → ~/.claude.json 수동편집 불필요(= codebase-memory-mcp 네이티브등록 보류 사유와 구별, config 자체관리·재시작반영). 역할: WebFetch→Jina→curl UA→curl_cffi TLS→Playwright **5단계 적응 fetch fallback** + 숨은 API 발견. gstack /browse(인터랙티브)와 **보완**(read fetch vs interactive browse). ⚠️ **CAUTION(에이전트 교차검수)**: ① curl_cffi·feedparser·yt-dlp **자동 pip install** = 공급망 신뢰면, ② TLS임퍼소네이션·WAF우회 = 대상 사이트 **ToS 위반·IP밴 소지**, ③ 스킬이 로컬 셸/파이썬을 사용자 권한으로 실행. repo는 정상(fivetaku/GPTaku, ~257★·MIT). **codex 외부검수는 타임아웃(P-262 재발)** → 에이전트 단독 검수로 진행.
