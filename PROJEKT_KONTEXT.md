# MeBTC – Vollständige Projektbeschreibung für KI-Kontext

**Zweck dieses Dokuments**: Diese Datei beschreibt das MeBTC-Protokoll vollständig und präzise,
damit Claude in neuen Gesprächen sofort den technischen und konzeptionellen Kontext versteht.
Kernthema des Projekts ist **faires, deterministisches On-Chain-Mining** – dieser Grundsatz
durchzieht jeden Teil des Systems.

---

## 1. Projektübersicht

**MeBTC** ist ein dezentrales Mining-Economy-Protokoll auf Avalanche (EVM-kompatibel).
Nutzer kaufen Miner-NFTs mit USDC und erhalten dafür MeBTC-Token als Belohnung.
MeBTC ist ein ERC20-Token mit einem **harten Deckel von 21.000.000 Stück** (8 Dezimalstellen –
analog zu Bitcoin) und einer **automatischen Halbierung der Emission alle 210.000 Slots**
(ca. 4 Jahre, da 1 Slot = 10 Minuten).

Das Protokoll kombiniert:
- **Bitcoin-Mechanik** (Halving, knapper Supply, faire Verteilung)
- **DeFi-Infrastruktur** (Trader Joe V2 DEX, TWAP-Preisermittlung, LP-Epoch-Engine)
- **NFT-basierte Partizipation** (6 Miner-Modelle mit unterschiedlicher Leistung/Kosten)
- **Staking-Boni** (4 Tiers mit Hash-/Power-Boni und Lockup-Perioden)

---

## 2. Technologiestack

| Schicht       | Technologie                                    |
|---------------|------------------------------------------------|
| Smart Contracts | Solidity 0.8.26, Foundry (forge, cast)       |
| DEX-Integration | Trader Joe V2 (Liquidity Bin Protocol)       |
| Frontend      | Vue 3 + TypeScript, Vite, TailwindCSS, ethers.js v6 |
| Wallet-Connect | ReOwn AppKit                                 |
| Testnet       | Avalanche Fuji (C-Chain)                       |
| Build-Optimierung | via_ir: true, optimizer runs: 20.000       |

---

## 3. Smart-Contract-Architektur

Das Protokoll besteht aus **8 Kernverträgen**, die strikt getrennte Verantwortlichkeiten haben.

```
MinerNFT ──────────────────────────────────────┐
    │ buyFromModel()                            │
    │ requestUpgradeHash/Power()                │
    └─────────────► MiningManager ─────────────► MeBTC (Mint)
                         │                          (ERC20, 21M cap)
                         │ onStakeChange()
                         ▼
                    StakeVault
                         │
                    DemandVault (USDC) ──► LiquidityEngine ──► Trader Joe V2 LP
                    FeeVault (MeBTC)   ──►        │
                                                  ▼
                                          TwapOracleJoeV2
```

### 3.1 MiningManager (`src/core/MiningManager.sol`)

**Herzstück des Protokolls.** Verantwortlich für:
- Slot-basierte Emissionsberechnung (10-Minuten-Takt)
- Belohnungsverteilung proportional zur effektiven Hashrate
- Gebührenabrechnung pro Slot
- Halbierungslogik

**Wichtige Funktionen:**

| Funktion | Beschreibung |
|----------|-------------|
| `claim(uint256[] ids)` | Belohnungen für eigene Miner auszahlen, Gebühren abrechnen, ausstehende Upgrades aktivieren |
| `claimWithMebtc(ids, mebtcShareBps)` | Wie `claim`, aber bis zu 30 % der Gebühren in MeBTC statt USDC zahlen |
| `_update()` | Interne Slot-Fortschreibung und Halving-Check |
| `preview(tokenId, owner)` | Schätze ausstehende Belohnungen und Gebühren (kein State-Change) |
| `onMinerTransfer()` | Hook bei NFT-Übertragung (setzt Belohnungs-Checkpoint) |
| `onStakeChange()` | Wird von StakeVault aufgerufen; berechnet effektive Hash/Power aller Miner des Nutzers neu |
| `resyncMiner(tokenId)` | Permissionless-Helper: korrigiert Drift in effektiver Hashrate/Power |

**Belohnungsformel:**
```
reward_per_slot = (effectiveHashrate_miner / totalEffectiveHashrate) × 50 MeBTC
```
- Anfangsemission: 50 MeBTC pro 10-Minuten-Slot
- Halving: Bei `blockIndex % 210_000 == 0` halbiert sich die Emission
- Präzision: Reste werden mit 1e12 skaliert getragen (verhindert Rundungsangriffe)

**Gebührenformel:**
```
fee_per_slot = (powerWatt × 600s × 0,15 USDC/kWh) / 3.600.000
```
- 0,15 USDC pro kWh (150.000 interne Einheiten bei 6 Dezimalstellen)
- Gebühren-Split: **90 % → DemandVault (USDC)**, **10 % → ProjectWallet**
- Optionaler MeBTC-Anteil: max. 30 % der Gebühren in MeBTC; Fallback zu reinem USDC wenn TWAP veraltet

---

### 3.2 MinerNFT (`src/nft/MinerNFT.sol`)

**Verwaltung der Miner-NFTs und Upgrade-Anfragen.**

**6 Miner-Modelle** (konfiguriert via `SetupModels.s.sol`):

| Modell     | Basis-Hashrate | Leistung | Max. Supply | Preis   | Min. Liquidität |
|------------|----------------|----------|-------------|---------|-----------------|
| RigMiner   | 500 GH/s       | 200 W    | 50.000      | 24 USDC | —               |
| BasicMiner | 13,5 TH/s      | 1.350 W  | 20.000      | 49 USDC | 10.000 USDC     |
| MeMiner    | 50 TH/s        | 2.250 W  | 10.000      | 124 USDC| 50.000 USDC     |
| ProMiner   | 104 TH/s       | 3.068 W  | 3.000       | 349 USDC| 200.000 USDC    |
| PrimeMiner | 200 TH/s       | 3.500 W  | 800         | 749 USDC| 750.000 USDC    |
| ApexMiner  | 270 TH/s       | 3.645 W  | 200         | 1.499 USDC | 2.000.000 USDC |

**Upgrade-System:**
- 4 Stufen Hashrate-Upgrade: je +2,5 % (max. +10 %)
- 4 Stufen Power-Upgrade: je -5 % (max. -20 % Stromverbrauch)
- Upgrades werden **sofort bezahlt**, aber **erst nach dem nächsten Claim aktiv**
  (Fairness: kein rückwirkender Vorteil gegenüber anderen Minern)

**Liquidity Gate:**
- Modelle können eine Mindestliquidität im Trading-Pair erfordern
- Verhindert: Sybil-Angriffe und Dump-Szenarien vor Marktreife
- Ist die Liquidität zu niedrig → `buyFromModel()` revert

**Zahlungsfluss bei Kauf:**
- 90 % des Kaufpreises → DemandVault
- 10 % → ProjectWallet

**ERC2981-Royalties:** Alle Sekundärmarkttransfers tragen eine konfigurierbare Royalty.

---

### 3.3 MeBTC Token (`src/token/MeBTC.sol`)

- Standard ERC20, 8 Dezimalstellen
- **Harter Supply-Deckel: 21.000.000 MeBTC**
- Nur der MiningManager darf minten
- Kein Burn-Mechanismus

---

### 3.4 StakeVault (`src/core/StakeVault.sol`)

**Optionales Staking mit Tier-basierten Boni.**

| Tier | Mindest-MeBTC | Lock-Periode | Hash-Bonus | Power-Reduktion |
|------|---------------|--------------|------------|-----------------|
| 0    | 0             | –            | 0 %        | 0 %             |
| 1    | 10.000        | 30 Tage      | +5 %       | -5 %            |
| 2    | 50.000        | 90 Tage      | +10 %      | -12 %           |
| 3    | 250.000       | 180 Tage     | +15 %      | -20 %           |

**Fairness-Mechaniken:**
- Lock-Zeit verlängert sich **nur bei Tier-Upgrade**, nicht bei jeder weiteren Einzahlung
- Tier-Upgrade nur wenn neue Schwelle wirklich überschritten wird
- Flash-Loan-Schutz durch Lockup
- `onStakeChange()` → MiningManager berechnet effektive Hash/Power aller Miner des Nutzers neu

---

### 3.5 LiquidityEngine (`src/core/LiquidityEngine.sol`)

**Automatisches Liquiditätsmanagement via Epoch-Mechanismus.**

**`executeEpoch()`** (Standard-Interval: 3600 Sekunden):
1. Auto-Compounding bestehender LP-Positionen (konfigurierter Prozentsatz verbrennt und re-mintet)
2. Neue Liquidität hinzufügen wenn:
   - DemandVault-USDC ≥ minUsdc (Standard: 10 USDC)
   - FeeVault-MeBTC > 0
   - Epoch-Fenster abgelaufen
3. Token-Verhältnis-Balancierung via `_capByMin()` (berücksichtigt 8-2=6 Dezimalstellen-Differenz)

**Fairness:** Liquidität wird nur hinzugefügt wenn **beide** Seiten Guthaben haben – keine einseitige LP-Erstellung.

---

### 3.6 TwapOracleJoeV2 (`src/core/TwapOracleJoeV2.sol`)

**TWAP-Preisorakel für USDC/MeBTC-Gebührenkonvertierung.**

| Parameter | Wert | Bedeutung |
|-----------|------|-----------|
| window | 3.600 s | Beobachtungsfenster (1h) |
| updateInterval | 7.200 s | Mindestabstand zwischen Updates (2h) |
| maxPriceAge | 7.200 s | Ab wann gilt Preis als veraltet (2h) |

- TWAP verhindert kurzfristige Preismanipulation
- Freshness-Check: Ist der Preis veraltet → MeBTC-Gebührenanteil deaktiviert, nur USDC
- `lastGoodPrice`-Cache: Letzter gültiger Preis wird gespeichert

---

### 3.7 TokenVault (`src/core/TokenVault.sol`)

Einfache Escrow-Wrapper für DemandVault (USDC) und FeeVault (MeBTC).
- `transferTo()` nur durch LiquidityEngine aufrufbar

---

## 4. Fairness-Mechanismen (Kernprinzip)

Fairness ist das zentrale Designprinzip von MeBTC. Hier sind alle Mechanismen im Detail:

### 4.1 Emissionsfairness
- **Proportionale Verteilung**: Jeder Miner erhält exakt seinen Anteil an der Gesamthashrate
- **Slot-Gating**: Alle Miner müssen denselben 10-Minuten-Slot abwarten
- **Remainder-Tracking**: Präzisionsverluste werden in 1e12-Skalierung mitgetragen – kein Slot-Rounding-Exploit möglich
- **Kein Backfill**: Wenn `totalEffectiveHash == 0`, werden keine Belohnungen erzeugt oder nachträglich verteilt

### 4.2 Upgrade-Fairness
- **Pending → Active nach Claim**: Upgrades werden in derselben `claim()`-Transaktion aktiviert – sie gelten erst ab dem **nächsten** Slot. Kein Miner kann sich rückwirkend einen höheren Anteil erschleichen.
- **Kosten vorab bezahlt**: Verhindern spekulatives Queuing ohne Commitment
- **Stufendeckelung**: Max. 4 Stufen pro Upgrade-Typ (Hash max. +10 %, Power max. -20 %)

### 4.3 Staking-Fairness
- **Klare Tier-Schwellen**: Keine discretionary Entscheidungen, nur objektive Schwellenwerte
- **Lock nur bei Tier-Erhöhung**: Wer bereits Tier 1 hat und mehr einzahlt ohne Tier 2 zu erreichen, bekommt keine neue Lock-Zeit
- **Sofortige Neuberechnung**: Beim Staking/Unstaking werden ALLE Miner des Nutzers neu berechnet

### 4.4 Liquidity Gate (Anti-Sybil/Anti-Dump)
- Miner-Modelle können einen Mindest-USDC-Bestand im Trading-Pair verlangen
- Gilt für **alle** Käufer gleichermaßen – keine Ausnahmen
- Verhindert: Massenprägung vor Marktreife, anschließender Dump

### 4.5 Gebührensicherheit
- TWAP: Zeitgewichteter Durchschnittspreis, 2-Stunden-Fenster
- Freshness-Fallback: Bei veraltetem Preis → 100 % USDC-Gebühren
- MeBTC-Share-Cap: Max. 30 % der Gebühren in MeBTC
- Insufficient-MeBTC-Fallback: Wenn Nutzer nicht genug MeBTC hat → volle USDC-Gebühr

### 4.6 Reentrancy-Schutz
`ReentrancyGuard` auf allen State-ändernden Funktionen:
- `claim()`, `claimWithMebtc()`
- `requestUpgradeHash()`, `requestUpgradePower()`
- `stake()`, `unstake()`
- `buyFromModel()`

### 4.7 Berechtigungsmodell
| Rolle | Berechtigungen |
|-------|---------------|
| Owner | `setPayToken`, `addModel`, `finalizeModel`, `setLiquidityOracle`, `setManager` |
| MiningManager | `applyPendingUpgrades`, `setLastClaimAt` (auf MinerNFT) |
| StakeVault | Trigger `onStakeChange` |
| LiquidityEngine | `transferTo` (auf TokenVaults) |
| Jeder | `resyncMiner`, `executeEpoch` (permissionless) |

---

## 5. Tokenomics

| Parameter | Wert | Anmerkung |
|-----------|------|-----------|
| MeBTC Gesamtsupply | 21.000.000 (8 Dez.) | Bitcoin-analog |
| Anfangsemission | 50 MeBTC/Slot (10 min) | ~2,6 Mio./Jahr initial |
| Halbierungsintervall | 210.000 Slots | ~4 Jahre |
| Mining-Gebühr | 0,15 USDC/kWh | Pro 10-Minuten-Slot |
| Kaufpreis-Split | 90 % DemandVault / 10 % ProjectWallet | Beim Miner-Kauf |
| Gebühren-Split | 90 % DemandVault / 10 % ProjectWallet | Laufende Mining-Gebühren |
| MeBTC-Gebührenanteil | Max. 30 % | Nur wenn TWAP frisch |
| Staking Tier 1 | 10.000 MeBTC, 30d Lock | +5 % Hash, -5 % Power |
| Staking Tier 2 | 50.000 MeBTC, 90d Lock | +10 % Hash, -12 % Power |
| Staking Tier 3 | 250.000 MeBTC, 180d Lock | +15 % Hash, -20 % Power |

---

## 6. Deployment & Konfiguration

### Aktuelles Fuji-Testnet-Deployment (Redeploy #11, 2026-03-15)

| Contract | Adresse |
|----------|---------|
| MiningManager | `0xCb4bc402784CF93dbe9E3504C7AD37eC7Cfa738F` |
| MinerNFT | `0xcd0604989548a6947D600D3Bb0A0808f7Ac5aFE1` |
| MeBTC | `0xfFfb0217713597608d88DcB7B8401a5B5893Ce84` |
| StakeVault | `0x82D7E18655e1A4e58fb68A7e4Ec6b3f806d54417` |
| LiquidityEngine | `0x873659698195103536bBC3F7b6d0304822cAD562` |
| TWAP Oracle | `0x046c3b8e32f3802A8d5A62b2096e2d8754De8EB6` |
| MockUSDC | `0x01900649664B7f221D11b6194A49597CBdF8C72e` |
| DemandVault | `0x80E8E3912FACC03245ad551c09681Be1Dd555009` |
| FeeVault (MeBTC) | `0xacad4b6525d85C6b0834e18aFcd9De695993F721` |
| LP Pair | `0xDfba4ed71aC02Bcba9F9B1a79Fbfa081A143914C` |

### Deployment-Workflow

1. `DeployMainnet.s.sol` – 8 Verträge in Reihenfolge deployen
2. `SetupModels.s.sol` – 6 Miner-Modelle anlegen (RigMiner → ApexMiner)
3. `FinalizeModel.s.sol` – Jedes Modell finalisieren (danach unveränderlich)
4. `MinerNFT.setLiquidityOracle()` – Liquidity Gate konfigurieren (optional)
5. `ListModels.s.sol` – Konfiguration verifizieren

### Wichtige Env-Variablen (`DeployMainnet.s.sol`)

```
PRIVATE_KEY          Deployer-Schlüssel
PAY_TOKEN            USDC-Adresse (6 Dezimalstellen zwingend)
JOE_FACTORY          Trader Joe V2 Factory
MIN_USDC_LP          Mindest-USDC für LiquidityEngine
EPOCH_SECONDS        Epoch-Länge (Standard: 3600)
LP_BURN_BPS          Auto-Compound-Anteil (BPS)
TWAP_WINDOW          Beobachtungsfenster (Standard: 3600)
PROJECT_WALLET       Empfänger des 10%-Anteils
ROYALTY_WALLET       NFT-Royalty-Empfänger
ROYALTY_BPS          Royalty-Prozentsatz (BPS)
```

---

## 7. Frontend

**Verzeichnis**: `frontend-vue/`

**Technologien**: Vue 3, TypeScript, Vite, TailwindCSS, ethers.js v6, ReOwn AppKit

**Wichtige Komponenten:**

| Komponente | Funktion |
|------------|----------|
| `MinerPricingCard` | Zeigt Modellpreise, Hashrate, Kaufbutton |
| `MinerScannerCard` | Zeigt einzelnen Miner mit Status |
| `ClaimCard` | Claim-Aktion mit optionalem MeBTC-Anteil |
| `OwnedMinersList` | Alle Miner des verbundenen Wallets |
| `StakingCard` | Tier-Anzeige, Stake/Unstake-Flows |
| `BalancesCard` | USDC- und MeBTC-Guthaben |
| `OracleActionsDropdown` | Epoch ausführen, TWAP-Freshness anzeigen |
| `Header` | Contract-Adressen, MeBTC-Preis |

**Wichtige Composables:**

| Composable | Zweck |
|------------|-------|
| `useMiningStats.ts` | Ausstehende Belohnungen und Gebühren |
| `useBalances.ts` | Wallet-Guthaben (USDC/MeBTC) |
| `useOwnedMinerTokenIds.ts` | Liste eigener Miner |
| `useRouterAllowances.ts` | Token-Approvals verwalten |
| `useMebtcForMiner.ts` | MeBTC-Gebührenanteil-Logik |

---

## 8. Tests

**Testverzeichnis**: `test/`
**Framework**: Foundry (forge test)
**Coverage**: 59+ Tests, 17 Test-Suites

| Test-Suite | Testschwerpunkte |
|------------|-----------------|
| `MiningManagerClaim.t.sol` | Claim-Logik, Preview-Genauigkeit, Multi-Miner-Verteilung |
| `MiningManagerHalving.t.sol` | Halving bei 210k Slots, Emissions-Reduktion |
| `StakeVault.t.sol` | Tier-Setzen, Lock-Zeit-Logik, Unlock-Revert |
| `LiquidityEngine.t.sol` | LP-Hinzufügen, Auto-Compound, `_capByMin` |
| `TwapOracleJoeV2.t.sol` | UpdateIfDue, frisch/veraltet-Erkennung |
| `SecurityScenarios.t.sol` | Auth-Checks, Allowance-Reverts, MeBTC-Fallback |
| `LiquidityGate.t.sol` | Kauf-Revert bei zu geringer Liquidität |
| `MinerNFT.t.sol` | Mint, Transfer, Upgrade-Requests |
| `ResyncMiner.t.sol` | Drift-Korrektur, Neuberechnung |
| `InvariantMiningManager.t.sol` | Fuzzing: totalEffectiveHash-Konsistenz, kein Overflow |

**Foundry-Konfiguration (`foundry.toml`)**:
- Invariant: runs=32, depth=25, fail_on_revert=false
- Solc: 0.8.26, via_ir: true, optimizer runs: 20.000

---

## 9. Sicherheitsstatus

### Implementierte Schutzmaßnahmen
- Reentrancy Guards auf allen State-ändernden Funktionen
- `onlyOwner`-Modifikatoren für kritische Konfiguration
- Rollenbasierter Zugriff (Manager, StakeVault, LiquidityEngine)
- Dezimalvalidierung: PayToken muss 6 Dezimalstellen haben, MeBTC hat 8
- Harter Supply-Deckel (no backdoor mint)
- Remainder-Tracking gegen Rundungsangriffe
- TWAP-Freshness-Checks mit Fallback

### Bekannte und dokumentierte Punkte (`SECURITY_CHANGES.md`)
- `LiquidityEngine._mintLiquidity()`: SafeERC20-Wrapping (nicht-standard ERC20 abgesichert)
- `LiquidityEngine.executeEpoch()`: Externes DEX-Call → optionales `nonReentrant`
- `TokenVault.transferTo()`: Externer Call (SWC-107) – dokumentiertes, bewusstes Design

### Behobene Probleme
- TWAP-Caching (2026-02-08): Preis-Cache bei stündlichem Update
- Invariant-Timeout (2026-02-25): Token-Tracking gedeckelt, Depth reduziert
- MeBTC-Fallback (2026-02-08): Automatischer USDC-Only-Fallback bei veraltetem Preis

---

## 10. Dateistruktur (Wichtigste Dateien)

```
MeBTC/
├── src/
│   ├── core/
│   │   ├── MiningManager.sol      # Kernvertrag: Emissionen, Claim, Halving
│   │   ├── StakeVault.sol         # Staking mit Tier-Boni
│   │   ├── LiquidityEngine.sol    # Epoch-basiertes LP-Management
│   │   ├── TwapOracleJoeV2.sol    # TWAP-Preisermittlung
│   │   └── TokenVault.sol         # Escrow für USDC/MeBTC-Vaults
│   ├── nft/
│   │   └── MinerNFT.sol           # Miner-NFTs, Modelle, Upgrades, Liquidity Gate
│   └── token/
│       └── MeBTC.sol              # ERC20, 21M Supply-Cap
├── test/
│   ├── helpers/
│   │   └── MeBTCTestBase.sol      # Gemeinsame Test-Infrastruktur
│   └── *.t.sol                    # 17 Test-Suites
├── script/
│   ├── DeployMainnet.s.sol        # Vollständiges Deployment
│   ├── SetupModels.s.sol          # 6 Miner-Modelle anlegen
│   ├── FinalizeModel.s.sol        # Modell finalisieren
│   ├── ResyncMiner.s.sol          # Permissionless Miner-Resync
│   └── ListModels.s.sol           # Konfiguration anzeigen
├── frontend-vue/
│   ├── src/
│   │   ├── components/            # 57 Vue/TS-Dateien
│   │   ├── composables/           # ethers.js-Logik
│   │   └── main.ts / App.vue
├── .env.fuji                      # Fuji-Testnet-Konfiguration
├── foundry.toml
├── LITEPAPER.md                   # Technische Spezifikation
├── README.md                      # Projektübersicht
└── SECURITY_CHANGES.md            # Sicherheits-Änderungsprotokoll
```

---

## 11. Kern-Invarianten des Protokolls

Diese Invarianten gelten zu jeder Zeit und werden durch Tests geprüft:

1. **Supply-Invariante**: `MeBTC.totalSupply() ≤ 21.000.000 × 10^8` – niemals überschritten
2. **Hashrate-Invariante**: `Σ(effectiveHashrate aller Miner) == totalEffectiveHashrate` im MiningManager
3. **Claim-Monotonie**: `lastClaimSlot` eines Miners wächst nur, niemals zurück
4. **Upgrade-Reihenfolge**: Upgrades aktivieren sich ausschließlich in `claim()`, nie rückwirkend
5. **Gebühren-Fairness**: Jeder Slot wird genau einmal abgerechnet – keine Doppelabrechnung

---

## 12. Häufige Operationsabläufe

### Nutzer kauft Miner
1. Nutzer genehmigt USDC (`approve(MinerNFT, amount)`)
2. `MinerNFT.buyFromModel(modelId, qty)` – Zahlung + NFT-Mint
3. 90 % USDC → DemandVault, 10 % → ProjectWallet
4. Miner ist sofort aktiv, `lastClaimSlot = currentSlot`

### Nutzer claimes Belohnungen
1. Optional: Genehmigt MeBTC für Gebührenanteil
2. `MiningManager.claim([tokenId1, tokenId2, ...])` oder `claimWithMebtc(..., mebtcShareBps)`
3. Pro Miner: Belohnungen berechnen, Gebühren abziehen, ausstehende Upgrades aktivieren
4. MeBTC wird an Wallet gesendet

### Nutzer staked MeBTC
1. `MeBTC.approve(StakeVault, amount)`
2. `StakeVault.stake(amount)`
3. Tier berechnen → falls Tier-Upgrade: Lock-Zeit setzen
4. `onStakeChange()` → MiningManager berechnet alle Miner des Nutzers neu

### Liquidity Epoch ausführen
1. Jeder kann `LiquidityEngine.executeEpoch()` aufrufen
2. Prüfung: Epoch-Fenster abgelaufen? Beide Vaults haben Guthaben?
3. Auto-Compound + neue Liquidität hinzufügen

---

*Dieses Dokument wurde am 2026-03-15 erstellt und beschreibt den Stand nach Fuji Redeploy #11.*
