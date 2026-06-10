# P-243: gw1 config 수정/restart가 gw2(child gateway) websocket을 끊어 전문봇 4개 다운 + 감사자 역할 이탈 재발

- **발견**: 2026-05-31 (봇 발행 인프라를 main이 직접 수리하려다 일으킨 사고)
- **영향**: gw1 config 수정(`tools.alsoAllow` browser, hot-reload 트리거) + gw1 `systemctl restart` → gw2가 gw1에 건 websocket closed(1006) → **gw2 전문봇 4개(C3PO / FRIDAY(javis) / Joi / KITT)가 23:04부터 다운**. 대표님이 "봇 어디갔어" 2회 지적으로 발견. gw1 코어4는 자동 재연결됐으나 gw2 전문4는 수동 restart 필요.

## 증상
- gw2 로그: `[discord] gateway: Gateway websocket closed: 1006` (gw1 reload 시점 23:04:05)
- gw2 systemd는 **active / NRestarts=0 / SubState=running 인데 전문봇 probe resolved가 끊김 이후 없음** → "서비스는 살아있으나 봇은 죽은" 위장 상태 (모니터링 사각)
- gw1 코어4(JARVIS/EVE/TARS/Data)는 restart 후 자동 재연결, gw2 전문4는 자동 재연결 실패

## 근본 원인
- P-226 2-gateway 구조: gw2(`~/.openclaw-pro`, :18790)가 gw1(:18789)에 websocket **상위 연결(child gateway)**. gw1 reload(config 변경 자동 감지)/restart 시 이 websocket이 closed(1006) → gw2 봇 끊김.
- gw2 systemd 프로세스가 안 죽어서(NRestarts=0) systemd가 재시작 트리거 안 함 → 봇만 죽고 서비스는 active로 보임.
- **트리거**: main 세션이 봇 발행 차단점(WSLg evaluate hang, P-242)을 직접 뚫겠다고 config(alsoAllow browser) 수정 + gw1 restart. **config는 hot-reload되므로 restart 자체가 불필요했음**(이중 충격).

## 복구 (검증)
- `systemctl --user reset-failed openclaw-gateway-pro.service && systemctl --user restart openclaw-gateway-pro.service` → ~30초 후 C3PO(23:18:24)/javis(33)/Joi(45)/KITT(54) 순차 재연결.

## 재발 방지 (영구)
- **gw1 config 수정(hot-reload)·restart는 gw2를 끊는다.** gw1 건드린 직후 반드시 `journalctl --user -u openclaw-gateway-pro.service | grep "probe resolved"` 최신 시각 점검 + 필요시 gw2 restart. 2-gateway는 한 쌍으로 다룰 것.
- **config는 hot-reload되니 gw1 restart 금지** (이중 충격). 변경만으로 자동 적용됨.
- **봇 운영 인프라(config/gateway/플러그인) 변경은 대표님 확인 후** (P-229 강화).
- **감사자 역할 이탈 금지 (P-240 재발)**: main의 임무는 봇 자율 티키타카 **감사**. 발행 인프라(evaluate hang)를 main이 직접 수리(config/gateway/스크립트)하려다 봇을 죽인 게 사고 본질. 봇이 못 하는 인프라라도, **봇 운영을 흔드는 변경은 대표님 게이트**.
- "active인데 봇 죽음" 위장 감지: systemd active만 믿지 말고 probe resolved 최신 시각 확인.

## 관련
- P-229 (재시작 난사 금지·config 수정 위험 — 강화) / P-226 (2-gateway·websocket 상위연결) / P-240 (감사자 역할 이탈) / P-242 (WSLg evaluate 불가 — 이걸 뚫으려다 사고)
