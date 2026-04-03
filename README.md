# JamesClaw Agent Harness

자율 실행 에이전트 "JamesClaw"의 하네스 설정 저장소.

## 구조

```
harness/
├── CLAUDE.md              # 에이전트 규칙
├── settings.json          # hooks, permissions, plugins
├── deploy.sh              # ~/.claude/에 배포
├── hooks/
│   ├── telegram-notify.sh # 알림 + usage + context
│   ├── verify-subagent.sh # hallucination 1계층
│   └── verify-memory-write.sh # hallucination 2계층
├── rules/
│   ├── architecture.md    # 도구 선택, tool budget, context
│   ├── quality.md         # 검증, self-healing, commits
│   └── security.md        # secret 보호, 파괴적 명령 차단
├── scripts/
│   ├── tavily-rotator.mjs # Tavily 6키 로테이션 MCP 래퍼
│   └── enhance-personas.mjs # 옵시디언 페르소나 AI 보강
└── keys/
    ├── tavily-keys.example.json
    └── openrouter-keys.example.json
```

## 배포

```bash
bash harness/deploy.sh
```

## 키 파일 (git 미추적)

실제 키 파일은 `~/.claude/`에 직접 관리:
- `~/.claude/tavily-keys.json`
- `~/.claude/openrouter-keys.json`
