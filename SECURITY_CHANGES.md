# Security Change Log (MeBTC)

## Planned Contract Changes
- [x] MiningManager: `SafeERC20` eingeführt für `transferFrom` (USDC + MeBTC-Gebühren). Umgesetzt in Redeploy #11 (2026-03-15).
- [ ] LiquidityEngine: `SafeERC20`/Return-Checks in `_mintLiquidity` (src/core/LiquidityEngine.sol:145-148). Grund: unchecked transfer; Risiko bei non-standard ERC20. (noch offen)
- [ ] LiquidityEngine: optional `nonReentrant` auf `executeEpoch` oder Trust-Boundary dokumentieren (src/core/LiquidityEngine.sol:70-79). Grund: Slither Reentrancy-Hinweis. (noch offen)
- [x] TokenVault: `transferTo` externe Call (SWC-107) als bewusstes Pattern akzeptiert – kein Guard geplant.

## Test Findings / Fehlerlog
- 2026-02-08: Datei angelegt. Findings werden hier fortlaufend ergaenzt.
- 2026-02-08: Test-Idee `claimWithMebtc` mit Share > MAX hat nicht wie erwartet revertiert (mehrfacher Lauf). Ursache unklar, weiter untersuchen.
- 2026-02-08: Neuer Test `test_AutoCompoundIgnoresFailedTokenTransfer` zeigt Risiko bei Tokens die `transfer` false returnen (LP mint ohne Token-Transfer).
- 2026-02-08: Invariant Suite (`InvariantMiningManagerTest`) laeuft >5 Min ohne Abschluss (Timeout). Vorschlag: Token-Anzahl im Handler cappen oder Test-Depth reduzieren.
- 2026-02-08: TWAP-Fees umgestellt: `updateIfDue()` wird in Claim/Upgrade ausgefuehrt (>=2h), Preis wird gecached; bei stale/fehlendem MeBTC -> USDC-only Fallback.
- 2026-02-25: Invariant-Timeout entschaerft: `InvariantHandler` cappt `tokenIds` (`MAX_TRACKED_TOKENS = 120`) und `foundry.toml` nutzt `[invariant] runs=32, depth=25, fail_on_revert=false`. Ergebnis: `forge test` laeuft durch (51 passed, 0 failed).
- 2026-02-25: P0-Tests ergaenzt: `test_ClaimWithMebtcRevertsWhenShareAboveMax`, `test_UpgradeWithMebtcRevertsWhenShareAboveMax`, neue Suites `StakeVaultTest` (Tier/Lock/Unstake) und `ResyncMinerTest` (Drift-Korrektur + Revert bei inkonsistentem Total).
- 2026-02-25: Follow-up `share > MAX`: Contract revertiert korrekt mit `mebtc%`; die fruehere Fehlbeobachtung kam aus fehlerhaftem `expectRevert`-Setup im Test (Getter-Call nach `expectRevert`).
- 2026-02-25: Regression-Status nach neuen Tests: `forge test` komplett gruen (59 passed, 0 failed).
- 2026-03-15 (Redeploy #11): MiningManager – `SafeERC20` eingeführt; `transferFrom` fuer USDC und MeBTC-Gebuehren revertiert jetzt korrekt statt bei `false`-Return still zu schweigen (commit `aa20ff6`).
- 2026-03-15: MiningManager – `MAX_SLOTS_PER_UPDATE = 1000` cappt Slot-Loops in `_update()` und `_computeState()`; verhindert Gas-Overflow nach langen Pausen.
- 2026-03-15: MiningManager – Transfer-Clear bei NFT-Uebertragung: `pendingReward`, `remainder` und Schulden werden auf 0 gesetzt (`MinerTransferCleared`-Event). Vorherige Claims des alten Besitzers empfohlen.
- 2026-03-15: MinerNFT – Guard `manager != address(0)` in `_requestUpgradePower` und `_requestUpgradeHash` ergaenzt; verhindert stille Fehlschlaege ohne gesetzten Manager.
- 2026-03-15: MinerNFT – Primaerverkauf-Split: 90 % → DemandVault, 10 % → ProjectWallet (vorher 95/5).
- 2026-03-15: LiquidityEngine – `lastEpoch` wird jetzt im Constructor auf `block.timestamp` gesetzt; Zero-Fallback in `executeEpoch()` entfaellt (vereinfacht Zustandslogik).
- 2026-03-15: LiquidityEngine-Tests – alle `vm.warp()`-Aufrufe auf `engine.lastEpoch() + engine.epochSeconds()` umgestellt (setzt Constructor-Aenderung voraus). `forge test` gruen.
