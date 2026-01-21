# MeBTC Test Plan (Foundry-first)

This plan is the baseline for security, tokenomics, performance, and frontend testing.
Foundry is primary. Hardhat is optional only if a specific task requires JS/TS tooling.

## Goals
- Prevent loss of funds (USDC/MeBTC), protect user balances, and keep vaults consistent.
- Ensure emission, halving, and claim timing are correct under all edge cases.
- Verify upgrades, staking, liquidity, and oracle flows work under load and stress.
- Validate frontend safety, resilience, and performance.

## Environments
1) Local Anvil (no fork)
   - Fast, deterministic, ideal for unit/integration and fuzz/invariants.
2) Mainnet-fork (Anvil fork)
   - Highest realism for liquidity, oracle data, gas, and MEV-like conditions.
3) Fuji testnet
   - End-to-end UI flows, wallet behavior, and deployment verification.

Primary: Local Anvil + Mainnet-fork. Secondary: Fuji.

## Tooling
- Foundry: forge test, forge snapshot, forge fuzz/invariants
- Optional static analysis: Slither/Mythril (if needed)
- Frontend E2E: (choose existing stack) Playwright/Cypress

## Definition of Done
- All critical invariants validated and regression tests green.
- No high or medium severity security findings.
- Gas usage and throughput acceptable within block limits.
- E2E UI flows pass on Fuji.

## Core Invariants (must always hold)
- Claim can only mint for full intervals; no partial interval emission.
- Total minted emission never exceeds schedule (including halving).
- Fees and payouts always sum correctly (DemandVault + FeeVaultMeBTC + user).
- Vault balances never go negative or drift from accounting.
- Only authorized roles can update critical parameters.

## Test Matrix

### A) Smart Contracts - Unit
Where: Local Anvil + Foundry
Focus:
- Access control (owner/manager)
- Token decimals enforcement (USDC-like 6 decimals)
- Reentrancy protections on buy/claim/upgrade/stake
- Parameter validation and event emission
Notes:
- Add unit tests per contract in `src/core`, `src/nft`, `src/token`.

### B) Smart Contracts - Integration
Where: Local Anvil + Foundry
Flows:
- buy miner -> claim -> upgrade -> claim
- stake -> lock -> unstake (early revert)
- liquidity add -> TWAP update -> execute epoch
- claimWithMebtc fee split
Notes:
- Ensure vault balances and rewards match preview outputs.

### C) Tokenomics & Halving
Where: Local Anvil + Mainnet-fork
Checks:
- Halving boundary timestamps (before/after)
- Emission totals after N intervals
- Rounding behavior and dust handling
- Long-run emission sanity (simulation)

### D) Oracle & TWAP
Where: Mainnet-fork
Checks:
- TWAP readiness window; stale data handling
- Price manipulation scenarios (low liquidity)
- Update timing with liquidity changes

### E) Security Scenarios
Where: Local Anvil + Mainnet-fork
Threats:
- Reentrancy attempts on all external calls
- Approval abuse / allowance drains
- MEV-like front-running around claim/upgrade/liquidity
- DoS via large arrays or repeated upgrades

### F) Performance & Load
Where: Local Anvil + Mainnet-fork
Checks:
- Gas per operation (claim/upgrade/stake/executeEpoch)
- Batch claim worst-case with many miners
- Synthetic load: simulate many users and miners
Notes:
- 1,000,000 users is simulated by scaling: measure gas per claim, estimate
  throughput under block gas limits.

### G) Frontend Security & UX
Where: Fuji
Checks:
- Wallet connect, chain mismatch handling
- Approve/buy/claim/upgrade/stake flows
- RPC failures, timeouts, retries
- XSS/input injection, unsafe URL handling

### H) Regression & Monitoring
Where: CI + Fuji
Checks:
- forge test + invariant suite green
- gas snapshot diffs reviewed
- basic on-chain metrics tracked (claim failures, vault drift, oracle stale)

## Proposed Step-by-Step Execution (short)
1) Expand unit tests to cover core invariants.
2) Add integration tests for full user flows.
3) Add tokenomics/halving tests and long-run emission checks.
4) Run mainnet-fork tests for oracle/liquidity realism.
5) Perform Fuji UI/E2E test checklist.
6) Run performance profiling and gas snapshot review.

## Optional Hardhat Usage (only if needed)
- E2E or frontend-contract integration tests in JS/TS
- Load testing scripts requiring web3 stack

