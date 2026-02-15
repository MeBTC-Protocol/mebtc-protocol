#!/usr/bin/env bash
set -euo pipefail

for cmd in jq date; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing dependency: $cmd" >&2
    exit 2
  fi
done

require_env() {
  local name="$1"
  if [ -z "${!name:-}" ]; then
    echo "missing env: $name" >&2
    exit 2
  fi
}

require_env TELEMETRY_EVENTS_FILE

if [ ! -f "$TELEMETRY_EVENTS_FILE" ]; then
  echo "telemetry events file not found: $TELEMETRY_EVENTS_FILE" >&2
  exit 2
fi

WINDOW_MINUTES="${WINDOW_MINUTES:-60}"
CLAIM_REVERT_RATE_MAX_BPS="${CLAIM_REVERT_RATE_MAX_BPS:-500}"
CLAIM_RPC_ERROR_RATE_MAX_BPS="${CLAIM_RPC_ERROR_RATE_MAX_BPS:-1000}"
UI_RPC_ERRORS_MAX_PER_HOUR="${UI_RPC_ERRORS_MAX_PER_HOUR:-120}"
MIN_CLAIM_ATTEMPTS_FOR_ALERT="${MIN_CLAIM_ATTEMPTS_FOR_ALERT:-20}"
FAIL_ON_ALERTS="${FAIL_ON_ALERTS:-1}"
NOW_EPOCH="${NOW_EPOCH:-$(date -u +%s)}"

if [ "$WINDOW_MINUTES" -le 0 ]; then
  echo "invalid WINDOW_MINUTES=$WINDOW_MINUTES (must be > 0)" >&2
  exit 2
fi

window_start=$((NOW_EPOCH - WINDOW_MINUTES * 60))

events_json="$(jq -Rcs \
  --argjson start "$window_start" \
  --argjson now "$NOW_EPOCH" '
    split("\n")
    | map(select(length > 0) | fromjson?)
    | map(select(type == "object"))
    | map(. + { __ts: ((.ts | fromdateiso8601?) // 0) })
    | map(select(.__ts >= $start and .__ts <= $now))
  ' "$TELEMETRY_EVENTS_FILE")"

metric_count() {
  local jq_filter="$1"
  jq "$jq_filter" <<<"$events_json"
}

total_events="$(metric_count 'length')"
claim_attempts="$(metric_count '[.[] | select(.event == "claim.attempt")] | length')"
claim_results="$(metric_count '[.[] | select(.event == "claim.result")] | length')"
claim_success_count="$(metric_count '[.[] | select(.event == "claim.result" and .status == "success")] | length')"
claim_revert_count="$(metric_count '[.[] | select(.event == "claim.result" and .status == "revert")] | length')"
claim_rpc_error_count="$(metric_count '[.[] | select(.event == "claim.result" and .status == "rpc_error")] | length')"

claim_revert_slot_count="$(metric_count '[.[] | select(.event == "claim.result" and .status == "revert" and .reason_class == "slot")] | length')"
claim_revert_allowance_count="$(metric_count '[.[] | select(.event == "claim.result" and .status == "revert" and .reason_class == "allowance")] | length')"
claim_revert_balance_count="$(metric_count '[.[] | select(.event == "claim.result" and .status == "revert" and .reason_class == "balance")] | length')"
claim_revert_other_count="$(metric_count '[.[] | select(.event == "claim.result" and .status == "revert" and .reason_class == "other")] | length')"

ui_rpc_error_count="$(metric_count '[.[] | select(.event == "ui.rpc_error")] | length')"

claim_denominator="$claim_attempts"
if [ "$claim_denominator" -eq 0 ] && [ "$claim_results" -gt 0 ]; then
  # Backward compatibility if producer only sends claim.result.
  claim_denominator="$claim_results"
fi

if [ "$claim_denominator" -gt 0 ]; then
  claim_revert_rate_bps=$((claim_revert_count * 10000 / claim_denominator))
  claim_rpc_error_rate_bps=$((claim_rpc_error_count * 10000 / claim_denominator))
else
  claim_revert_rate_bps=0
  claim_rpc_error_rate_bps=0
fi

ui_rpc_errors_per_hour=$((ui_rpc_error_count * 60 / WINDOW_MINUTES))

alerts=0
if [ "$claim_denominator" -ge "$MIN_CLAIM_ATTEMPTS_FOR_ALERT" ] && [ "$claim_revert_rate_bps" -gt "$CLAIM_REVERT_RATE_MAX_BPS" ]; then
  echo "ALERT claim_revert_rate_high bps=$claim_revert_rate_bps threshold=$CLAIM_REVERT_RATE_MAX_BPS denominator=$claim_denominator" >&2
  alerts=$((alerts + 1))
fi

if [ "$claim_denominator" -ge "$MIN_CLAIM_ATTEMPTS_FOR_ALERT" ] && [ "$claim_rpc_error_rate_bps" -gt "$CLAIM_RPC_ERROR_RATE_MAX_BPS" ]; then
  echo "ALERT claim_rpc_error_rate_high bps=$claim_rpc_error_rate_bps threshold=$CLAIM_RPC_ERROR_RATE_MAX_BPS denominator=$claim_denominator" >&2
  alerts=$((alerts + 1))
fi

if [ "$ui_rpc_errors_per_hour" -gt "$UI_RPC_ERRORS_MAX_PER_HOUR" ]; then
  echo "ALERT ui_rpc_error_rate_high per_hour=$ui_rpc_errors_per_hour threshold=$UI_RPC_ERRORS_MAX_PER_HOUR" >&2
  alerts=$((alerts + 1))
fi

cat <<OUT
window.start_epoch=$window_start
window.end_epoch=$NOW_EPOCH
window.minutes=$WINDOW_MINUTES
telemetry.events_total=$total_events
claims.attempt_count=$claim_attempts
claims.result_count=$claim_results
claims.success_count=$claim_success_count
claims.revert_count=$claim_revert_count
claims.revert_rate_bps=$claim_revert_rate_bps
claims.revert_slot_count=$claim_revert_slot_count
claims.revert_allowance_count=$claim_revert_allowance_count
claims.revert_balance_count=$claim_revert_balance_count
claims.revert_other_count=$claim_revert_other_count
claims.rpc_error_count=$claim_rpc_error_count
claims.rpc_error_rate_bps=$claim_rpc_error_rate_bps
ui.rpc_error_count=$ui_rpc_error_count
ui.rpc_error_per_hour=$ui_rpc_errors_per_hour
alerts.count=$alerts
OUT

if [ "$FAIL_ON_ALERTS" = "1" ] && [ "$alerts" -gt 0 ]; then
  exit 1
fi
