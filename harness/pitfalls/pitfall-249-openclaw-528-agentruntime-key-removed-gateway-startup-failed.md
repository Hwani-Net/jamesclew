# P-249: openclaw 5.28 업데이트 → `agents.defaults.agentRuntime` 폐기로 gateway startup_failed

- **발견/해결**: 2026-06-02 (대표님 "버전 업데이트 했더니 게이트웨이가 시작 안 됨")
- **영향**: 5.27→5.28 자동 업데이트 후 gateway가 1.7s 만에 exit code 1, restart 5회 후 "Start request repeated too quickly"로 완전 정지. 9봇 전원 다운.

## 증상
- `systemctl --user is-active openclaw-gateway.service` = **failed**. 포트 18789 없음.
- 로그: `Gateway failed to start: Invalid config at .../openclaw.json` → `agents.defaults: Invalid input` → `Run "openclaw doctor --fix"`.
- `doctor` 정확 사유: **`agents.defaults: Unrecognized key: "agentRuntime"`**
- stability bundle: `~/.openclaw/logs/stability/openclaw-stability-*-gateway.startup_failed.json`

## 근본 원인 (실측)
- 5.28이 config 스키마를 엄격화 — **`agents.defaults` 직속 `agentRuntime` 키를 폐기**(이전 5.27까지 valid였음).
- 모델별 `agents.defaults.models.<name>.agentRuntime`은 **여전히 유효**(이건 거부 안 함). 폐기된 건 defaults 최상위 `agentRuntime: {id: claude-cli}` 하나뿐.
- P-229(5.22→5.27 harness 미등록)와 같은 "버전 자동 업데이트 = 시한폭탄" 패턴의 config-스키마 변종.

## 해결 (검증됨)
1. config backup: `cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak-pre-528fix-$(date +%Y%m%d-%H%M%S)`
2. **타겟 제거**(P-229 교훈 — doctor --fix 난사 대신 정확한 키만): python으로 `del d["agents"]["defaults"]["agentRuntime"]` 후 저장.
3. 검증: `node .../dist/index.js doctor` → Invalid/Unrecognized 사라짐(doctor가 models 키 일부 자동 "Upgraded" 출력 — 정상 마이그레이션).
4. `systemctl --user reset-failed openclaw-gateway.service` → `start`(restart 난사 금지, P-229).
5. 포트 18789 확인 + 9봇 connect(startup grace ~90s, 0→9 점진). 검증: 9/9 connected.

## 잔여 주의
- **gw2(.openclaw-pro) config에도 동일 `agents.defaults.agentRuntime`이 있으면** gw2 부활 시 같은 에러. 단 gw2는 P-226 폐지로 disabled — 부활 금지(CLAUDE.md). 부활시키려면 같은 키 제거 선행.
- 실제 실행 버전은 `index.js --version`(5.28)으로 확인. systemd unit Description의 "v2026.5.18"은 표기 잔재(P-224 주의와 동일).

## 재발 방지
- **OpenClaw 자동 업데이트 후 gateway 안 뜨면 1순위로 `doctor`** → `Unrecognized key`/`Invalid input` 정확 사유 확인 → 해당 키만 타겟 수정. 추측 수정·doctor --fix 난사 금지.
- 버전 업데이트는 P-229/P-249 누적상 **반복 시한폭탄** — 업데이트 직후 gateway active + 봇 9 connected 실측 필수.

## 관련
- [[pitfall-229-openclaw-522-harness-bug-527-recovery]] (5.22→5.27 harness, 버전 시한폭탄 원형)
- [[pitfall-245-openclaw-codex-harness-model-must-be-codex-provider]] (agents.defaults.models agentRuntime 구조)
- [[pitfall-224-wsl2-instance-idle-timeout-gateway-death]] (직전 재부팅 사례, Description 버전 표기 주의)
