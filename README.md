## MeBTC Contracts (Foundry)

Minimal docs for the MeBTC contracts and scripts. Frontend docs live elsewhere.

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

## Scripts

### Deploy (Mainnet)

Env:
```
PRIVATE_KEY
PAY_TOKEN_ADDRESS
POOL_ADDRESS
PROJECT_WALLET
ROYALTY_WALLET
ROYALTY_BPS
```

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
