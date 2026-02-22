## MeBTC TODO

### Erledigt
- Staking-Vault + Tier-Boni + Lock-Periods
- MiningManager-Integration fuer staking-angepasstes Hash/Power
- Fee-Split (USDC + optional MeBTC via TWAP-Gate)
- Demand/Fee-Vaults + Creator-Fee 10%
- Liquidity Engine (Epoch Add + Auto-Compound)
- TWAP-Oracle-Adapter (Trader Joe V2)
- Modelle auf Fuji angelegt (u. a. BasicMiner, MeMiner)
- Fuji Basisflows validiert: Buy, Claim, Upgrade, Staking, claimWithMebtc, Liquidity
- Fuji TWAP >=2h Formalcheck validiert (2026-02-17)
- Foundry Test-Suite inkl. Invariants/Fork-Lauf gruen
- Frontend-Updates aktiv: Staking-UI, claimWithMebtc/upgradeWithMebtc, Liquidity + Epoch-Trigger

### Offen / Naechste Schritte
- MiningManager/Contracts erweitern: aktive Miner-Anzahl als direkte View abrufbar machen (gesamte Hashrate ist bereits ueber `totalEffectiveHash` verfuegbar)
- Token-Reset ohne Redeploy pruefen (setPayToken vs. Vault/Engine/TWAP Bindung)
- Fuji Frontend E2E-Regression (Section 7 in `TEST_ABLAUF_FUJI.md`) bei naechstem Deploy komplett durchlaufen
- NFT-Metadaten-Strategie finalisieren (IPFS Multi-Pin / Arweave / On-Chain SVG)
