## Test Ablauf auf Fuji (Checkliste)

### 0) Vorbereitungen
- [x] Frontend laeuft und neue Adressen sind geladen
- [x] Mock-USDC auf Test-Adresse vorhanden

### 1) Grundfunktionen (UI)
- [x] Wallet verbinden (Fuji)
- [x] Miner kaufen (BasicMiner)
- [x] 2 Slots warten (~20 Min), dann Claim
- [x] MeBTC-Balance gestiegen
- [x] DemandVault USDC gestiegen
- [x] Mining-Stats zeigen neue Werte

### 2) Staking
- [ ] MeBTC Approve (StakeVault)
- [ ] Stake (z. B. 10k)
- [ ] Tier/Boni sichtbar
- [ ] Lock-Timer gesetzt
- [ ] Unstake vor Ablauf blockiert

### 3) Upgrades
- [x] Upgrade Power/Hash anstossen
- [x] Claim ausfuehren
- [x] Pending -> Active gewechselt
- [ ] Fees korrekt in DemandVault

### 4) Liquidity
- [x] USDC + MeBTC Approve (Router)
- [x] Add Liquidity via UI
- [x] Pool-Reserven in Mining-Stats sichtbar
- [x] Pair existiert (Address in Stats)

### 5) TWAP + Engine
- [x] 60 Min warten (TWAP Window)
- [x] TwapOracle.update() ausfuehren
- [x] LiquidityEngine.executeEpoch() ausfuehren
- [ ] Vaults sinken, Pool-Reserven steigen
- [ ] Auto-Compound sichtbar (optional)

### 6) Fee-Split mit MeBTC
- [x] claimWithMebtc (z. B. 30%) testen
- [x] FeeVaultMeBTC steigt
- [x] DemandVault USDC Restbetrag korrekt
