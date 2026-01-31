# Mainnet-Fork E2E Ablauf (Vorlage)

Ziel: reproduzierbare End-to-End Tests mit echtem Mainnet-State auf Fork.

## Voraussetzungen
- RPC-URL fuer Mainnet-Fork (Avalanche C-Chain Mainnet, z. B. oeffentlicher RPC oder eigener Node)
- feste Blocknummer (reproduzierbar)

## Start (Anvil Fork)
```
anvil --fork-url <RPC_URL> --fork-block-number <BLOCK>
```

## Deploy (Beispiel)
```
forge script script/DeployMainnet.s.sol:DeployMainnet --rpc-url http://127.0.0.1:8545 --broadcast
```

## Beispiel-Variablen (Platzhalter)
```
RPC_URL=https://api.avax.network/ext/bc/C/rpc
BLOCK=<fixe_blocknummer>
```

## Fuji RPC (Referenz)
- https://api.avax-test.network/ext/bc/C/rpc

## E2E Schritte
1) UI mit Fork verbinden (Custom RPC).
2) Wallet connect und Chain-ID pruefen.
3) Buy Flow: Approve -> Buy -> Receipt.
4) Claim Flow: vor Slot blockiert, nach Slot claimen.
5) Upgrade Flow: Upgrade -> Pending -> Claim -> Active.
6) claimWithMebtc: TWAP ready, price > 0.
7) Oracle-Stale: wenn TWAP nicht ready, Tx muss failen.
8) Batch-Claim: viele Miner, Gas/Throughput notieren.

## Dokumentation
- Blocknummer, RPC-URL, Contract-Adressen
- Tx-Hashes, beobachtete Balances, Vault-Delta
- Besonderheiten/Fehler
