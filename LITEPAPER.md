# MeBTC Litepaper

Version: 1.0  
Date: February 15, 2026  
Language: English

## Overview
MeBTC is an on-chain mining economy where users buy Miner NFTs, earn MeBTC rewards, and optimize output through upgrades and staking.

The protocol combines:

- A capped token (`MeBTC`, 21M max supply, 8 decimals)
- Slot-based mining rewards (10-minute intervals)
- Bitcoin-style halving cadence
- Energy-style operating fees in USDC, with optional partial MeBTC fee share
- Vault-driven liquidity support via epoch execution

## Core Components
- `MiningManager`: calculates rewards/fees and processes claims.
- `MinerNFT`: miner ownership, model supply, upgrades, and royalties.
- `MeBTC`: reward token minted only by manager and capped at 21M.
- `StakeVault`: optional staking bonuses with lock periods.
- `TwapOracleJoeV2`: cached TWAP pricing for fee conversion safety.
- `LiquidityEngine`: moves vault assets into liquidity on timed epochs.

## How Rewards Work
- Time is segmented into 10-minute slots.
- Each full slot emits a network reward (starts at 50 MBTC per slot).
- Reward share is proportional to a miner's effective hashrate.
- Emission halving occurs every 210,000 slots (about 4 years).
- No emission is backfilled while total effective hashrate is zero.

## Miner Economy
- Users buy finalized miner models in a 6-decimal payment token (USDC-style).
- Primary sale flow: 90% to Demand Vault, 10% to Project Wallet.
- Upgrades are queued as pending and become active after a claim.

Current scripted models range from entry-level (RigMiner) to high-performance (ApexMiner), each with fixed supply, price, power, and hashrate profiles.

## Fee System
Mining fees are tied to effective power usage and settled per claim interval.

Users can optionally pay up to 30% of fees in MeBTC:

- If TWAP price is fresh and wallet has sufficient MeBTC, split payment is used.
- If TWAP is stale/missing or MeBTC is insufficient, flow falls back to USDC-only.
- Fallback avoids unnecessary claim failures.

## Staking Boosts
Staking MeBTC provides bonus hashrate and reduced effective power draw:

- Tier 1: 10,000 MBTC, 30-day lock
- Tier 2: 50,000 MBTC, 90-day lock
- Tier 3: 250,000 MBTC, 180-day lock

Higher tiers increase reward potential and reduce fee burden through better efficiency.

## Liquidity and Sustainability
Protocol fees are split across vaults and later used by the liquidity engine.

Each epoch, the engine can:

- Add balanced liquidity from USDC and MeBTC vaults
- Auto-compound LP exposure by burning a configured LP share and re-minting

This creates a direct path from user activity to protocol-side liquidity support.

## Security Posture
The contracts include reentrancy guards, role-based authorization, strict decimal checks, and hard cap enforcement. Ongoing hardening and regression work is tracked in repository security/test documentation.

## Why MeBTC
MeBTC focuses on deterministic on-chain economics:

- Transparent emission logic
- Hard supply constraints
- Explicit fee accounting
- Oracle freshness protections
- Modular architecture for iterative upgrades

## Disclaimer
This litepaper is for technical information only and is not financial advice. Smart contract use involves technical and market risk.
