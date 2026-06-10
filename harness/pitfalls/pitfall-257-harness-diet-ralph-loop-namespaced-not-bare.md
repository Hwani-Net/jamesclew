# PITFALL-257 — harness-diet: 플러그인 namespaced 슬래시는 bare command를 대체하지 못함 (실측 없는 "대체" 보고 → 회귀)

**날짜**: 2026-06-05
**분류**: harness 리팩터링 / 거짓 검증(skip_review) / command 라우팅
**연결**: [[pitfall-082-deferred-to-user-without-attempting-direct-action]], [[pitfall-194-premature-conclusion]] family, harness-legacy-scan Adversarial Reviewer 경고

## 증상

`/harness-diet`에서 `commands/ralph-loop.md`(17줄 래퍼)를 "네이티브 `/ralph-loop` 플러그인과 동명 중복"이라 판단해 archive로 이동. 보고서 smoke-test #2에 "네이티브 플러그인이 정상 대체"라고 기재. 대표님이 실제로 `/ralph-loop 테스트 작업 시작` 실행 → **`Unknown command: /ralph-loop`** (FAIL).

## 원인

1. **namespaced ≠ bare**: 플러그인 ralph-loop은 `commands/`에 cancel-ralph/help/ralph-loop를 갖지만 **모두 `ralph-loop:ralph-loop` 형태(namespaced)로만 호출**된다. bare `/ralph-loop`은 우리 `commands/ralph-loop.md`가 유일 제공자였다. 둘은 **충돌이 아니라 공존**(다른 네임스페이스)이었으므로 "동명 중복" 판단 자체가 오류.
2. **실측 없는 보고(skip_review)**: 제거 후 bare `/ralph-loop`이 실제로 동작하는지 **직접 실행하지 않고** "정상 대체"라고 단언. smoke-test를 설계만 하고 적용 직후 스스로 돌리지 않음.
3. **Adversarial 경고 무시**: 선행 harness-legacy-scan의 Adversarial Reviewer가 정확히 "어느 쪽이 우선 호출되는지 실측 확인하지 않은 채 삭제하면 침묵 손실"이라 **CONDITIONAL** 권고했으나, watchdog 연계(무관)만 확인하고 대체 동작은 검증하지 않음.

## 해결

- `archive/harness-diet-2026-06-05/ralph-loop.md` → `commands/ralph-loop.md` **복원**(소스+배포본 양쪽). skill 목록에 `ralph-loop: Start Ralph Loop` 재등장 확인.
- wiki-sync.md는 `user_invocable:false`라 bare `/wiki-sync`이 원래 호출 불가 → 제거해도 회귀 없음(archive 유지).

## 재발 방지

1. **command 제거 전 "이 bare 슬래시를 무엇이 대체하는가"를 실측**. 플러그인 namespaced 슬래시(`plugin:cmd`)는 bare `/cmd`를 **대체하지 않는다**. 같은 이름이라도 네임스페이스가 다르면 공존이며, bare 제공자를 지우면 bare가 사라진다.
2. **smoke-test는 설계로 끝내지 말고 적용 직후 작성자가 직접 실행**. 사용자에게 회귀 검출을 떠넘기지 않는다(P-082 변형).
3. Adversarial/critic이 CONDITIONAL/PRESERVE를 단 항목은 dietAuto(무승인 자동처리)에서 제외하고 실측 게이트를 통과해야 PROCEED.
