# DECISION.md
# Decision Log

## Why This Approach?
- **Upstream Config**: Single `backend` upstream with primary (`max_fails=1 fail_timeout=5s`) and backup. Simplest way to achieve failover and toggle.
- **Failover**: `proxy_next_upstream` retries same request on error/5xx/timeout, ensuring 0 non-200s. `max_fails=1` marks primary down after one failure; `fail_timeout=5s` balances quick detection vs. flapping.
- **Timeouts**: `1s connect + 2s send/read + 3s retry = ~8s max`, meeting <10s requirement. Ensures ≥95% Green responses post-chaos (likely 100% in 10s window).
- **Templating**: `generate-nginx.sh` uses `sed` over `envsubst` for conditional logic (primary/backup swap). Indentation preserves Nginx syntax.
- **Nginx Reload**: `nginx -s reload` for zero-downtime toggles (no container restart).
- **No Health Checks**: Task implies request-based failover (`healthz` not needed for routing).
- **Alpine Nginx**: Lightweight, fast reloads, minimal footprint.

## Trade-Offs
- **No Sticky Sessions**: Not needed (identical apps, no session state).
- **Simple Script**: Bash+sed over Python for zero deps in CI.
- **Fixed Timeouts**: Tuned for task; adjustable if apps need longer.

## Updates for v2
- Ports: 3000 internal (Node standard) → Maps to 8081/8082 host.
- Health: /healthz checks + depends_on healthy → No timeouts.
- Wait: Init container pings apps → Nginx starts only when ready.