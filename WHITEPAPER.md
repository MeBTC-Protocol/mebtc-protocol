# MeBTC Whitepaper

Version: 1.0  
Date: February 15, 2026  
Language: English

## 1. Abstract
MeBTC is a proof-of-mining game and tokenized infrastructure protocol built on EVM chains. Users acquire Miner NFTs, earn MeBTC emissions based on effective hashrate, pay energy-like operating fees, and can optimize performance through upgrades and staking. The system combines:

- A capped reward token (`MeBTC`, max supply 21,000,000 with 8 decimals)
- Miner NFTs with configurable models and upgrade paths
- A slot-based emission engine with Bitcoin-like halving logic
- A TWAP-gated fee split that allows partial fee payment in MeBTC
- A vault and liquidity engine that routes protocol flows into pool liquidity

The design goal is to create a transparent, on-chain economy with deterministic reward rules and explicit risk controls.

## 2. Problem Statement
Many token mining games fail because they rely on opaque emissions, discretionary reward changes, or weak liquidity mechanics. MeBTC addresses this by enforcing:

- Fixed, code-defined emission intervals
- Deterministic halving schedule
- Hard token supply cap
- Explicit fee accounting tied to miner power usage
- Oracle freshness checks for non-USDC fee paths

## 3. System Architecture
Core contracts:

- `MeBTC`: ERC-20 token (8 decimals), mint restricted to `MiningManager`, 21M cap.
- `MiningManager`: Settlement engine for rewards/fees, slot updates, halving, claims.
- `MinerNFT`: ERC-721 miner models, purchasing, pending upgrades, royalty support (ERC2981).
- `StakeVault`: Optional MeBTC staking for hashrate/power bonuses with lock periods.
- `TokenVault` (Demand/Fee): Engine-controlled vault wrappers.
- `LiquidityEngine`: Epoch execution for adding liquidity and LP auto-compounding.
- `TwapOracleJoeV2`: Trader Joe V2 TWAP adapter with cached price freshness controls.

## 4. Token Design
Token parameters:

- Name: `MeBTC`
- Symbol: `MBTC`
- Decimals: `8`
- Max supply: `21,000,000 * 10^8`
- Mint authority: `MiningManager` only

Minting occurs on successful claims and is always capped to remaining supply.

## 5. Emission and Halving
### 5.1 Slot Model

- Claim interval (slot): `600s` (10 minutes)
- Network reward at launch: `50 MBTC` per slot
- Emission accrues only on full slots
- No retroactive emission when total effective hashrate is zero

### 5.2 Halving

- Halving every `210,000` slots
- At 10 minutes/slot, one halving period is about 3.995 years
- Current slot reward is halved automatically at each boundary

### 5.3 Reward Allocation
For each slot:

`Miner reward share = (miner effective hashrate / total effective hashrate) * slot reward`

The contract uses accumulator math with remainder carry to reduce long-run rounding drift.

## 6. Miner NFTs
### 6.1 Purchase Flow

- Users buy finalized miner models with USDC-like payment tokens (6 decimals required)
- Primary sale split: `90%` -> Demand Vault, `10%` -> Project Wallet
- Miner becomes active immediately after mint (no delayed activation state)

### 6.2 Upgrade Model

- Upgrades are requested first and stored as pending
- Activation happens only after the next claim
- Hash upgrade step: `+2.5%` (`250 bps`) per step, max 4 steps
- Power upgrade step: `-5%` (`500 bps`) per step, max 4 steps

### 6.3 Current Model Set (configured by script)
| Model | Base Hashrate | Base Power | Max Supply | Price |
|---|---:|---:|---:|---:|
| RigMiner | 500 GH/s | 200 W | 50,000 | 24 USDC |
| BasicMiner | 13,500 GH/s | 1,350 W | 20,000 | 49 USDC |
| MeMiner | 50,000 GH/s | 2,250 W | 10,000 | 124 USDC |
| ProMiner | 104,000 GH/s | 3,068 W | 3,000 | 349 USDC |
| PrimeMiner | 200,000 GH/s | 3,500 W | 800 | 749 USDC |
| ApexMiner | 270,000 GH/s | 3,645 W | 200 | 1,499 USDC |

Model parameters are on-chain configuration and can differ by deployment.

## 7. Fee Mechanics
Operational fees model energy cost per interval.

- `FEE_PER_KWH = 0.15 USDC` (6-decimal token units)
- Fee is derived from miner effective power and settled per full slot

Per-slot fee formula:

`feeUSDC = (powerWatt * 600 * 150000) / 3600000`

Claims settle reward and fee for all selected token IDs in one transaction.

## 8. Optional MeBTC Fee Share (TWAP-Gated)
Users can choose to pay up to 30% of claim/upgrade fees in MeBTC.

- Max MeBTC fee share: `3000 bps` (30%)
- Oracle updates via `updateIfDue()`
- If TWAP is stale/unavailable or wallet MeBTC is insufficient, the system falls back to `USDC-only` fee collection
- Claim/upgrade does not revert due to price freshness issues

This keeps UX predictable while preventing stale-price dependency.

## 9. Staking Layer
Users can stake MeBTC for miner performance bonuses.

| Tier | Stake Threshold | Hash Bonus | Power Reduction Bonus | Lock |
|---|---:|---:|---:|---:|
| Tier 1 | 10,000 MBTC | +5% | -5% | 30 days |
| Tier 2 | 50,000 MBTC | +10% | -12% | 90 days |
| Tier 3 | 250,000 MBTC | +15% | -20% | 180 days |

Stake changes trigger recalculation of miner effective stats in the manager.

## 10. Liquidity Engine
`LiquidityEngine.executeEpoch()` is callable once per epoch and performs:

1. Optional LP auto-compound (burn a configured share of LP held by engine and re-mint).
2. Add liquidity from protocol vaults if thresholds are met.

Execution guards:

- Epoch time elapsed
- Demand Vault balance >= `minUsdc`
- Fee Vault MeBTC balance > 0

Inputs are capped by the smaller normalized side to preserve pair ratio.

## 11. Oracle Design
`TwapOracleJoeV2` uses cumulative price observations from a Trader Joe V2 pair.

- Minimum reserve gate (`minUsdcLiquidity`)
- TWAP window (`window`)
- Cached good price with freshness limit (`maxPriceAge = 2 * window`)

The system uses cached price for fee conversions to avoid immediate spot-price dependence.

## 12. Security and Risk Notes
Implemented protections:

- Reentrancy guards on user-critical state-changing functions
- Strict token decimal checks for payment token
- Explicit authorization boundaries (`onlyOwner`, manager hooks, vault engine-only transfer)
- Supply cap enforcement at mint time

Known engineering follow-ups documented in repo:

- Hardening token transfer assumptions in parts of liquidity execution
- Additional reentrancy hardening/documentation for engine boundaries
- Continued invariant and adversarial test expansion

Users should treat MeBTC as experimental software and assess smart contract risk accordingly.

## 13. Testing and Validation
The project follows a Foundry-first testing strategy with:

- Unit tests
- Integration tests
- Invariant/property tests
- Security scenario tests
- Fuji testnet E2E flows
- Optional mainnet-fork regression checks

Test plans and security notes are maintained in repository documentation.

## 14. Governance and Operations
Current control model is owner-administered for selected configuration tasks (e.g., payment token updates, model setup/finalization, manager binding during deployment). Vault transfers are constrained to the liquidity engine once initialized.

Future governance can evolve toward timelocks and multisig operational standards.

## 15. Disclaimer
This document is technical documentation, not financial advice, investment advice, or a promise of future performance. Smart contract systems involve security, market, and operational risk.
