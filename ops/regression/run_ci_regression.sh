#!/usr/bin/env bash
set -euo pipefail

GAS_TOLERANCE_PCT="${GAS_TOLERANCE_PCT:-20}"

printf '==> Forge fmt check\n'
forge fmt --check

printf '==> Forge build\n'
forge build --sizes

printf '==> Forge tests (without invariants)\n'
forge test --no-match-contract InvariantMiningManagerTest -vv

printf '==> Forge invariant suite\n'
forge test --match-contract InvariantMiningManagerTest -vv

printf '==> Gas regression check (tolerance: +-%s%%)\n' "$GAS_TOLERANCE_PCT"
forge snapshot --check --tolerance "$GAS_TOLERANCE_PCT" --no-match-contract InvariantMiningManagerTest
