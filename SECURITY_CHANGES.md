# Security Change Log (MeBTC)

## Planned Contract Changes
- [ ] LiquidityEngine: `SafeERC20`/Return-Checks in `_mintLiquidity` (src/core/LiquidityEngine.sol:145-148). Grund: unchecked transfer; Risiko bei non-standard ERC20.
- [ ] LiquidityEngine: optional `nonReentrant` auf `executeEpoch` oder Trust-Boundary dokumentieren (src/core/LiquidityEngine.sol:70-79). Grund: Slither Reentrancy-Hinweis.
- [ ] TokenVault: `transferTo` externe Call (SWC-107) als bewusstes Pattern dokumentieren oder Guard erwaegen (src/core/TokenVault.sol:28-33).

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
