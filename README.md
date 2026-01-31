## MeBTC Contracts (Foundry)

Minimal docs for the MeBTC contracts and scripts.

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/DeployMainnet.s.sol:DeployMainnet --rpc-url <your_rpc_url> --broadcast
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

## Frontend (local)

The Vue frontend lives in `frontend-vue/`.

### Setup

```shell
$ cd frontend-vue
$ npm install
```

### Run dev server

```shell
$ npm run dev
```

Open `http://localhost:5173` in your browser.

### Environment

The frontend reads env vars from `frontend-vue/.env`:

- `VITE_REOWN_PROJECT_ID` (wallet appkit)
- `VITE_APP_URL` (local app URL)
- `VITE_FUJI_RPC_URL` (defaults to `/fuji` for the Vite proxy)

The dev server proxies `/fuji` to the Fuji RPC. See `frontend-vue/vite.config.ts` if you need to adjust the target or path.

### Build / preview

```shell
$ npm run build
$ npm run preview
```

## Scripts

### Deploy (Mainnet)

Env:
```
PRIVATE_KEY
PAY_TOKEN_ADDRESS
DEMAND_VAULT
FEE_VAULT_MEBTC
TWAP_ORACLE
JOE_FACTORY
MIN_USDC_LP
EPOCH_SECONDS
LP_BURN_BPS
TWAP_WINDOW_SECONDS
PROJECT_WALLET
ROYALTY_WALLET
ROYALTY_BPS
```

See `DEPLOY_FUJI.md` and `DEPLOY_ADDRESSES_FUJI.md` for Fuji steps and address history.

### SetPayToken

Switches the payment token on both contracts (owner only).

Env:
```
PRIVATE_KEY
MANAGER_ADDRESS
MINER_ADDRESS
PAY_TOKEN_ADDRESS
```

Run:
```
forge script script/SetPayToken.s.sol:SetPayToken --rpc-url <rpc> --broadcast
```

### ResyncMiner

Permissionless resync helper for a single miner.

Env:
```
PRIVATE_KEY
MANAGER_ADDRESS
TOKEN_ID
```

Run:
```
forge script script/ResyncMiner.s.sol:ResyncMiner --rpc-url <rpc> --broadcast
```
