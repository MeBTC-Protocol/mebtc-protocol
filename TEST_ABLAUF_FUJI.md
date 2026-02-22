## Test Ablauf auf Fuji (Checkliste)

### Aktive Deployment-Daten (Redeploy #9, 2026-02-11, Cached TWAP + USDC Fallback)
- PAY_TOKEN_ADDRESS=0x01900649664B7f221D11b6194A49597CBdF8C72e
- MANAGER_ADDRESS=0x929A4287ef98fe69b04e0a6023AF6b0aACB03381
- MINER_ADDRESS=0x1d3AAeFd45A280f223f791F0684D95008ad0f420
- MEBTC_ADDRESS=0xFCaCB5f7822b53F014340a0A2321F9b90013C18d
- DEMAND_VAULT=0xb034EBb58Dac2006d950CE5993626cdfec39B086
- FEE_VAULT_MEBTC=0xa63932A47b649C7C6775f532872abdde81b11fFF
- TWAP_ORACLE=0x8025b93dBF756987202c2BE0f35b906Bf2997F70
- PAIR_ADDRESS=0x655C942A1351bD1C9AFC11a6d0E2cA2FD777DBcC
- STAKE_VAULT=0x482D88b04739075805dD3dE79BdDa985484ED676
- ENGINE_ADDRESS=0xfFE3A1aa5079241eFD5E04a2a91BdF4777b60bD0

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
- Fork-Referenz (2026-02-16): `forge test --fork-url http://127.0.0.1:8545 --fork-block-number 78033775` -> 49/49 gruen

### 1) Grundfunktionen (UI)
- [x] Wallet verbinden (Fuji)
- [x] Miner kaufen (BasicMiner)
- [x] 1-2 Slots warten (~10-20 Min), dann Claim
- [x] MeBTC-Balance gestiegen
- [x] DemandVault USDC gestiegen
- [x] Mining-Stats zeigen neue Werte
- [x] Miner ist sofort aktiv (Hashrate/Power sichtbar, keine Pending-Aktivierung)

### 2) Staking
- [x] MeBTC Approve (StakeVault)
- [x] Stake (z. B. 10k)
- [x] Tier/Boni sichtbar
- [x] Lock-Timer gesetzt
- [x] Unstake vor Ablauf blockiert (Unlock erst nach 30 Tagen)

### 3) Upgrades
- [x] Upgrade Power/Hash anstossen
- [x] Claim ausfuehren
- [x] Pending -> Active gewechselt
- [x] Fees korrekt in DemandVault

### 4) Liquidity
- [x] USDC + MeBTC Approve (Router)
- [x] Add Liquidity via UI
- [x] Pool-Reserven in Mining-Stats sichtbar
- [x] Pair existiert (Address im Header sichtbar)

### 5) TWAP + Engine
- [x] >= 2h warten (Auto-TWAP-Fenster)
- [x] Claim/Upgrade ausfuehren (triggert TWAP-Update, wenn >=2h seit letztem Update)
- [x] LiquidityEngine.executeEpoch() ausfuehren
- [x] Vaults sinken, Pool-Reserven steigen (FeeVaultMeBTC benoetigt)
- [x] Auto-Compound sichtbar (optional, FeeVaultMeBTC/LP benoetigt)

Verifiziert am 2026-02-17 (Fuji, ChainID 43113):
- Upgrade-Batch (Power, IDs [1,3]): `0xf3673c7c457771ef58875e5e0a9bc022565f4d51de8b9c7975f34a748c1a1746`, `0x04a3b2a4155d4d7569d331dd96c2a2fa7a17de8a1c93fc0805fe798db9787677`, `0x8d837fadc9592a49b8d23ae1ebaf3d71a5460673742a607a70ca237865375470`
- Claim (IDs [1,3]): `0xf1fdbfaf9e9c75f10bbec361d531d58ea64bf7119948ca13a083b2f2cabd4847`
- ExecuteEpoch: `0x7fe688d8fde88436e8ee0ac6d6712f0c1227e7c48d55d42ba093b47ee1aaec6a`
- Effekte: `lastEpoch` 18000 -> 21600, DemandVault USDC 854000 -> 0, FeeVaultMeBTC 1867736973 -> 581336973, Pair-Reserven stiegen (USDC 161211610 -> 174075610, MeBTC 33691569437 -> 34977969437).
- Auto-Compound im ExecuteEpoch-Receipt vorhanden (`AutoCompounded` + `EpochExecuted` Events).
- TWAP >=2h Formalcheck am 2026-02-17: `claim([1,3])` Tx `0xe51203cade7aae5890bf917314637bebdc9cc997971c5ddf75e2e20312dcf31e`;
  `lastTimestamp`/`lastGoodTimestamp` 1771350656 -> 1771358363 (Delta +7707s),
  `getPriceForFees` danach wieder `fresh=true`; Oracle-Events `PriceCached` + `OracleUpdated` im Receipt vorhanden.

### 6) Fee-Split mit MeBTC
- [x] claimWithMebtc (z. B. 30%) testen
- [x] FeeVaultMeBTC steigt
- [x] DemandVault USDC Restbetrag korrekt

### 7) E2E-Checkliste (Frontend, Re-Test bei neuem Deploy)
- Status: offen als Regression-Checkliste fuer kommende Deploys; Basisflows wurden in 1-6 bereits validiert.
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
