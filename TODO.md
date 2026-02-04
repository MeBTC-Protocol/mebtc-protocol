## MeBTC TODO

### Erledigt
- Staking-Vault + Tier-Boni + Lock-Periods
- MiningManager-Integration fuer staking-angepasstes Hash/Power
- Fee-Split (USDC + optional MeBTC via TWAP-Gate)
- Demand/Fee-Vaults + Creator-Fee 10%
- Liquidity Engine (Epoch Add + Auto-Compound)
- TWAP-Oracle-Adapter (Trader Joe V2)

### In Arbeit
- Modelle anlegen (BasicMiner, MeMiner) auf Fuji

### Naechste Schritte
- MiningManager/Contracts erweitern: aktive Miner-Anzahl und gesamte Hashrate (inkl. Upgrades + Stake-Bonus) als direkte View abrufbar machen
- Token-Reset ohne Redeploy pruefen (setPayToken vs. Vault/Engine/TWAP Bindung)
- Fuji: Testkauf (Miner minten)
- Fuji: Claim (USDC Fee zahlen, MeBTC minten)
- Fuji: Liquidity im Trader Joe V2 Pool hinzufuegen
- Fuji: TWAP update + Engine executeEpoch
- Tests fuer TWAP-Readiness + Fee-Split-Flow + LiquidityEngine-Epoch erweitern
- Frontend-Updates:
  - neue Contract-Adressen und ABIs
  - Staking-UI + Lock-Timer
  - claimWithMebtc + upgradeWithMebtc Flows
  - Liquidity-Dashboard + Epoch-Trigger
- NFT-Metadaten-Strategie finalisieren (IPFS Multi-Pin / Arweave / On-Chain SVG)
