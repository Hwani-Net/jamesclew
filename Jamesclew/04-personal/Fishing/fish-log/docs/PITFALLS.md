

## ❌ 시뮬레이션 알림이 새벽에 작동 안 함 (2026-03-03)
- **증상**: /alerts 페이지에서 "테스트 알림 발송" 클릭해도 아무 반응 없음
- **원인**: `sendLocalNotification()`이 quietHours(23:00~06:00) 체크 → 04:27 AM 이므로 차단
- **해결**: `sendSimulationAlert()`에서 `sendLocalNotification` 우회 → 직접 `new Notification()` 생성
- **🚫 금지**: 시뮬레이션/테스트 전송 함수를 quietHours 로직이 있는 공용 함수에 연결하지 말 것. 테스트는 항상 직접 `new Notification()` 사용.
