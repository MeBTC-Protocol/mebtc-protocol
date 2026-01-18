## Fuji Deploy Guide (MeBTC)

### 1) Prerequisites
- Foundry installed
- Fuji RPC URL
- Deployer wallet funded with AVAX
- USDC token address on Fuji (set as `PAY_TOKEN_ADDRESS`)
- Trader Joe V2 Factory address on Fuji (set as `JOE_FACTORY`)

### 2) Wallets / Addresses Required
- `PRIVATE_KEY` (deployer, pays gas)
- `PROJECT_WALLET` (receives 10% of primary sales)
- `ROYALTY_WALLET` (receives ERC2981 royalties)
- Optional:
  - `DEMAND_VAULT` (USDC vault). If not set, deploy script creates one.
  - `FEE_VAULT_MEBTC` (MeBTC vault). If not set, deploy script creates one.
  - `TWAP_ORACLE` (if you already have an oracle). If not set, deploy script creates one.

### 3) Params to Decide
- `MIN_USDC_LP` = `10000000` (10,000 USDC with 6 decimals)
- `EPOCH_SECONDS` = `3600` (1 hour)
- `LP_BURN_BPS` = `200` (2%)
- `TWAP_WINDOW_SECONDS` = `3600` (1 hour)
- `ROYALTY_BPS` (e.g. `250` = 2.5%)

### 4) Deploy (single script)
Run:
```bash
forge script script/DeployMainnet.s.sol:DeployMainnet \
  --rpc-url <FUJI_RPC_URL> \
  --broadcast
```

Required env vars:
```
PRIVATE_KEY
PAY_TOKEN_ADDRESS
PROJECT_WALLET
ROYALTY_WALLET
ROYALTY_BPS
JOE_FACTORY
MIN_USDC_LP
EPOCH_SECONDS
LP_BURN_BPS
TWAP_WINDOW_SECONDS
```

Optional env vars:
```
DEMAND_VAULT
FEE_VAULT_MEBTC
TWAP_ORACLE
```

### 5) After Deploy
1) **Setup miner models**
```bash
forge script script/SetupModels.s.sol:SetupModels \
  --rpc-url <FUJI_RPC_URL> \
  --broadcast
```
Env:
```
PRIVATE_KEY
MINER_ADDRESS
```

2) **Mint a miner (test user)**
```bash
forge script script/MintMinerFuji.s.sol:MintMinerFuji \
  --rpc-url <FUJI_RPC_URL> \
  --broadcast
```
Env:
```
PRIVATE_KEY
MINER_ADDRESS
USDC_ADDRESS
MODEL_ID
QTY
```

3) **Add initial liquidity (to create pool & TWAP)**
- Use Trader Joe UI on Fuji and add liquidity to the MeBTC/USDC pair.
- This creates the pair if it does not exist.
- After liquidity is live, wait `TWAP_WINDOW_SECONDS` and optionally call `TwapOracleJoeV2.update()`.

4) **Run epoch (Liquidity Engine)**
- Anyone can call `executeEpoch()` once per hour.
- This moves assets from Vaults into the pool and auto-compounds (2% LP burn).

### 6) Testing the Pool on Fuji
Yes, you can create a **test pool** on Trader Joe Fuji:
- Add liquidity via UI or router using MeBTC + USDC.
- The pool address will match the canonical pair.
- TWAP becomes valid after the window passes.

### Notes
- MeBTC fee payments stay disabled until TWAP is ready.
- Vaults are engine-controlled and cannot be drained by an owner.
