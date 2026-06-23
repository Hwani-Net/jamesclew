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

## 드롭 로그 (rel 0~1, 기록만 — 재상신 방지)
- ✅ 보유(검증): bytedance/deer-flow(=우리 superagent), omnigent-ai/omnigent(=메타하네스), DietrichGebert/ponytail(=Karpathy G2)
- ❌ 무관: tursodatabase/turso, ZhuLinsen/daily_stock_analysis, tamnd/kage, zhongerxin/Cowart
