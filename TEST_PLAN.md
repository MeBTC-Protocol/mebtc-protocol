# MeBTC Testplan (Foundry-first)

Dieser Plan ist die Basis fuer Security, Tokenomics, Performance und Frontend-Tests.
Foundry ist primaer. Hardhat ist nur optional, wenn ein konkreter Task JS/TS-Tooling braucht.

## Ziele
- Verlust von Funds verhindern (USDC/MeBTC), Nutzer-Balances schuetzen, Vaults konsistent halten.
- Emission, Halving und Claim-Timing unter allen Edge-Cases korrekt.
- Upgrades, Staking, Liquidity und Oracle-Flows unter Last und Stress verifizieren.
- Frontend-Sicherheit, Resilienz und Performance validieren.

## Umgebungen
1) Lokales Anvil (ohne Fork)
   - Schnell, deterministisch, ideal fuer Unit/Integration und Fuzz/Invariants.
2) Mainnet-Fork (Anvil Fork)
   - Hohe Realitaet fuer Liquidity, Oracle-Daten, Gas und MEV-aehnliche Bedingungen.
3) Fuji Testnet
   - End-to-End UI-Flows, Wallet-Handling und Deployment-Validierung.

Primaer: Lokales Anvil + Mainnet-Fork. Sekundaer: Fuji.

## Mainnet-Fork Setup (Anvil)
Ziel: Realistische Tests mit echtem Mainnet-State (Liquidity, Oracles, Fees).

Schritte:
1) RPC-URL fuer Mainnet bereitstellen (z. B. Infura/Alchemy).
2) Anvil Fork starten:
   - anvil --fork-url <RPC_URL> --fork-block-number <BLOCK>
3) In Foundry Tests die Fork nutzen:
   - forge test --fork-url <RPC_URL> --fork-block-number <BLOCK>
4) Konstante Blocknummer nutzen fuer reproduzierbare Tests.
5) Falls benoetigt: Test-Accounts prefunden und Contracts gezielt deployen.

Hinweise:
- Fork-Block fixieren, damit TWAP/Pool-Daten stabil bleiben.
- Keine echten Keys nutzen; nur Test-Schluessel.

## Tooling
- Foundry: forge test, forge snapshot, forge fuzz/invariants
- Optional Static-Analysis: Slither/Mythril (falls noetig)
- Frontend E2E: (bestehenden Stack nutzen) Playwright/Cypress

## Definition of Done
- Alle kritischen Invariants validiert und Regression-Tests gruen.
- Keine Security Findings mit Severity High oder Medium.
- Gas Usage und Throughput innerhalb Blocklimits.
- E2E UI-Flows auf Fuji bestanden.

## Prioritaeten (empfohlene Reihenfolge)
- P0: Core Invariants + Tokenomics/Halving (MiningManager), Claim/Fees/Cap.
- P0: Integration Flows (buy/claim/upgrade/stake, claimWithMebtc).
- P1: Oracle/TWAP + Mainnet-Fork Realismus.
- P1: Security Scenarios (Reentrancy/Approval/MEV/DoS).
- P2: Performance/Load (Gas + Batch-Scaling).
- P2: Frontend Security/UX.
- P3: Monitoring/Metriken (nach Stabilisierung).

## Core Invariants (muessen immer gelten)
- Claim mintet nur volle Intervalle; keine Teil-Emission.
- Gesamt-Emission ueberschreitet nie den Zeitplan (inkl. Halving).
- Fees und Auszahlungen summieren sich korrekt (DemandVault + FeeVaultMeBTC + User).
- Vault-Balances werden nie negativ oder driften vom Accounting weg.
- Nur autorisierte Rollen duerfen kritische Parameter aendern.

### Detaillierte Contract-Invariants (MiningManager)
- blockIndex steigt nur, wenn ein volles CLAIM_INTERVAL vergangen ist.
- currentReward halbiert exakt, wenn blockIndex % HALVING_BLOCKS == 0.
- Keine Emission, solange totalEffectiveHash == 0.
- claim erfordert blockIndex > lastClaimedBlockIndex[id] fuer jede id.
- pendingReward/debtUSDC werden bei claim genullt und lastAccPerHash == accRewardPerEffHash danach.
- Minted Rewards ueberschreiten nie MAX_SUPPLY; claim capped auf remaining supply.
- Fee-Split: outF == usdcPart + mebtcPart; mebtcShareBps <= MAX_MEBTC_SHARE_BPS.
- Bei mebtcShareBps > 0: TWAP muss ready sein und price > 0.

## Testmatrix

### A) Smart Contracts - Unit
Wo: Lokales Anvil + Foundry
Fokus:
- Access Control (Owner/Manager)
- Token-Decimals Enforcement (USDC-like 6 Decimals)
- Reentrancy-Protections bei buy/claim/upgrade/stake
- Parameter-Validation und Event-Emission
Hinweise:
- Unit-Tests pro Contract in `src/core`, `src/nft`, `src/token`.
Testskizzen pro Contract (Foundry):
- MiningManager:
  - test_claim_requires_slot()
  - test_halving_at_boundary()
  - test_no_emission_when_total_hash_zero()
  - test_fee_split_usdc_only()
  - test_fee_split_with_mebtc_price_ready()
- MinerNFT:
  - test_buy_from_model_sets_activation()
  - test_apply_pending_upgrades_after_claim()
  - test_owner_transfer_updates_manager_tokens()
- MeBTC:
  - test_only_manager_can_mint()
  - test_max_supply_cap()
- StakeVault:
  - test_stake_sets_lock_and_bonus()
  - test_unstake_before_unlock_reverts()
  - test_onStakeChange_updates_eff_hash()
- LiquidityEngine / TwapOracleJoeV2:
  - test_execute_epoch_requires_ready_twap()
  - test_twap_update_window()

### B) Smart Contracts - Integration
Wo: Lokales Anvil + Foundry
Flows:
- buy miner -> claim -> upgrade -> claim
- stake -> lock -> unstake (early revert)
- liquidity add -> TWAP update -> execute epoch
- claimWithMebtc Fee-Split
Konkrete Tests (Integration):
- Buy -> Claim: 1 Miner kaufen, 2 Intervalle warten, claim; Reward > 0 und Fee > 0.
- Claim Slot: Direkt nach Kauf claimen -> revert "slot".
- Upgrade Flow: Upgrade anstossen, vor dem Claim bleiben alte Stats aktiv; nach Claim neue Stats aktiv.
- Multiple IDs: 2 Miner, batch claim; beide pendingRewards und debtUSDC werden genullt.
- Stake Impact: Stake setzen, onStakeChange -> effHash/effPower aendern; Reward/Fees folgen.
- ClaimWithMebtc: Fee-Split 30% mit TWAP ready; FeeVaultMeBTC steigt, DemandVault steigt um Rest.
- Edge: mebtcShareBps > MAX_MEBTC_SHARE_BPS -> revert.
- Edge: TWAP not ready oder price=0 -> claimWithMebtc revert.
Hinweise:
- Vault-Balances und Rewards mit preview-Outputs abgleichen.

### C) Tokenomics & Halving
Wo: Lokales Anvil + Mainnet-Fork
Checks:
- Halving-Grenzzeitpunkte (before/after)
- Emissionssumme nach N Intervallen
- Rounding-Verhalten und Dust-Handling
- Long-Run Emission Sanity (Simulation)
Konkrete Tests:
- Halving-Grenze: blockIndex auf HALVING_BLOCKS-1 setzen, 1 Intervall weiter -> Reward halbiert.
- Multi-Halving: nach 2 Halvings entspricht Reward INITIAL_REWARD / 4.
- Long-Run Emission: simulierte Summe der Rewards <= Zeitplan und <= MAX_SUPPLY.
- Keine Emission wenn totalEffectiveHash == 0 ueber mehrere Intervalle.
- preview vs claim: am gleichen Timestamp liefert preview das gleiche Ergebnis wie claim (keine State-Aenderung dazwischen).
Erweiterte Tokenomics-Checks:
- Emissionsformel: Summe der Rewards pro Intervall folgt geometrischer Reihe mit Halving.
- Supply-Cap: ab MAX_SUPPLY keine weitere Minting-Erhoehung (Reward wird gekappt).
- Dust/Rounding: accRewardRemainder und pendingRewardRemainder bleiben konsistent und wachsen nicht unbounded.
- Time-Drift: bei mehrfachen _update() Calls ohne Zeitfortschritt keine zusaetzliche Emission.
- totalEffectiveHash == 0: blockIndex nur bei echte Intervalle; keine Reward-Zuteilung.
- Regression: Preview/Claim identisch bei gleicher Zeit; keine Diffs nach mehrfachen preview Calls.

### D) Oracle & TWAP
Wo: Mainnet-Fork
Checks:
- TWAP-Readiness Window; Stale-Data Handling
- Price-Manipulation Scenarios (low liquidity)
- Update-Timing bei Liquidity-Changes

### E) Security Scenarios
Wo: Lokales Anvil + Mainnet-Fork
Threats:
- Reentrancy-Attempts auf allen externen Calls
- Approval-Abuse / Allowance-Drains
- MEV-like Front-Running um claim/upgrade/liquidity
- DoS via grosse Arrays oder wiederholte Upgrades
Konkrete Tests (Security):
- Reentrancy: fuer claim/claimWithMebtc/upgrade/stake jeweils mit boesartigem Receiver.
- Approval Abuse: allowance kleiner als fee -> revert; allowance gross -> exact transfer.
- Oracle Manipulation: TWAP not ready, stale price, price=0; alle muessen sauber reverts geben.
- MEV/Front-Run: claim vor Slot -> revert; upgrade vor claim -> alte Stats gelten.
- DoS Arrays: sehr viele IDs im claim; Gas-Limit und graceful failure.
- Ownership: Miner transfer -> ownerTokens korrekt; alter Owner kann nicht mehr claimen.
- Role Abuse: nur Owner darf setPayToken; nicht owner -> revert.

### F) Performance & Load
Wo: Lokales Anvil + Mainnet-Fork
Checks:
- Gas pro Operation (claim/upgrade/stake/executeEpoch)
- Batch-Claim Worst-Case mit vielen Minern
- Synthetic Load: viele User und Miner simulieren
Hinweise:
- 1.000.000 User wird skaliert simuliert: Gas pro Claim messen,
  Durchsatz unter Block-Gaslimits abschaetzen.
Konkrete Tests (Performance/Load):
- Gas-Budget: Gas pro claim/upgrade/stake/executeEpoch messen; Zielwerte dokumentieren.
- Batch-Claim Skalierung: 1, 5, 20, 50 IDs in einem claim; Gaswachstum pruefen.
- Worst-Case Miner: Maximale Upgrades + Stake-Boni; Gas und Fees vergleichen.
- Load-Simulation: 10k Miner/1k Nutzer in Tests, Gas pro Claim messen, linear hochskalieren.
- Block-Limit Check: maximal moegliche Claims pro Block aus Gaswerten ableiten.
- Durchsatzgrenze: claims pro Minute basierend auf CLAIM_INTERVAL und Blockgas.

### G) Frontend Security & UX
Wo: Fuji
Checks:
- Wallet connect, Chain-Mismatch Handling
- Approve/buy/claim/upgrade/stake Flows
- RPC Failures, Timeouts, Retries
- XSS/Input-Injection, Unsafe URL Handling
Konkrete Tests (Frontend):
- Chain Mismatch: falsches Netzwerk -> klare UI-Fehler, kein tx senden.
- Allowance Flow: approve nur fuer benoetigten Betrag; UI zeigt allowance korrekt.
- Pending State: claim/upgrade in-flight; UI blockiert Doppelklicks.
- RPC Failover: RPC down -> fallback/fehlermeldung ohne crash.
- Rate Limits: viele Refresh/claims -> UI bleibt stabil.
- Input Hardening: keine XSS in Inputs/URLs/Tx-Notizen.
- Edge Balances: 0 USDC / 0 MeBTC / max approvals.
- Timing: Claim vor Slot -> UI zeigt "noch nicht" statt tx.

### H) Regression & Monitoring
Wo: CI + Fuji
Checks:
- forge test + invariant suite gruen
- gas snapshot diffs reviewen
- basic on-chain metrics tracken (claim failures, vault drift, oracle stale)
Konkrete Metriken/Alerts:
- Claim-Revert-Rate (slot/allowance/balance) mit Schwellenwert.
- Vault Drift: DemandVault/ FeeVaultMeBTC Abweichung gegen erwartete Fees.
- Oracle Stale: TWAP isReady false ueber X Minuten.
- Emission Drift: Summe minted vs. expected schedule (toleranz 0).
- Gas Regression: claim/upgrade > +20% gegen Snapshot.
- UI Errors: RPC Failures/Timeouts pro Stunde.

## Vorschlag Step-by-Step (kurz)
1) Unit-Tests erweitern fuer Core Invariants.
2) Integration-Tests fuer Full User Flows.
3) Tokenomics/Halving-Tests und Long-Run Emission Checks.
4) Mainnet-Fork-Tests fuer Oracle/Liquidity Realitaet.
5) Fuji UI/E2E Test-Checklist ausfuehren.
6) Performance-Profiling und Gas Snapshot Review.

## Optional Hardhat Usage (nur wenn noetig)
- E2E oder Frontend-Contract Integration Tests in JS/TS
- Load-Testing-Skripte, die ein Web3-Stack brauchen

## Task-Liste (Roadmap)
P0:
- MiningManager Invariants: claim-slot, halving boundary, supply-cap, fee-split.
- Integration Tests: buy/claim/upgrade/stake/claimWithMebtc (happy + edge).
- Preview vs Claim Konsistenz.

P1:
- Oracle/TWAP Tests auf Mainnet-Fork (ready/stale/price=0).
- Security Scenarios: Reentrancy/Approval/MEV/DoS.
- Miner transfer/ownership edge cases.

P2:
- Performance/Load: Gas snapshots, batch scaling, throughput estimate.
- Frontend E2E Checklist auf Fuji.

P3:
- Monitoring/Metriken + Alerts definieren und pruefen.
