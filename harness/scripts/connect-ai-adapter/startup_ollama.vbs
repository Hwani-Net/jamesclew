' Ollama Auto-Start (Windows Login, Minimized to System Tray)
' "ollama app.exe"는 자체 트레이 아이콘으로 최소화 동작
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run """C:\Users\AIcreator\AppData\Local\Programs\Ollama\ollama app.exe""", 0, False
Set WshShell = Nothing
