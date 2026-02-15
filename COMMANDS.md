## Commands

Build the contracts:
```
forge build
```

Run all tests:
```
forge test
```
If you see a signature cache permission warning, run with a local HOME:
```
mkdir -p cache/home/.foundry/cache
HOME=./cache/home forge test
```

Run tests with more output:
```
forge test -vvv
```

Run a single test by name:
```
forge test --match-test test_ClaimOnlyAfterGlobalSlot
```

Format Solidity files:
```
forge fmt
```

Deploy to a network (Mainnet script):
```
forge script script/DeployMainnet.s.sol:DeployMainnet --rpc-url <rpc> --broadcast
```
Env needed:
```
PRIVATE_KEY
PAY_TOKEN_ADDRESS
POOL_ADDRESS
PROJECT_WALLET
ROYALTY_WALLET
ROYALTY_BPS
```

Switch pay token (owner only):
```
forge script script/SetPayToken.s.sol:SetPayToken --rpc-url <rpc> --broadcast
```
Env needed:
```
PRIVATE_KEY
MANAGER_ADDRESS
MINER_ADDRESS
PAY_TOKEN_ADDRESS
```

Resync a miner (permissionless helper):
```
forge script script/ResyncMiner.s.sol:ResyncMiner --rpc-url <rpc> --broadcast
```
Env needed:
```
PRIVATE_KEY
MANAGER_ADDRESS
TOKEN_ID
```

Run CI regression suite locally (tests + invariants + gas regression check):
```
bash ops/regression/run_ci_regression.sh
```

Run on-chain monitoring checks:
```
set -a; source ops/monitoring/.env.example; set +a
bash ops/monitoring/check_onchain_metrics.sh
```

Run off-chain telemetry monitoring checks (claim revert rate + UI RPC error rate):
```
set -a; source ops/monitoring/.env.example; set +a
bash ops/monitoring/check_telemetry_metrics.sh
```
