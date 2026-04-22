# P-054: Stitch 디자인 → 코드 변환 시 세부 요소 누락

**증상**: 라이브 구현이 Stitch 디자인 스크린샷과 비교했을 때 부분 누락 발생.
- 로고 서브타이틀, 상태 배지 종류, 데이터 행 수, 배너 내 인라인 칩 등 사소한 요소들이 빠짐

**원인**: Stitch → 코드 사이에 검수 게이트 없음. 2가지 패턴으로 발생:
1. `fetch_screen_code`의 HTML 코드를 전부 참조하지 않고 구조만 보고 재구현 → 세부 누락
2. Mock 데이터로 된 KPI/배지를 "실데이터로 대체"하면서 Stitch 표현 의도를 드롭

**해결**: `/design-review` 실행 → 불일치 항목 픽스 → 재배포

**재발 방지**:
1. Stitch 생성 직후 반드시 `/design-review` 실행 (스킵 금지)
2. 코드 구현 시 `mcp__stitch__fetch_screen_code` + `mcp__stitch__fetch_screen_image` 를 **동시에** 열어두고 pixel-level로 대조
3. Mock 데이터를 실데이터로 교체할 때 Stitch 스크린의 표현 구조(배지 종류, 행 수 등)는 반드시 유지
4. 배포 후 `mcp__expect__screenshot` → Stitch 스크린샷과 나란히 비교를 PR 체크리스트에 포함

**2026-04-21 추가 방어층 (drift-guard 통합)**:
5. UI 프로젝트는 `npx drift-guard init --from design.html` → `npx drift-guard rules` 선행. 이후 자동 gate 발동:
   - `stitch-drift-guard.sh` hook: `mcp__stitch__*` 호출 후 init/check 유도
   - `/pipeline-run` Step 3-0: 시각 검수 전 drift-guard check 필수
   - `verify-deploy.sh`: 배포 전 `.drift-guard.json` 감지 시 check 실패면 exit 2 차단
6. Vision(`/design-review`)은 시각 인상, drift-guard는 CSS 토큰·DOM 구조 — 두 레이어 병행
