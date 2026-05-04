"""Connect AI Adapter Watchdog — auto-restart on crash
- 어댑터 (connect_ai_adapter_v3.py) 죽으면 즉시 재시작
- 무한 루프, vbs로 백그라운드 spawn
- 로그: C:/temp/bench/adapter_watchdog.log
"""
import subprocess, sys, time, os, datetime, signal

ADAPTER = r"C:\temp\bench\connect_ai_adapter_v3.py"
LOG = r"C:\temp\bench\adapter_watchdog.log"
ADAPTER_LOG = r"C:\temp\bench\adapter_v3.log"
RESTART_DELAY = 3  # 죽음 직후 대기 (포트 release 시간)
MIN_UPTIME = 10    # 이 시간 이내 죽으면 backoff
BACKOFF_MAX = 60

def log(msg):
    line = f"[{datetime.datetime.now().isoformat(timespec='seconds')}] {msg}\n"
    try:
        with open(LOG, "a", encoding="utf-8") as f:
            f.write(line)
    except Exception:
        pass
    print(line, end="", flush=True)

def main():
    log("=== watchdog start ===")
    backoff = RESTART_DELAY
    while True:
        start = time.time()
        log(f"spawning adapter: {ADAPTER}")
        try:
            with open(ADAPTER_LOG, "a", encoding="utf-8") as logf:
                logf.write(f"\n[watchdog] spawn at {datetime.datetime.now().isoformat()}\n")
                proc = subprocess.Popen(
                    [sys.executable, ADAPTER],
                    stdout=subprocess.DEVNULL,
                    stderr=logf,
                    creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
                )
            ret = proc.wait()
            uptime = time.time() - start
            log(f"adapter exited code={ret} uptime={uptime:.1f}s")
            # 짧은 시간 내 종료 → backoff 증가
            if uptime < MIN_UPTIME:
                backoff = min(backoff * 2, BACKOFF_MAX)
                log(f"short uptime — backoff to {backoff}s")
            else:
                backoff = RESTART_DELAY
        except FileNotFoundError as e:
            log(f"FATAL: {e}")
            time.sleep(BACKOFF_MAX)
        except Exception as e:
            log(f"ERR: {e}")
        time.sleep(backoff)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        log("=== watchdog stopped (KeyboardInterrupt) ===")
