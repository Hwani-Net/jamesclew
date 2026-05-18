---
slug: pitfall-118-adapter-korean-stdout-encoding
title: Connect AI 어댑터 한국어 stdout CP949/UTF-8 인코딩 불일치
date: 2026-05-05
severity: medium
status: open
---

# Connect AI 어댑터 한국어 stdout CP949/UTF-8 인코딩 불일치

## 증상
`C:/temp/bench/connect_ai_adapter_v3.py` (포트 4142) 어댑터에서 codex-cli 라우트 응답 중 한국어 텍스트가 깨져서 stdout으로 출력됨.

- 영문 텍스트 + 코드 블록(PowerShell, JSON 등)은 정상
- 한국어 본문 (codex의 자연어 답변) 일부가 ?? 또는 mojibake로 변환
- claude-cli 라우트는 영향 없음 (claude CLI 자체가 UTF-8 stdout)
- copilot-api 라우트도 영향 없음 (HTTP JSON 응답)

## 발생 시나리오
- 2026-05-05 13:30 — Developer 에이전트 시뮬레이션으로 블로그 자동발행 진단 호출
- 모델: gpt-5.3-codex (codex-cli 라우트)
- 응답: 한국어 진단 본문이 stdout 인코딩 불일치로 깨짐. 단 ASCII 명령(`schtasks`, `node`, `curl` 등)은 정상

## 원인
Windows 기본 콘솔 인코딩이 CP949 (한국어 환경). Python `subprocess.Popen(encoding="utf-8")`로 codex stdout을 읽지만, codex 자체가 일부 OS API를 거쳐 출력될 때 CP949로 인코딩되는 경로가 있음.

`call_codex_cli()` 함수 (adapter_v3.py L196 부근):
```python
result = subprocess.run(
    f'codex exec --json --skip-git-repo-check -m {model_id} -',
    input=prompt, capture_output=True, text=True, encoding="utf-8",
    timeout=timeout, shell=True,
)
```

`shell=True`로 cmd 경유 시 cmd 콘솔 코드페이지(936=CP949)가 영향. UTF-8 강제가 codex 자체에 도달하지 않는 경우 발생.

## 해결
어댑터 v6.3에서 다음 환경변수 강제:

```python
env = os.environ.copy()
env["PYTHONIOENCODING"] = "utf-8"
env["PYTHONUTF8"] = "1"
env["LANG"] = "en_US.UTF-8"  # codex 일부 경로 대응
result = subprocess.run(
    f'chcp 65001 >NUL && codex exec --json --skip-git-repo-check -m {model_id} -',
    input=prompt, capture_output=True, text=True, encoding="utf-8", errors="replace",
    timeout=timeout, shell=True, env=env,
)
```

추가:
- `chcp 65001`로 cmd 코드페이지를 UTF-8로 변경
- `errors="replace"`로 mojibake 발생 시 ?로 대체 (크래시 방지)

## 재발 방지
- claude-cli, openai-direct, copilot-api 라우트도 동일 패턴 적용 (방어적)
- 어댑터 시작 시 `os.environ["PYTHONIOENCODING"] = "utf-8"` 글로벌 설정
- 검증: 한국어 1000자 응답을 받아 mojibake 없는지 확인

## 영향 범위
- Developer/CEO 에이전트가 codex/claude-cli 라우트 사용 — 한국어 본문 응답 깨짐 시 진단 가독성 저하
- Connect AI Office Panel UI에는 영향 적음 (HTTP JSON 응답 경로는 정상)
- 어댑터 stderr 로그(`adapter_v3.log`)는 정상 (별도 인코딩 경로)

## 검증 사례
- 2026-05-05: `D:/smartreview-blog` 진단 시 한국어 본문 일부 깨짐. 그러나 ASCII 명령은 정상 추출되어 진단 결과 자체는 사용 가능.
- 데이터 기반 진단(추측 없음)은 정상 작동 — 인코딩은 표시 레이어 문제
