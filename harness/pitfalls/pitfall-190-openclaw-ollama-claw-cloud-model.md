# P-190: OpenClaw ollama claw 봇 — Windows host Ollama 경유 cloud 모델 사용

- **발견**: 2026-05-20
- **영향**: 3번째 의견 봇이 로컬 gemma3:4b로는 신뢰도 부족 → cloud 모델 필수

## 증상

- ollama claw 봇이 WSL 내부 Ollama (v0.7.0 → 자체 빌드) + gemma3:4b 로 가동
- 대표님 평가: "gemma3는 너무 옛 모델 — cloud 정도는 써줘야 의견이라도 신뢰"
- WSL Ollama 0.7.0은 `ollama signin` 미지원 (cloud 기능 부재)
- 최신 v0.24.0 자산은 `.tar.zst` 압축 (zstd 필요, sudo 차단)

## 원인

- 직접 다운로드 시 `releases/latest/download/ollama-linux-amd64.tgz` 경로가 구버전 v0.7.0 캐시 반환
- Cloud 모델 pull은 ollama v0.11+ 필요 (`signin` 커맨드)
- 자체 WSL 빌드 경로는 sudo · zstd 의존 → 막힘

## 해결 (검증됨)

**Windows host Ollama (v0.24.0, signin 완료, cloud 모델 다수 보유) 경유**

1. Windows 환경변수: `setx OLLAMA_HOST 0.0.0.0:11436` (이미 설정됨, 11436 포트)
2. WSL → Windows host IP: `ip route | awk '/default/ {print $3}'` (예: `172.23.192.1`)
3. ollama-relay/.env:
   ```
   OLLAMA_URL=http://172.23.192.1:11436/api/chat
   OLLAMA_MODEL=deepseek-v3.1:671b-cloud
   ```
4. `systemctl --user restart ollama-relay`

선택 모델: **gemma4:31b-cloud** (Google family, 31B, free tier 동작 확인)

### Ollama Cloud Free tier 동작 매트릭스 (2026-05-20 검증)
| 모델 | Free tier | 비고 |
|------|-----------|------|
| `gemma4:31b-cloud` | ✅ | Google, 3rd opinion 추천 (family 다양성) |
| `qwen3-coder:480b-cloud` | ✅ | Alibaba, 480B, 코딩 특화 대안 |
| `deepseek-v3.1:671b-cloud` | ❌ | 유료 구독 필요 |
| `glm-5.1:cloud` | ❌ | 유료 구독 필요 |
| `kimi-k2.6:cloud` | ❌ | 유료 구독 필요 |
| `minimax-m2.7:cloud` | ❌ | 유료 구독 필요 |

**교훈**: Ollama Cloud의 큰 모델 대부분은 유료. 무료 tier는 gemma4·qwen3 계열만. cloud 모델 도입 시 free tier 동작 사전 검증 필수 (`curl /api/chat`으로 403/200 즉시 확인).

## 잔존 리스크

- **WSL2 NAT IP 변동성**: `172.23.192.1`은 WSL 재시작 시 변경 가능. relay 시작 실패 시 index.js에 동적 IP 조회 로직 추가 필요:
  ```javascript
  const wslGateway = (await execAsync("ip route | awk '/default/ {print $3}'")).stdout.trim();
  process.env.OLLAMA_URL = `http://${wslGateway}:11436/api/chat`;
  ```
- WSL mirrored networking 모드면 `localhost`로 통일 가능 — `.wslconfig`에 `[wsl2] networkingMode=mirrored` 설정 검토
- Windows host Ollama가 종료되면 봇 응답 끊김 → systemd watchdog 또는 startup hook 필요

## 재발 방지

- 새 봇/도구에 모델 지정 시 무조건 cloud-capable 버전 확인 (`ollama signin --help` 동작 여부)
- WSL 자체 빌드보다 Windows host 노출 (OLLAMA_HOST=0.0.0.0) 우선 — 모델 재pull 비용·디스크 절약
- 로컬 소형 모델은 "테스트용" 명시 — 운영엔 cloud 또는 대형 로컬(31B+)

## 관련

- [[pitfall-184-openclaw-windows-discord-readiness]]
- [[pitfall-187-openclaw-wsl2-deployment-success]]
- [[pitfall-188-openclaw-wsl2-deployment-complete-2026-05-20]]
- CLAUDE.md "External Model CLI Reference" — GLM-5.1:cloud 명시
- ORCHESTRATION.md §9 (3번째 봇 등록)
