## Test Ablauf auf Fuji (Checkliste)

### Aktive Deployment-Daten (Redeploy #6, 2026-02-07, Full-Interval Rewards)
- PAY_TOKEN_ADDRESS=0x01900649664B7f221D11b6194A49597CBdF8C72e
- MANAGER_ADDRESS=0x99A58B07b483b7Ef321743700B246F668c1f1732
- MINER_ADDRESS=0x67BeE4Ec6ADB03fD5feb604f70D2498F9D9073C1
- MEBTC_ADDRESS=0x29fFA0F955D9ED0573ce489475B91bb7Cd5D1dD1
- DEMAND_VAULT=0x4f0a2AABC72185A7129EEcC27FC9079eb6c4b191
- FEE_VAULT_MEBTC=0x5653478937CE10c6c1F7EAE33B64348D6A0FDe0B
- TWAP_ORACLE=0x0F481f788ab482823CbF0428398e56f404bB8710
- PAIR_ADDRESS=0xf68007af4B8BAaEb2Da060B5d5e2127eE499b612
- STAKE_VAULT=0xFc2f32cfE6d08F7eEf53D1382e414b728Cfac5D2
- ENGINE_ADDRESS=0x6B406Cdb7A38C22EC11fa9D3Ee6A46E4F1eBFcf9

### Standardbetraege (Default)
- Buy: 1 Miner (ModelId 1)
- Claim: nach 1-2 Slots (~10-20 Min)
- Stake: 10_000 MeBTC
- claimWithMebtc: 30% Fee-Split
- Liquidity: 1_000 USDC + entsprechendes MeBTC

### 0) Vorbereitungen
- [x] Frontend laeuft und neue Adressen sind geladen
- [x] Pay-Token (USDC/Mock-USDC) auf Test-Adresse vorhanden

Info (Fuji RPC Referenz):
- https://api.avax-test.network/ext/bc/C/rpc

### 1) Grundfunktionen (UI)
- [x] Wallet verbinden (Fuji)
- [x] Miner kaufen (BasicMiner)
- [x] 1-2 Slots warten (~10-20 Min), dann Claim
- [x] MeBTC-Balance gestiegen
- [x] DemandVault USDC gestiegen
- [x] Mining-Stats zeigen neue Werte
- [x] Miner ist sofort aktiv (Hashrate/Power sichtbar, keine Pending-Aktivierung)

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

### 7) E2E-Checkliste (Frontend)
- [ ] Wallet connect: connect/disconnect/reconnect
- [ ] Netzwerkwechsel: falsches Netzwerk -> Meldung; nach Switch ok
- [ ] Buy Flow: Approve -> Buy -> Receipt -> UI-Stats/Balances aktualisiert
- [ ] Claim Flow: vor Slot blockiert; nach Slot Claim ok; Stats aktualisiert
- [ ] Upgrade Flow: Pending sichtbar; nach Claim aktive Werte sichtbar
- [ ] Stake Flow: Approve -> Stake -> Lock-Timer; Unstake vor Ablauf blockiert
- [ ] claimWithMebtc: Fee-Split korrekt; Balances/Vaults aktualisiert
- [ ] Liquidity: Approve -> Add Liquidity -> Pool-Reserven sichtbar
- [ ] TWAP/Epoch (falls UI): Update/Execute -> Status-Update sichtbar
- [ ] Error Handling: Tx reject/RPC error/Timeout -> klare Fehler
- [ ] State Refresh: Page reload nach Tx -> Daten korrekt (kein stale cache)
- [ ] Chain-Check: ChainID pruefen (Fuji = 43113); falsche Chain blockiert

#### Erwartete Ergebnisse (Details)
- Wallet connect:
  - Connect -> Adresse sichtbar, Chain-ID korrekt, UI-Status "connected".
  - Disconnect -> keine Aktionen moeglich, UI zeigt "disconnected".
  - Reconnect -> vorherige Adresse/State wiederhergestellt.
- Netzwerkwechsel:
  - Falsches Netz -> klare Fehlermeldung, Buttons disabled.
  - Nach Switch -> Buttons enabled, Daten werden neu geladen.
- Buy Flow:
  - Approve -> Tx bestaetigt, Allowance im UI aktualisiert.
  - Buy -> Miner-ID sichtbar, DemandVault steigt, Stats refresh.
  - Miner aktiv sofort (keine Retro-Rewards; Rewards erst ab naechstem vollen Slot).
- Claim Flow:
  - Vor Slot -> UI blockiert oder zeigt "noch nicht".
  - Nach Slot -> Claim Tx ok, MeBTC-Balance erhoeht, Fees abgezogen.
- Upgrade Flow:
  - Upgrade anstossen -> Pending sichtbar.
  - Nach Claim -> Pending verschwindet, aktive Werte aktualisiert.
- Stake Flow:
  - Approve/Stake -> Lock-Timer gesetzt, Tier/Boni sichtbar.
  - Unstake vor Ablauf -> tx fail, UI zeigt Fehler.
- claimWithMebtc:
  - Fee-Split Anzeige korrekt; FeeVaultMeBTC und DemandVault Werte konsistent.
- Liquidity:
  - Add Liquidity -> Pool-Reserven sichtbar, Pair-Adresse vorhanden.
- TWAP/Epoch:
  - Update/Execute -> Status/Stats aktualisieren sich.
- Error Handling:
  - User Reject/RPC Fail/Timeout -> UI zeigt klare Meldung, kein "stuck" State.
- State Refresh:
  - Reload nach Tx -> alle Werte korrekt (keine stale cache).

#### Abnahme-Kriterien (Pass/Fail)
- Wallet connect: PASS wenn connect/disconnect/reconnect jeweils ohne Reload funktioniert.
- Netzwerkwechsel: PASS wenn UI bei falschem Netz blockiert und nach Switch sauber aktiviert.
- Buy Flow: PASS wenn Miner-ID sichtbar, Allowance korrekt, Stats/Balances updaten.
- Claim Flow: PASS wenn vor Slot keine Tx moeglich/revert und nach Slot Reward+Fee korrekt.
- Upgrade Flow: PASS wenn Pending sichtbar und nach Claim aktive Werte aktualisiert.
- Stake Flow: PASS wenn Lock-Timer korrekt, Unstake vor Ablauf failt.
- claimWithMebtc: PASS wenn Fee-Split exakt und Vaults stimmen.
- Liquidity: PASS wenn Reserves/Pair sichtbar und UI konsistent.
- TWAP/Epoch: PASS wenn Status/Stats nach Execute korrekt.
- Error Handling: PASS wenn Fehler klar angezeigt und UI nicht haengt.
- State Refresh: PASS wenn nach Reload keine stale Werte verbleiben.
