@echo off
REM Windows Task Scheduler wrapper for codex-keepalive.sh
REM Calls Git Bash to execute the keep-alive script
"C:\Program Files\Git\bin\bash.exe" -lc "bash /d/jamesclew/harness/scripts/codex-keepalive.sh"
exit /b %errorlevel%
