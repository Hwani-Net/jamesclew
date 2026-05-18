# P-154: tavily-rotator fetch monkey-patch는 v0.1.4부터 무효 — axios 인터셉션 필요

- **발견**: 2026-05-15
- **검증 완료**: 2026-05-15 (standalone test, HTTP 401 → 회전 → 200 + state 파일 생성)
- **영향**: tavily 멀티계정 회전이 **하네스 초기부터 단 한 번도 작동하지 않았음**. 키 1번이 매번 사용되어 한도 초과 시 모든 호출 실패. P-057 (432 누락)도 잘못된 진단 위에 세워졌음.

## 증상

- `~/.claude/tavily-keys.json`에 6개 키가 있어도 첫 키만 매번 호출됨.
- 1번 키 한도 초과(HTTP 432) 시 `"This request exceeds your plan's set usage limit"`로 모든 Tavily 검색이 실패.
- `~/.harness-state/tavily-rotation-index.json` 파일이 한 번도 생성된 적 없음 (회전이 한 번도 발생 안 함).

## 근본 원인

`tavily-mcp` (npm 패키지)는 **v0.1.4부터 줄곧 `axios` 사용**. `globalThis.fetch` monkey-patch는 axios를 가로채지 못함.

- 확인: `npm pack tavily-mcp@0.1.4` → `build/index.js`에 `import axios from "axios"` (v0.2.18까지 동일)
- 우리 원본 `tavily-rotator.mjs`는 `globalThis.fetch` monkey-patch만 — axios 호출은 그대로 통과
- 결과: 회전 로직이 **단 한 번도 발동한 적 없음**

### 시도해본 우회 (모두 실패)
1. **CJS `createRequire("axios")` + axios.create monkey-patch**: 우리 axios instance에는 patch 적용되지만 tavily-mcp는 ESM `import axios from "axios"` 사용 → **Node ESM/CJS dual-package-hazard로 별개 module instance**. patch 무효.
2. **ESM `await import(axiosResolvedPath)`**: 같은 path를 ESM으로 import해도 module cache 분리되어 별개 instance. 무효.

## 진짜 해결 (검증 완료)

### 1단계: tavily-mcp/build/index.js 직접 patch (1줄)

`import axios from "axios";` 다음에:
```js
globalThis.__TAVILY_MCP_AXIOS__ = axios;
```

이로써 **tavily-mcp가 실제로 사용하는 axios module instance**가 `globalThis`에 노출.

### 2단계: 우리 `tavily-rotator.mjs`에 setter trap

```js
let _axiosRef = null;
Object.defineProperty(globalThis, "__TAVILY_MCP_AXIOS__", {
  configurable: true,
  set(v) { _axiosRef = v; patchAxios(v); },  // tavily-mcp가 할당하는 순간 patch
  get() { return _axiosRef; },
});
```

`patchAxios()`는 `axios.defaults.adapter` + `axios.create`를 우리 `fetchAdapter`로 교체. fetchAdapter는 우리 monkey-patched `globalThis.fetch`를 호출 → 기존 회전 로직 재사용.

### 3단계: 패키지 업데이트 자동 재적용

`harness/scripts/patch-tavily-mcp.sh` — idempotent. `npm install -g tavily-mcp` 또는 `npm update -g tavily-mcp` 후 실행. 이미 patch돼 있으면 no-op.

## 검증 (2026-05-15)

`D:/jamesclew/.tmp-rotation-verify.mjs` standalone test:
- 슬롯 1에 가짜 키 `tvly-dev-FAKEKEY_FORCE_ROTATE_TEST` 주입
- 직접 `axios.post("https://api.tavily.com/search", ...)` 호출
- 결과:
  - `[tavily-rotator] Key #1 exhausted (HTTP 401), rotating to #2`
  - `SUCCESS status=200`
  - state file: `{"currentKeyIndex": 1, "updatedAt": "...", "keyCount": 7}`
- ✅ patch 적용 + 회전 발생 + state 영속화 모두 확인

## 재발 방지

- **MCP 패키지가 어떤 HTTP 클라이언트 사용하는지 매번 확인.** `fetch` 가정 금지.
- ESM/CJS dual-package-hazard: 외부 패키지의 module instance를 우리가 가져온 instance와 동일하다고 가정하지 말 것. globalThis 노출 패턴 또는 setter trap이 안전.
- `npm update -g tavily-mcp` 후 반드시 `bash harness/scripts/patch-tavily-mcp.sh` 실행 — deploy.sh 통합 후속.
- 회전 메커니즘은 반드시 **실측 검증** (fake key 주입 → 회전 → state 파일 생성 확인). "patch 적용 = 작동"이라고 추정 금지.

## 관련

- [[pitfall-057-tavily-rotator-432-miss]] — 432 누락 진단 (그러나 실제로는 회전 자체가 안 됐던 거임)
- [[pitfall-152-tavily-rotator-state-not-persistent]] — 상태 영속화 fix (P-154와 함께 적용)
