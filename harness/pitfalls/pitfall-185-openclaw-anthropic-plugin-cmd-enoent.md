# P-185: OpenClaw anthropic plugin Native Windows에서 `spawn claude ENOENT`

- **발견**: 2026-05-20
- **영향**: default model을 `anthropic/claude-*`로 설정 시 봇 응답 단계에서 spawn 실패 → 무응답.

## 증상

```
log: spawn failed: runId=<uuid> reason=Error: spawn claude ENOENT
log: Embedded agent failed before reply: spawn claude ENOENT
```

`claude.cmd`는 `C:\Users\<user>\AppData\Roaming\npm\claude.cmd`에 존재하지만 Node `spawn('claude', args, {shell:false})`로는 찾지 못함 (Windows의 `.cmd` 확장자 + PATHEXT 인식은 `shell:true`에서만 동작).

## 원인

OpenClaw anthropic plugin (`extensions/anthropic/cli-backend.js` 등)이 `spawn('claude', ...)`를 호출. **Windows .cmd 분기 코드 부재** — grep으로 `claude.cmd` / `win32.*claude` 매칭 0건.

비교: codex plugin은 정상 분기:
```javascript
const commandName = platform === "win32" ? "codex.cmd" : "codex";
```

`resolveWindowsSpawnProgram` + `materializeWindowsSpawnProgram` 헬퍼가 codex 측에만 적용됨.

## 해결

- **A. WSL2 전환** (근본): WSL Linux에선 `.cmd` 자체 없음
- B. default model을 `openai/gpt-5.5` + codex runtime으로 사용 (codex plugin은 Windows 정식 지원). 단 P-184 readiness 결함은 별개 차단 사유
- C. anthropic plugin 코드 패치 — minified + 업데이트 시 깨짐
- API key 등록은 ENV var 사용해도 spawn 경로 자체를 우회하는지 미확정

## 진단 스니펫

```bash
# Node spawn ENOENT 재현
node -e "
const {spawnSync}=require('child_process');
console.log('shell:false ->', spawnSync('claude',['--version'],{shell:false}).error?.code);
console.log('shell:true  ->', spawnSync('claude',['--version'],{shell:true,encoding:'utf8'}).stdout?.slice(0,40));
"
# 결과:
# shell:false -> ENOENT
# shell:true  -> 2.1.144 (Claude Code)
```

## 재발 방지

- npm 글로벌 CLI를 Node `spawn`으로 호출하는 도구는 Windows에서 `.cmd` 명시 호출 또는 `shell:true` 필요. `cross-spawn` 패키지 사용 권장.
- OpenClaw 같은 multi-channel 도구 도입 전 plugin source에서 `commandName.*win32|\\.cmd` 분기 확인 필수.

## 관련

- [[pitfall-184-openclaw-windows-discord-readiness]]
