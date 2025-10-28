# README.md
# Blue/Green Deployment with Nginx Auto-Failover

## Setup
1. Copy `.env.example` to `.env` ...
2. Run `./generate-nginx.sh`
3. Start: `docker compose up -d` # Health checks ensure apps ready before Nginx

## Endpoints
- **Nginx**: `http://localhost:${PORT:-8080}` (main entrypoint).
- **Blue (direct)**: `http://localhost:8081` (for chaos).
- **Green (direct)**: `http://localhost:8082`.

## Testing
1. **Baseline** (Blue active):
   - `curl -v http://localhost:8080/version`
   - Expect: 200 OK, `X-App-Pool: blue`, `X-Release-Id: $RELEASE_ID_BLUE`.
   - Repeat 10x: All responses from Blue.

2. **Induce Failure**:
   - `curl -X POST "http://localhost:8081/chaos/start?mode=error"` (or `?mode=timeout`).
   - `curl -v http://localhost:8080/version`
   - Expect: 200 OK, `X-App-Pool: green`, `X-Release-Id: $RELEASE_ID_GREEN`.

3. **Stability**:
   - Run: `for i in {1..20}; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/version; done`
   - Expect: 0 non-200s, ≥95% responses from Green (likely 100%).

4. **Stop Chaos**:
   - `curl -X POST http://localhost:8081/chaos/stop`
   - After 5s, traffic may return to Blue (auto-recovery).

## Toggle Primary (Blue ↔ Green)
1. Edit `.env`: Set `ACTIVE_POOL=green` (or `blue`).
2. Run `./generate-nginx.sh`.
3. Reload: `docker compose exec nginx nginx -s reload`.
4. Verify: `curl -v http://localhost:8080/version` shows new primary.

## Notes
- **Failover**: Auto-retries to backup on 5xx/timeout; 0 client failures.
- **Timeouts**: <10s per request (1s connect + 2s send/read + 3s retry).
- **Headers**: `X-App-Pool`, `X-Release-Id` forwarded unchanged.
- **CI**: Expects `.env` vars; no image builds.