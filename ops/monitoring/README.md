# Monitoring (Regression & Runtime)

This folder covers the `Regression & Monitoring` part from `TEST_PLAN.md`.

## Script

Run:

```bash
set -a; source ops/monitoring/.env.example; set +a
ops/monitoring/check_onchain_metrics.sh
```

Use real deployed addresses and RPC in your own env file.

Additional off-chain telemetry check:

```bash
set -a; source ops/monitoring/.env.example; set +a
ops/monitoring/check_telemetry_metrics.sh
```

## What is checked

- claim success count in a rolling block window (`RewardsClaimed`)
- MeBTC fallback rate (`MebtcFeeFallback` in manager + miner)
- oracle freshness (`getPriceForFees` + `lastGoodTimestamp`)
- emission reward schedule consistency (`currentReward` vs expected halving reward)
- supply cap safety (`totalSupply <= MAX_SUPPLY`)
- vault balances snapshot (`DemandVault` pay token, `FeeVaultMeBTC` mebtc)

## Alerts (non-zero exit)

The script exits `1` when one of these triggers:

- oracle stale (`oracle_fresh != true` or age above threshold)
- fallback rate above threshold (`FALLBACK_RATE_MAX_BPS`)
- reward schedule mismatch (`currentReward != expectedReward`)
- supply cap exceeded (`totalSupply > MAX_SUPPLY`)

Threshold defaults:

- `ORACLE_STALE_MAX_SECONDS=1200`
- `FALLBACK_RATE_MAX_BPS=2000`

## Notes

- `Claim-Revert-Rate (slot/allowance/balance)` cannot be derived purely from on-chain logs because reverted txs are not emitted as events. Use the off-chain telemetry pipeline below.
- `Vault Drift` is exposed here as balance snapshots; full fee-accounting drift needs additional app-level attribution for buy/upgrade/claim flow split.

## Off-chain telemetry format (JSONL)

The script `check_telemetry_metrics.sh` expects newline-delimited JSON objects with ISO timestamp field `ts`.

Supported events:

- `claim.attempt`
  - fields: `ts`, `event`, `mode`, `token_count`, `mebtc_share_bps`
- `claim.result`
  - fields: `ts`, `event`, `status`, `reason_class`, `mode`, `token_count`, `mebtc_share_bps`
  - status values: `success`, `revert`, `rpc_error`, `user_rejected`, `other_error`
  - reason_class values: `slot`, `allowance`, `balance`, `rpc`, `user_rejected`, `other`
- `ui.rpc_error`
  - fields: `ts`, `event`, `context`, `message`

Example line:

```json
{"ts":"2026-02-15T09:25:31.032Z","source":"frontend-vue","env":"production","event":"claim.result","status":"revert","reason_class":"slot","mode":"usdc","token_count":3,"mebtc_share_bps":0}
```

## Off-chain telemetry alerts (non-zero exit)

`check_telemetry_metrics.sh` raises alerts for:

- claim revert rate above `CLAIM_REVERT_RATE_MAX_BPS` (default `500` = 5%)
- claim RPC error rate above `CLAIM_RPC_ERROR_RATE_MAX_BPS` (default `1000` = 10%)
- UI RPC errors per hour above `UI_RPC_ERRORS_MAX_PER_HOUR` (default `120`)

Gate is only active if claim denominator (`claim.attempt` or fallback `claim.result`) is at least `MIN_CLAIM_ATTEMPTS_FOR_ALERT` (default `20`).

## CI wiring

Workflow `.github/workflows/monitoring.yml` runs telemetry checks when
`TELEMETRY_EVENTS_URL` secret is configured.

Optional secret:
- `TELEMETRY_AUTH_BEARER` for protected endpoints.
