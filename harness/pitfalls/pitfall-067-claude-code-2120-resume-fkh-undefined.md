---
slug: pitfall-067-claude-code-2120-resume-fkh-undefined
title: "Claude Code v2.1.120 --continue/--resume 크래시 (FKH/g9H is not a function)"
date: 2026-04-25
tier: raw
tags:
  - pitfall
  - claude-code
  - resume
  - regression
versions:
  - "2.1.120"
broken_in: "2.1.120 (2026-04-24 자동 업데이트)"
last_working: "2.1.119"
fixed_in: "2.1.121 (2026-04-27)"
upstream_issue: "https://github.com/anthropics/claude-code/issues/53086"
upstream_state: "RESOLVED (2.1.121 changelog: 'Fixed --resume crashing on startup in external builds')"
duplicates: ["#53041", "#53064", "#53079"]
---

# 증상

이전 세션을 `--continue` 또는 `/resume` 으로 재개할 때 즉시 크래시:

```
ERROR  FKH is not a function. (In 'FKH(K)', 'FKH' is undefined)
B:/~BUN/root/src/entrypoints/cli.js:9273:5663
```

새 세션은 정상 동작. **resume 경로에서만 재현**.

# 원인 (minified 코드 역추적)

`REPL` 컴포넌트 mount effect:

```js
s8.useEffect(() => {
  if (K && K.length > 0)
    sW8(K, Kq()),
    GMq({ ... }),
    BIq(K),
    pc(K),
    oMH.current.current = I38(K, Fq),
    FKH(K)          // ← crash
}, []);
```

- `K` = `initialMessages` (resume 시 이전 세션 메시지로 채워짐)
- `FKH` = `XJ7({ enabled: S }).onSessionRestored`
- `S = useMemo(() => !1, [])` → 항상 `false`
- `XJ7` 가 `enabled: false` 일 때 `onSessionRestored` 를 반환하지 않음 → `FKH = undefined`
- 그러나 `K.length > 0` 이면 가드 없이 `FKH(K)` 호출 → 크래시

→ **resume 경로 전용 가드 누락**. v2.1.116~118 의 `/resume` 가속·summarize·`--continue` 범위 확장 회귀로 추정.

# 해결 (검증된 공식 워크어라운드 — Issue #53086 본문 기준)

1. **다운그레이드 (가장 확실)**: `npm i -g @anthropic-ai/claude-code@2.1.119`
2. **REPL 내부 `/resume` 사용 (코드 패스 회피)**:
   ```bash
   claude --new                    # 빈 세션 시작 (K=[]이라 effect skip)
   # REPL 내부:
   /resume <session-id>            # 다른 함수 경로 → 안 깨짐
   ```
3. (실패 시) 새 세션 + 옵시디언 직전 저장본 `Read` 로 컨텍스트 수동 복원

⚠️ **CLI 플래그 `--continue`, `--resume <id>`는 2.1.120 에서 100% 깨짐**. 절대 사용 금지.

# 재발 방지

- v2.1.121+ 출시 시 changelog `Fixes Issue #53086` 또는 `g9H?.()` 옵셔널 체이닝 확인 후 업그레이드
- 변수명은 빌드별 minify 로 매번 달라짐 (FKH/g9H/...). 매칭 키는 **`is not a function. (In '*(K)', '*' is undefined)` + `cli.js:~9270:5663` + 2.1.120**
- 세션 저장 시 옵시디언 백업을 항상 유지 (45% compact 규칙)
- 자동 업데이트 차단 옵션 검토: `DISABLE_UPDATES=1` env var (v2.1.118+ 신규)
