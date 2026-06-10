# P-244: WSL2 HCS_E_SERVICE_NOT_AVAILABLE = hypervisorlaunchtype 누락 → 봇 전체 다운 (BIOS 오인 주의)

- **발견/복구**: 2026-06-01 (봇 7개 운영 중 WSL2 급사)
- **영향**: WSL2 gateway(gw1+gw2) 전체 다운 = 이 PC 봇 7개(JARVIS/EVE/TARS/Data/C3PO/Joi/KITT) 전부 다운. 외부 PC 봇(hermes/openclaw)은 별개라 생존.

## 증상
- `wsl -d Ubuntu ...` → `Wsl/Service/CreateInstance/CreateVm/HCS/HCS_E_SERVICE_NOT_AVAILABLE` (exit 127)
- `wsl --shutdown`은 exit 0인데 재기동 시 또 HCS 에러
- `Get-Service vmcompute` → "Cannot find any service" (vmcompute 서비스 부재)
- `Get-Service HvHost` → Stopped (Start-Service 해도 Stopped 유지)
- **녹스 플레이어(안드로이드 에뮬)도 "가상화 설정 안됨" 경고** (동반 증상 — 같은 hypervisor 문제, 진단 단서)

## 근본 원인 (실측)
- **`HypervisorPresent=False`** = Windows hypervisor(Hyper-V)가 부팅 시 안 뜸 → vmcompute 미생성 → WSL2 VM 못 띄움
- **`bcdedit`에 hypervisorlaunchtype 항목 자체가 없음**(누락) → hypervisor 미기동
- ⚠️ **BIOS 가상화는 정상**: `systeminfo` → "Virtualization Enabled In Firmware: **Yes**" + "VM Monitor Mode Extensions: Yes" + "Second Level Address Translation: Yes". `Win32_Processor.VirtualizationFirmwareEnabled=True`.
  - → **BIOS/CMOS SVM 의심은 오진.** 녹스 경고 보고 BIOS 의심하기 쉬우나 데이터는 BIOS 정상. 진짜 원인은 Windows hypervisorlaunchtype.

## 해결 (검증됨)
1. **관리자 PowerShell**: `bcdedit /set hypervisorlaunchtype auto`
2. (보강) `dism /online /enable-feature /featurename:HypervisorPlatform /all /norestart` (+ VirtualMachinePlatform)
3. **재부팅** (필수 — bcdedit + 기능 enable이 부팅 시 적용)
4. 재부팅 후: `HypervisorPresent=True` 확인 → WSL2 자동 기동 → gateway systemd 자동 시작(P-223) → 봇 자동 복구
- **검증 완료**: 재부팅 후 HypervisorPresent=True, WSL2 uptime 5min, gw1/gw2 active, 봇 7개 probe resolved, TARS 응답 정상. config 수정(codex/gpt-5.5)도 파일이라 재부팅 후 유지.

## 재발 방지 (영구)
- **WSL HCS 에러 진단 순서**: ①`systeminfo | findstr "Virtualization Enabled In Firmware"` (Yes면 BIOS 정상 → CMOS 만지지 말 것) ②`Win32_ComputerSystem.HypervisorPresent` (False면 hypervisor 미기동) ③`bcdedit`에 hypervisorlaunchtype 있나(없으면 누락) ④`bcdedit /set hypervisorlaunchtype auto` + 재부팅
- **BIOS 의심 전에 Windows hypervisor 설정 확인.** BIOS 진입은 systeminfo가 펌웨어 가상화 "No"일 때만.
- 보드 참고: ASRock X570 Taichi / Ryzen 5800X3D / AMI BIOS. BIOS SVM 위치(정말 필요시): Advanced → CPU Configuration → SVM Mode → Enabled.

## 관련
- [[pitfall-224-wsl2-instance-idle-timeout-gateway-death]] (WSL2 죽음 family — 그건 vmIdleTimeout, 이건 hypervisorlaunchtype)
- [[pitfall-243-gw1-restart-breaks-gw2-websocket-specialist-bots-down]] (이번 세션 gateway restart 사고)
- CLAUDE.md STICKY DECISIONS 활성 자율 인프라 (WSL2 keepalive P-223/224)
