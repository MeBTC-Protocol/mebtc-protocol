#!/usr/bin/env bash
set -euo pipefail

for cmd in cast jq bc; do
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

require_env RPC_URL
require_env MANAGER_ADDRESS
require_env MINER_ADDRESS
require_env MEBTC_ADDRESS
require_env TWAP_ORACLE_ADDRESS
require_env DEMAND_VAULT_ADDRESS
require_env FEE_VAULT_MEBTC_ADDRESS

WINDOW_BLOCKS="${WINDOW_BLOCKS:-7200}"
ORACLE_STALE_MAX_SECONDS="${ORACLE_STALE_MAX_SECONDS:-1200}"
FALLBACK_RATE_MAX_BPS="${FALLBACK_RATE_MAX_BPS:-2000}"
FAIL_ON_ALERTS="${FAIL_ON_ALERTS:-1}"

PAY_TOKEN_ADDRESS="${PAY_TOKEN_ADDRESS:-}"

latest_block="$(cast block-number --rpc-url "$RPC_URL")"
if [ "$latest_block" -lt "$WINDOW_BLOCKS" ]; then
  from_block=0
else
  from_block=$((latest_block - WINDOW_BLOCKS))
fi

call_uint() {
  local addr="$1"
  shift
  cast call "$addr" "$@" --rpc-url "$RPC_URL"
}

block_index="$(call_uint "$MANAGER_ADDRESS" "blockIndex()(uint256)")"
halving_blocks="$(call_uint "$MANAGER_ADDRESS" "HALVING_BLOCKS()(uint256)")"
initial_reward="$(call_uint "$MANAGER_ADDRESS" "INITIAL_REWARD()(uint256)")"
current_reward="$(call_uint "$MANAGER_ADDRESS" "currentReward()(uint256)")"

expected_reward="$initial_reward"
halvings_done=$((block_index / halving_blocks))
for ((i = 0; i < halvings_done; i++)); do
  expected_reward=$((expected_reward / 2))
done

mebtc_total_supply="$(call_uint "$MEBTC_ADDRESS" "totalSupply()(uint256)")"
mebtc_max_supply="$(call_uint "$MEBTC_ADDRESS" "MAX_SUPPLY()(uint256)")"

oracle_tuple_raw="$(cast call "$TWAP_ORACLE_ADDRESS" "getPriceForFees()(uint256,bool)" --rpc-url "$RPC_URL")"
oracle_tuple="$(cast abi-decode "(uint256,bool)" "$oracle_tuple_raw" | tr -d '(),')"
read -r oracle_price oracle_fresh <<<"$oracle_tuple"

last_good_timestamp="$(call_uint "$TWAP_ORACLE_ADDRESS" "lastGoodTimestamp()(uint32)")"
latest_timestamp="$(cast block latest -f timestamp --rpc-url "$RPC_URL")"
if [ "$last_good_timestamp" -eq 0 ]; then
  oracle_age_seconds=999999999
else
  oracle_age_seconds=$((latest_timestamp - last_good_timestamp))
fi

claims_json="$(cast logs --json \
  --rpc-url "$RPC_URL" \
  --address "$MANAGER_ADDRESS" \
  --from-block "$from_block" \
  --to-block "$latest_block" \
  "RewardsClaimed(address,uint256,uint256)")"
claim_count="$(jq 'length' <<<"$claims_json")"

claim_reward_sum=0
claim_fee_sum=0
while read -r data; do
  [ -z "$data" ] && continue
  reward_hex="${data:2:64}"
  fee_hex="${data:66:64}"
  reward_dec="$(cast to-dec "0x$reward_hex")"
  fee_dec="$(cast to-dec "0x$fee_hex")"
  claim_reward_sum="$(echo "$claim_reward_sum + $reward_dec" | bc)"
  claim_fee_sum="$(echo "$claim_fee_sum + $fee_dec" | bc)"
done < <(jq -r '.[].data' <<<"$claims_json")

manager_fallback_json="$(cast logs --json \
  --rpc-url "$RPC_URL" \
  --address "$MANAGER_ADDRESS" \
  --from-block "$from_block" \
  --to-block "$latest_block" \
  "MebtcFeeFallback(address,uint256,uint8)")"
miner_fallback_json="$(cast logs --json \
  --rpc-url "$RPC_URL" \
  --address "$MINER_ADDRESS" \
  --from-block "$from_block" \
  --to-block "$latest_block" \
  "MebtcFeeFallback(address,uint256,uint8)")"

manager_fallback_count="$(jq 'length' <<<"$manager_fallback_json")"
miner_fallback_count="$(jq 'length' <<<"$miner_fallback_json")"
fallback_total_count=$((manager_fallback_count + miner_fallback_count))

if [ "$claim_count" -gt 0 ]; then
  fallback_rate_bps=$((fallback_total_count * 10000 / claim_count))
else
  fallback_rate_bps=0
fi

fee_vault_mebtc_balance="$(call_uint "$MEBTC_ADDRESS" "balanceOf(address)(uint256)" "$FEE_VAULT_MEBTC_ADDRESS")"
demand_vault_pay_balance="n/a"
if [ -n "$PAY_TOKEN_ADDRESS" ]; then
  demand_vault_pay_balance="$(cast call "$PAY_TOKEN_ADDRESS" "balanceOf(address)(uint256)" "$DEMAND_VAULT_ADDRESS" --rpc-url "$RPC_URL")"
fi

alerts=0
if [ "$current_reward" -ne "$expected_reward" ]; then
  echo "ALERT emission_reward_mismatch current=$current_reward expected=$expected_reward" >&2
  alerts=$((alerts + 1))
fi
if [ "$mebtc_total_supply" -gt "$mebtc_max_supply" ]; then
  echo "ALERT supply_cap_exceeded total=$mebtc_total_supply max=$mebtc_max_supply" >&2
  alerts=$((alerts + 1))
fi
if [ "$oracle_fresh" != "true" ] || [ "$oracle_age_seconds" -gt "$ORACLE_STALE_MAX_SECONDS" ]; then
  echo "ALERT oracle_stale fresh=$oracle_fresh age_seconds=$oracle_age_seconds threshold=$ORACLE_STALE_MAX_SECONDS" >&2
  alerts=$((alerts + 1))
fi
if [ "$fallback_rate_bps" -gt "$FALLBACK_RATE_MAX_BPS" ]; then
  echo "ALERT mebtc_fallback_rate_high bps=$fallback_rate_bps threshold=$FALLBACK_RATE_MAX_BPS" >&2
  alerts=$((alerts + 1))
fi

cat <<OUT
window.from_block=$from_block
window.to_block=$latest_block
claims.success_count=$claim_count
claims.reward_sum_raw=$claim_reward_sum
claims.fee_sum_usdc_raw=$claim_fee_sum
fallback.manager_count=$manager_fallback_count
fallback.miner_count=$miner_fallback_count
fallback.total_count=$fallback_total_count
fallback.rate_bps=$fallback_rate_bps
oracle.price_raw=$oracle_price
oracle.fresh=$oracle_fresh
oracle.age_seconds=$oracle_age_seconds
emission.block_index=$block_index
emission.current_reward_raw=$current_reward
emission.expected_reward_raw=$expected_reward
emission.total_supply_raw=$mebtc_total_supply
emission.max_supply_raw=$mebtc_max_supply
vault.demand_pay_balance_raw=$demand_vault_pay_balance
vault.fee_mebtc_balance_raw=$fee_vault_mebtc_balance
alerts.count=$alerts
OUT

if [ "$FAIL_ON_ALERTS" = "1" ] && [ "$alerts" -gt 0 ]; then
  exit 1
fi
