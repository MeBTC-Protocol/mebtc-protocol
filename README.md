## MeBTC (Contracts + Frontend)

Diese README fasst die aktuelle Projektstruktur, die Kern-Logik und die Test-Abläufe zusammen.

## Projekt-Map

- `src/` Smart Contracts
- `test/` Foundry Tests (Unit/Integration/Invariant)
- `script/` Deploy- und Admin-Skripte
- `frontend-vue/` Vue UI
- `TEST_PLAN.md` Gesamt-Testplan
- `TEST_ABLAUF_FUJI.md` Fuji E2E Checkliste (inkl. aktueller Deploy-Daten)
- `DEPLOY_ADDRESSES_FUJI.md` Address-Historie und aktuelle Fuji-Deploys
- `SECURITY_CHANGES.md` Change-Log + Findings

## Kern-Contracts (Kurz)

- `MiningManager`: Claims, Fees, Emission, Halving, TWAP-Checks
- `MinerNFT`: Miner-Kauf + Upgrade-Requests (Pending bis Claim)
- `MeBTC`: Reward Token mit Supply-Cap
- `StakeVault`: Staking + Lock
- `TokenVault`: Vault-Wrapper (Demand/Fee)
- `LiquidityEngine`: Epoch-basierte Liquidity & Auto-Compound
- `TwapOracleJoeV2`: TWAP-Oracle (Time-Weighted Average Price)

## Flows (High-Level)

1) **Buy Miner** (USDC) -> Miner aktiv, Rewards ab naechstem Slot.
2) **Claim** -> mintet MeBTC; Fees gehen an DemandVault (USDC) und optional FeeVaultMeBTC.
3) **Upgrade** -> Kosten in USDC (oder Anteil in MeBTC), aktiv nach Claim.
4) **Stake** -> Lock + Boni.
5) **TWAP + Epoch** -> TWAP wird bei Claim/Upgrade (max. alle 2h) aktualisiert; Engine zieht Vaults in den Pool.

## TWAP vs. Spot-Preis

- **Spot-Preis**: Momentaufnahme aus Pool-Reserven, reagiert sofort auf Swaps.
- **TWAP**: Durchschnitt ueber ein Zeitfenster; robuster gegen Manipulation.

**Wichtig:** MeBTC-Fees verwenden einen gecachten TWAP-Preis. Wenn der Preis zu alt
ist, faellt die Gebuehr automatisch auf **USDC-only** zurueck (kein Revert).

## Wie kommt MeBTC in den FeeVault?

- Bei `claimWithMebtc` oder `requestUpgrade*WithMebtc` wird der MeBTC-Anteil
  direkt von der Wallet in den **FeeVaultMeBTC** transferiert.
- Ohne MeBTC im FeeVault kann `LiquidityEngine.executeEpoch()` keine Liquidity adden.

## LiquidityEngine: Wann werden Vaults in den Pool transferiert?

`executeEpoch()` addet Liquidity **nur wenn**:

- `demandVault USDC >= MIN_USDC_LP` (Fuji aktuell: 10 USDC)
- `feeVaultMeBTC > 0`
- Epoch-Fenster abgelaufen ist

Die Engine transferiert immer die kleinere Seite, damit das Verhaeltnis passt.

## Frontend (Vue)

### Setup

```bash
cd frontend-vue
npm install
```

### Dev-Server

```bash
npm run dev
```

Open `http://localhost:5173`.

### UI Features (aktuell)

- **Header:** zeigt MinerNFT, Manager, Pair-Adresse und MeBTC-Preis (mit Quelle).
- **Approvals Dropdown**
- **Oracle/Engine Dropdown** (neben Approvals):
  - Execute Epoch
  - Anzeige: `Fee-Preis fresh: ja/nein`

## Tests

### Lokal (Foundry)

```bash
forge test
```

### Spezifische Suites

```bash
forge test --match-contract MiningManagerHalvingTest
forge test --match-contract LiquidityEngineTest
forge test --match-contract SecurityScenariosTest
```

### Invariant Suite

- Siehe `test/InvariantMiningManager.t.sol`
- Status/Probleme werden in `SECURITY_CHANGES.md` dokumentiert.

### Fuji E2E

- Checkliste und Status in `TEST_ABLAUF_FUJI.md`
- Aktuelle Deploy-Daten in `DEPLOY_ADDRESSES_FUJI.md`

## Scripts

### Deploy (Mainnet)

```bash
forge script script/DeployMainnet.s.sol:DeployMainnet --rpc-url <your_rpc_url> --broadcast
```

Env:
```
PRIVATE_KEY
PAY_TOKEN_ADDRESS
DEMAND_VAULT
FEE_VAULT_MEBTC
TWAP_ORACLE
JOE_FACTORY
MIN_USDC_LP
EPOCH_SECONDS
LP_BURN_BPS
TWAP_WINDOW_SECONDS
PROJECT_WALLET
ROYALTY_WALLET
ROYALTY_BPS
```

### SetPayToken

```bash
forge script script/SetPayToken.s.sol:SetPayToken --rpc-url <rpc> --broadcast
```

Env:
```
PRIVATE_KEY
MANAGER_ADDRESS
MINER_ADDRESS
PAY_TOKEN_ADDRESS
```

### ResyncMiner

```bash
forge script script/ResyncMiner.s.sol:ResyncMiner --rpc-url <rpc> --broadcast
```

Env:
```
PRIVATE_KEY
MANAGER_ADDRESS
TOKEN_ID
```

## Weitere Doku

- `TEST_PLAN.md` (Teststrategie und Prioritaeten)
- `TEST_ABLAUF_FUJI.md` (Schritt-fuer-Schritt Fuji Tests)
- `SECURITY_CHANGES.md` (Findings & geplante Aenderungen)
