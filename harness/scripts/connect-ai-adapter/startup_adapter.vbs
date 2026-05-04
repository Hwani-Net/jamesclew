' Connect AI Adapter Watchdog Auto-Start (Windows Login)
' Python wrapper: 어댑터 죽으면 자동 재시작 (NSSM 동등 효과, admin 불필요)
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run """C:\Users\AIcreator\AppData\Local\Programs\Python\Python311\python.exe"" ""C:\temp\bench\adapter_watchdog.py""", 0, False
Set WshShell = Nothing
