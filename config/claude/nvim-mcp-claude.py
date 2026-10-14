"""Stdio shim between Claude Code and nvim-mcp.

Claude Code negotiates MCP protocol 2026-07-28 with nvim-mcp (rmcp 3.5.0)
and then rejects every */list result for lacking the 2026-07-28 cache hints
`ttlMs` and `cacheScope`, which nvim-mcp 0.7.2 does not send. This proxies
newline-delimited JSON-RPC both ways and fills those two fields into the
results of */list requests only. ttlMs is 0 because nvim-mcp's tool set
changes as Neovim instances connect, so nothing should be cached.

Remove once either side is fixed upstream (see config/claude/mcp-servers.json).
"""

import json
import signal
import subprocess
import sys
import threading

pending = set()
lock = threading.Lock()


def pump_requests(child):
    for line in sys.stdin.buffer:
        try:
            msg = json.loads(line)
        except ValueError:
            msg = None
        if isinstance(msg, dict) and "id" in msg:
            method = msg.get("method", "")
            if method.endswith("/list"):
                with lock:
                    pending.add(json.dumps(msg["id"]))
        try:
            child.stdin.write(line)
            child.stdin.flush()
        except BrokenPipeError:
            return
    child.stdin.close()


def patch(line):
    try:
        msg = json.loads(line)
    except ValueError:
        return line
    if not isinstance(msg, dict) or "id" not in msg:
        return line
    key = json.dumps(msg["id"])
    with lock:
        if key not in pending:
            return line
        pending.discard(key)
    result = msg.get("result")
    if not isinstance(result, dict):
        return line
    result.setdefault("ttlMs", 0)
    result.setdefault("cacheScope", "private")
    return (json.dumps(msg, separators=(",", ":")) + "\n").encode()


def main():
    child = subprocess.Popen(
        ["nvim-mcp", *sys.argv[1:]],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
    )
    for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, lambda s, _f: child.send_signal(s))
    threading.Thread(target=pump_requests, args=(child,), daemon=True).start()
    out = sys.stdout.buffer
    for line in child.stdout:
        out.write(patch(line))
        out.flush()
    sys.exit(child.wait())


main()
