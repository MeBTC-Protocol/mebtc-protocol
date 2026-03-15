# MeBTC Protocol

> **⚠ Public Testnet Beta** — Unaudited. Use Testnet USDC only. Mainnet launches after a successful beta phase.

Fair, deterministic on-chain mining on Avalanche. Buy Miner NFTs with USDC, earn MeBTC proportional to your hashrate. No premine. No admin mint. Not even the developer can print MeBTC.

→ **[mebtc.network](https://mebtc.network)** · [Testnet](https://mebtc.network/testnet) · [Litepaper](./LITEPAPER.md) · [Discord](https://discord.gg/HEVka5EH) · [contact@mebtc.network](mailto:contact@mebtc.network)

---

## What is MeBTC?

MeBTC is a mining-economy protocol on Avalanche (EVM). Users purchase Miner NFTs and receive MeBTC tokens as block rewards — proportional to their effective hashrate.

MeBTC is an ERC20 token with a **hard cap of 21,000,000** (8 decimals, Bitcoin-style) and an automatic **halving every 210,000 slots** (~4 years at 1 slot = 10 minutes).

```
MinerNFT ──────────────────────────────────────┐
    │ buyFromModel()                            │
    │ requestUpgradeHash/Power()                │
    └─────────────► MiningManager ─────────────► MeBTC (Mint)
                         │                          (ERC20, 21M cap)
                         │ onStakeChange()
                         ▼
                    StakeVault
                         │
                    DemandVault (USDC) ──► LiquidityEngine ──► Trader Joe V2 LP
                    FeeVault (MeBTC)   ──►        │
                                                  ▼
                                          TwapOracleJoeV2
```

---

## Why no one can print MeBTC

`MeBTC.sol` enforces a single minter: the `MiningManager` contract address, set immutably in the constructor. The `MiningManager` itself only mints inside `claim()` — proportional to elapsed slots and effective hashrate — and is bounded by the 21M cap. There is no `owner` function, no backdoor, no emergency mint. The deployer wallet has zero special minting privileges after deployment.

---

## Tokenomics

| Parameter | Value |
|-----------|-------|
| Max supply | 21,000,000 MBTC (8 decimals) |
| Initial emission | 50 MBTC per 10-minute slot |
| Halving interval | Every 210,000 slots (~4 years) |
| Mining fee | 0.15 USDC/kWh |
| Fee split | 90% DemandVault / 10% Project |
| MeBTC fee share | Up to 30% (TWAP-gated) |

---

## Miner Models

| Model | Hashrate | Power | Price | Max Supply | Min. Liquidity |
|-------|----------|-------|-------|-----------|----------------|
| RigMiner | 500 GH/s | 200 W | 24 USDC | 50,000 | — |
| BasicMiner | 13.5 TH/s | 1,350 W | 49 USDC | 20,000 | 10,000 USDC |
| MeMiner | 50 TH/s | 2,250 W | 124 USDC | 10,000 | 50,000 USDC |
| ProMiner | 104 TH/s | 3,068 W | 349 USDC | 3,000 | 200,000 USDC |
| PrimeMiner | 200 TH/s | 3,500 W | 749 USDC | 800 | 750,000 USDC |
| ApexMiner | 270 TH/s | 3,645 W | 1,499 USDC | 200 | 2,000,000 USDC |

**Min. Liquidity** is the minimum USDC reserve required in the MeBTC/USDC trading pair before that model can be purchased. This prevents mass-minting before real market liquidity exists. If the on-chain liquidity oracle reports below the threshold, `buyFromModel()` reverts for all buyers equally.

Each miner supports up to 4 hashrate upgrades (+2.5% each, max +10%) and 4 power upgrades (−5% each, max −20%). Upgrades are paid immediately but only become active after the next `claim()` — preventing retroactive advantage over other miners.

---

## Staking Tiers

| Tier | Min MeBTC | Lock | Hash Bonus | Power Reduction |
|------|-----------|------|-----------|-----------------|
| 0 | — | — | 0% | 0% |
| 1 | 10,000 | 30 days | +5% | −5% |
| 2 | 50,000 | 90 days | +10% | −12% |
| 3 | 250,000 | 180 days | +15% | −20% |

Lock time only extends on tier upgrade, not on every additional deposit.

---

## Repository Structure

```
mebtc-protocol/
├── src/
│   ├── core/
│   │   ├── MiningManager.sol       # Emissions, claim, halving
│   │   ├── StakeVault.sol          # Tier-based staking bonuses
│   │   ├── LiquidityEngine.sol     # Epoch-based LP management
│   │   ├── TwapOracleJoeV2.sol     # TWAP price feed
│   │   ├── TokenVault.sol          # USDC / MeBTC escrow
│   │   └── ITwapOracle.sol
│   ├── nft/
│   │   └── MinerNFT.sol            # NFTs, models, upgrades, liquidity gate
│   ├── token/
│   │   └── MeBTC.sol               # ERC20, 21M cap
│   └── mocks/
│       └── MockUSDC.sol            # Testnet only
├── test/                           # 17 Foundry test suites
├── script/                         # Deploy & setup scripts
├── frontend-vue/                   # Vue 3 + TypeScript + TailwindCSS
├── metadata/miners/                # NFT metadata (6 models)
├── audits/                         # Slither, Aderyn & Mythril reports
├── ops/                            # Monitoring & regression scripts
├── .github/workflows/              # CI: build + test
├── LITEPAPER.md
├── SECURITY.md
└── TESTNET.md
```

---

## Getting Started (Development)

**Requirements:** [Foundry](https://getfoundry.sh), Node.js ≥ 18

```bash
# Clone
git clone https://github.com/mebtc-protocol/mebtc-protocol.git
cd mebtc-protocol

# Install dependencies
forge install

# Build
forge build

# Run tests
forge test -vvv
```

**Frontend:**
```bash
cd frontend-vue
npm install
npm run dev
```

---

## Testnet (Avalanche Fuji)

Current deployment — Redeploy #11:

| Contract | Address |
|----------|---------|
| MiningManager | `0xCb4bc402784CF93dbe9E3504C7AD37eC7Cfa738F` |
| MinerNFT | `0xcd0604989548a6947D600D3Bb0A0808f7Ac5aFE1` |
| MeBTC | `0xfFfb0217713597608d88DcB7B8401a5B5893Ce84` |
| StakeVault | `0x82D7E18655e1A4e58fb68A7e4Ec6b3f806d54417` |
| LiquidityEngine | `0x873659698195103536bBC3F7b6d0304822cAD562` |
| TWAP Oracle | `0x046c3b8e32f3802A8d5A62b2096e2d8754De8EB6` |
| MockUSDC (Testnet) | `0x01900649664B7f221D11b6194A49597CBdF8C72e` |
| DemandVault | `0x80E8E3912FACC03245ad551c09681Be1Dd555009` |
| FeeVault (MeBTC) | `0xacad4b6525d85C6b0834e18aFcd9De695993F721` |
| LP Pair | `0xDfba4ed71aC02Bcba9F9B1a79Fbfa081A143914C` |

Testnet USDC faucet and full testing guide: [mebtc.network/testnet](https://mebtc.network/testnet)

> Testnet contracts may be redeployed without notice. Testnet assets have no real value.

---

## Security & Audits

Three automated analysis tools were run against the full `src/` directory (1,295 nSLOC). Reports are in [`audits/`](./audits/).

| Tool | High | Medium | Low | Report |
|------|------|--------|-----|--------|
| Mythril (symbolic execution) | 0 | 0 | 4 | [`audits/mythril_report.md`](./audits/mythril_report.md) |
| Slither (static analysis) | 0 | 0 | ~20 | [`audits/slither_report.txt`](./audits/slither_report.txt) |
| Aderyn (static analysis) | 1* | 0 | 14 | [`audits/aderyn_report.md`](./audits/aderyn_report.md) |

*The Aderyn H-1 flags 11 instances of "state change after external call". All are either protected by `ReentrancyGuard` or occur in constructors/initializers calling `IERC20Metadata.decimals()` — not exploitable paths. See [SECURITY.md](./SECURITY.md) for full evaluation.

This protocol has **not been formally audited** by a third-party security firm. A professional audit is planned before mainnet launch.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Smart Contracts | Solidity 0.8.26, Foundry |
| DEX | Trader Joe V2 (Liquidity Bin Protocol) |
| Frontend | Vue 3, TypeScript, Vite, TailwindCSS, ethers.js v6 |
| Wallet | ReOwn AppKit |
| Network | Avalanche C-Chain (Fuji Testnet → Mainnet) |
| Build | via_ir: true, optimizer runs: 20,000 |

---

## Protocol Invariants

These hold at all times and are enforced by invariant fuzz tests (`InvariantMiningManager.t.sol`, 32 runs, depth 25):

1. `MeBTC.totalSupply() ≤ 21,000,000 × 10^8` — never exceeded
2. `Σ(effectiveHashrate of all miners) == totalEffectiveHashrate` in MiningManager
3. `lastClaimSlot` of any miner only ever increases
4. Upgrades activate exclusively inside `claim()`, never retroactively
5. Each slot is settled exactly once — no double-accounting

---

## License

MIT — see [LICENSE](./LICENSE)

---

> MeBTC is an experimental protocol. Only use what you can afford to lose. This is not financial advice.
