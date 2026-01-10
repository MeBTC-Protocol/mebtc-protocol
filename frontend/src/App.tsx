// src/App.tsx
import { useEffect, useMemo, useRef, useState } from "react";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import {
  useAccount,
  useChainId,
  usePublicClient,
  useReadContract,
  useReadContracts,
  useWriteContract,
} from "wagmi";
import { formatUnits, parseAbiItem, maxUint256, type Address } from "viem";

import { ADDRESSES, CHAIN, TOKENS, ME_BTC_ICON_URL } from "./addresses";
import { erc20Abi, minerNftAbi, miningManagerAbi } from "./abi";

function shortAddr(a: string) {
  return a.slice(0, 6) + "..." + a.slice(-4);
}

function formatUnitsSafe(v: bigint | undefined, decimals: number) {
  if (v === undefined) return "-";
  return formatUnits(v, decimals);
}


function toBigIntSafe(v: unknown): bigint {
  try {
    return BigInt(v as any);
  } catch {
    return 0n;
  }
}

export default function App() {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const onFuji = chainId === CHAIN.id;

  const publicClient = usePublicClient();
  const { writeContractAsync } = useWriteContract();

  const [status, setStatus] = useState<string>("");
  const [ownedTokenIds, setOwnedTokenIds] = useState<bigint[]>([]);
  const [scanBusy, setScanBusy] = useState(false);
  const [scanMsg, setScanMsg] = useState("");

  // selection for claim
  const [selected, setSelected] = useState<Record<string, boolean>>({});

  // balances
  const mebtcBal = useReadContract({
    address: ADDRESSES.mebtc,
    abi: erc20Abi,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
    query: { enabled: !!address && onFuji },
  });

  const usdcBal = useReadContract({
    address: ADDRESSES.usdc,
    abi: erc20Abi,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
    query: { enabled: !!address && onFuji },
  });

  // allowances (USDC)
  const allowanceForMiner = useReadContract({
    address: ADDRESSES.usdc,
    abi: erc20Abi,
    functionName: "allowance",
    args: address ? [address, ADDRESSES.minerNft] : undefined,
    query: { enabled: !!address && onFuji },
  });

  const allowanceForManager = useReadContract({
    address: ADDRESSES.usdc,
    abi: erc20Abi,
    functionName: "allowance",
    args: address ? [address, ADDRESSES.miningManager] : undefined,
    query: { enabled: !!address && onFuji },
  });

  // miner count exists (not enough to get tokenIds, but still useful)
  const minerCount = useReadContract({
    address: ADDRESSES.minerNft,
    abi: minerNftAbi,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
    query: { enabled: !!address && onFuji },
  });

  const minerCountNum = Number(minerCount.data ?? 0n);

  useEffect(() => {
    if (!isConnected) setStatus("wallet nicht verbunden");
    else if (!onFuji) setStatus("falsches netzwerk – bitte auf avalanche fuji wechseln");
    else setStatus("");
  }, [isConnected, onFuji]);

  // -----------------------------
  // tokenId discovery via Transfer logs
  // -----------------------------
  const lastScanKeyRef = useRef<string>("");

  useEffect(() => {
    const key = `${address ?? ""}:${onFuji ? "fuji" : "no"}`;
    if (!address || !onFuji) {
      setOwnedTokenIds([]);
      setSelected({});
      lastScanKeyRef.current = "";
      return;
    }
    if (lastScanKeyRef.current === key) return;
    lastScanKeyRef.current = key;

    void scanOwnedTokenIds(address);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [address, onFuji]);

  async function scanOwnedTokenIds(user: Address) {
    if (!publicClient) return;
      setScanBusy(true);
      setScanMsg("scanne transfer events… (kann beim ersten mal etwas dauern)");

    try {
    const latest = await publicClient.getBlockNumber();

    // optional: wenn du später den deploy-block kennst, hier statt 0n eintragen
    const START_BLOCK = 49_943_120n;

    const chunk = 2000n; // kleiner chunk = weniger rpc stress
    const transferEvent = parseAbiItem(
      "event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)"
    );

    const touched = new Set<string>();

    let fromBlock = START_BLOCK;
    let iter = 0;

    while (fromBlock <= latest) {
      const toBlock = fromBlock + chunk > latest ? latest : fromBlock + chunk;
      iter++;

      setScanMsg(`scanne blocks ${fromBlock} – ${toBlock} (chunk ${iter})…`);

      // wichtig: KEINE args filter hier, nur event + range
      const logs = await publicClient.getLogs({
        address: ADDRESSES.minerNft as Address,
        event: transferEvent,
        fromBlock,
        toBlock,
      });

      for (const l of logs) {
        const a = l.args as any;
        const from = (a.from as string | undefined)?.toLowerCase();
        const to = (a.to as string | undefined)?.toLowerCase();
        const tid = a.tokenId as bigint | undefined;

        if (!tid) continue;

        if (from === user.toLowerCase() || to === user.toLowerCase()) {
          touched.add(tid.toString());
        }
      }

      fromBlock = toBlock + 1n;
    }

    if (touched.size === 0) {
      setOwnedTokenIds([]);
      setSelected({});
      setScanMsg("keine miner gefunden");
      return;
    }

    setScanMsg(`prüfe ownership von ${touched.size} tokenIds…`);

    const ids = Array.from(touched)
      .map((s) => BigInt(s))
      .sort((a, b) => (a < b ? -1 : 1));

    const owned: bigint[] = [];

    const batchSize = 75;
    for (let i = 0; i < ids.length; i += batchSize) {
      const slice = ids.slice(i, i + batchSize);

      const reads = slice.map((id) => ({
        address: ADDRESSES.minerNft as Address,
        abi: minerNftAbi,
        functionName: "ownerOf" as const,
        args: [id] as const,
      }));

      for (const id of slice) {
  try {
    const owner = await publicClient.readContract({
      address: ADDRESSES.minerNft as Address,
      abi: minerNftAbi,
      functionName: "ownerOf",
      args: [id],
    });

    if ((owner as string).toLowerCase() === user.toLowerCase()) {
      owned.push(id);
    }
  } catch {
    // ignore (token might not exist anymore in some edge cases)
  }
}

    }

    setOwnedTokenIds(owned);

    const sel: Record<string, boolean> = {};
    for (const id of owned) sel[id.toString()] = true;
    setSelected(sel);

    setScanMsg(`fertig. gefunden: ${owned.length} miner`);
  } catch (e: any) {
    console.error(e);
    setScanMsg(`scan fehler: ${e?.shortMessage ?? e?.message ?? String(e)}`);
  } finally {
    setScanBusy(false);
  }
}


  // previews for each owned tokenId
  const previewContracts = useMemo(() => {
    if (!address || !onFuji) return [];
    return ownedTokenIds.map((id) => ({
      address: ADDRESSES.miningManager as Address,
      abi: miningManagerAbi,
      functionName: "preview" as const,
      args: [id, address] as const,
    }));
  }, [address, onFuji, ownedTokenIds]);

  const previews = useReadContracts({
    contracts: previewContracts,
    query: { enabled: previewContracts.length > 0 },
  });

  const previewMap = useMemo(() => {
    const m = new Map<string, { reward: bigint; fee: bigint }>();
    const data = previews.data ?? [];
    for (let i = 0; i < data.length; i++) {
      const id = ownedTokenIds[i];
      const r = data[i];
      if (!id) continue;
      if (r?.status === "success") {
        const out = r.result as readonly [bigint, bigint];
        m.set(id.toString(), { reward: out[0], fee: out[1] });
      }
    }
    return m;
  }, [previews.data, ownedTokenIds]);

  const selectedIds = useMemo(() => {
    return ownedTokenIds.filter((id) => selected[id.toString()]);
  }, [ownedTokenIds, selected]);

  const totalFeeSelected = useMemo(() => {
    let s = 0n;
    for (const id of selectedIds) {
      const p = previewMap.get(id.toString());
      if (p) s += p.fee;
    }
    return s;
  }, [selectedIds, previewMap]);

  const totalRewardSelected = useMemo(() => {
    let s = 0n;
    for (const id of selectedIds) {
      const p = previewMap.get(id.toString());
      if (p) s += p.reward;
    }
    return s;
  }, [selectedIds, previewMap]);

  async function approveUSDC(spender: Address) {
    if (!address) return;
    if (!onFuji) return alert("bitte auf fuji wechseln");
    try {
      await writeContractAsync({
        address: ADDRESSES.usdc as Address,
        abi: erc20Abi,
        functionName: "approve",
        args: [spender, maxUint256],
      });
      alert("approve gesendet (max). nach bestätigung aktualisiert sich allowance automatisch.");
    } catch (e: any) {
      alert(e?.shortMessage ?? e?.message ?? String(e));
    }
  }

  async function claimSelected() {
    if (!address) return;
    if (!onFuji) return alert("bitte auf fuji wechseln");
    if (selectedIds.length === 0) return alert("keine miner ausgewählt");

    // check allowance for fee
    const allow = allowanceForManager.data ?? 0n;
    if (allow < totalFeeSelected) {
      return alert("USDC allowance für manager ist zu niedrig. zuerst approve für manager machen.");
    }

    try {
      await writeContractAsync({
        address: ADDRESSES.miningManager as Address,
        abi: miningManagerAbi,
        functionName: "claim",
        args: [selectedIds],
      });
      alert("claim tx gesendet. nach bestätigung kannst du nochmal scannen/refreshen.");
    } catch (e: any) {
      alert(e?.shortMessage ?? e?.message ?? String(e));
    }
  }

  return (
    <div style={{ maxWidth: 1150, margin: "0 auto", padding: 16, fontFamily: "ui-sans-serif, system-ui" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 12 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          {ME_BTC_ICON_URL ? (
            <img src={ME_BTC_ICON_URL} alt="MeBTC" style={{ width: 34, height: 34, borderRadius: 10 }} />
          ) : (
            <div style={{ width: 34, height: 34, borderRadius: 10, border: "1px solid #999" }} />
          )}
          <div>
            <div style={{ fontSize: 24 }}>MeBTC Advanced Dashboard (Fuji)</div>
            <div style={{ opacity: 0.7, marginTop: 4 }}>
              MinerNFT: {shortAddr(ADDRESSES.minerNft)} | Manager: {shortAddr(ADDRESSES.miningManager)}
            </div>
          </div>
        </div>

        <ConnectButton chainStatus="icon" showBalance={false} />
      </div>

      {status && (
        <div style={{ marginTop: 16, padding: 12, border: "1px solid #999", borderRadius: 10 }}>
          {status}
        </div>
      )}

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginTop: 16 }}>
        <Card title="wallet">
          <div>connected: {String(isConnected)}</div>
          <div>address: {address ? address : "-"}</div>
          <div>chainId: {chainId}</div>
        </Card>

        <Card title="balances">
          <Line label={TOKENS.mebtc.symbol} value={mebtcBal.isLoading ? "loading..." : formatUnitsSafe(mebtcBal.data, TOKENS.mebtc.decimals)} />
          <Line label={TOKENS.usdc.symbol} value={usdcBal.isLoading ? "loading..." : formatUnitsSafe(usdcBal.data, TOKENS.usdc.decimals)} />
          <div style={{ marginTop: 8, opacity: 0.7 }}>
            usdc allowance:
          </div>
          <Line
            label="für miner (buy/upgrade)"
            value={allowanceForMiner.isLoading ? "loading..." : formatUnitsSafe(0.07, TOKENS.usdc.decimals)}
          />
          <Line
            label="für manager (claim fee)"
            value={allowanceForManager.isLoading ? "loading..." : formatUnitsSafe(allowanceForManager.data, TOKENS.usdc.decimals)}
          />
        </Card>

        <Card title="approve usdc (schritt 2)">
          <div style={{ opacity: 0.75 }}>
            buy/upgrade: spender ist MinerNFT, claim fee: spender ist MiningManager
          </div>

          <div style={{ display: "flex", gap: 8, flexWrap: "wrap", marginTop: 10 }}>
            <button
              onClick={() => approveUSDC(ADDRESSES.minerNft as Address)}
              disabled={!isConnected || !onFuji}
              style={btn()}
            >
              approve USDC für MinerNFT (max)
            </button>

            <button
              onClick={() => approveUSDC(ADDRESSES.miningManager as Address)}
              disabled={!isConnected || !onFuji}
              style={btn()}
            >
              approve USDC für Manager (max)
            </button>
          </div>
        </Card>

        <Card title="miner in besitz (via events)">
          <div>balanceOf: {minerCount.isLoading ? "loading..." : String(minerCountNum)}</div>

          <div style={{ marginTop: 8, display: "flex", gap: 8, flexWrap: "wrap" }}>
            <button
              onClick={() => address && scanOwnedTokenIds(address as Address)}
              disabled={!isConnected || !onFuji || scanBusy}
              style={btn()}
            >
              neu scannen
            </button>
            <div style={{ opacity: 0.75, alignSelf: "center" }}>
              {scanMsg}
            </div>
          </div>

          <div style={{ marginTop: 10, opacity: 0.75 }}>
            tokenIds:
          </div>
          <div style={{ marginTop: 6, display: "flex", flexWrap: "wrap", gap: 6 }}>
            {ownedTokenIds.length === 0 ? <span>-</span> : null}
            {ownedTokenIds.map((id) => (
              <span key={id.toString()} style={pill()}>
                #{id.toString()}
              </span>
            ))}
          </div>
        </Card>
      </div>

      <div style={{ marginTop: 12 }}>
        <Card title="claim ui">
          <div style={{ opacity: 0.75 }}>
            preview liefert reward (MeBTC) und fee (USDC). fee wird an den pool gezahlt, spender ist MiningManager.
          </div>

          <div style={{ marginTop: 10, display: "flex", gap: 12, flexWrap: "wrap" }}>
            <div style={{ border: "1px solid #999", borderRadius: 12, padding: 10 }}>
              <div style={{ opacity: 0.75 }}>ausgewählt</div>
              <div>{selectedIds.length} miner</div>
            </div>

            <div style={{ border: "1px solid #999", borderRadius: 12, padding: 10 }}>
              <div style={{ opacity: 0.75 }}>gesamt reward</div>
              <div>{formatUnits(totalRewardSelected, TOKENS.mebtc.decimals)} {TOKENS.mebtc.symbol}</div>
            </div>

            <div style={{ border: "1px solid #999", borderRadius: 12, padding: 10 }}>
              <div style={{ opacity: 0.75 }}>gesamt fee</div>
              <div>{formatUnits(totalFeeSelected, TOKENS.usdc.decimals)} {TOKENS.usdc.symbol}</div>
            </div>

            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              <button onClick={claimSelected} disabled={!isConnected || !onFuji || selectedIds.length === 0} style={btn()}>
                claim selected
              </button>
              <div style={{ opacity: 0.75 }}>
                allowance manager: {formatUnitsSafe(allowanceForManager.data, TOKENS.usdc.decimals)} USDC
              </div>
            </div>
          </div>

          <div style={{ marginTop: 12 }}>
            {ownedTokenIds.length === 0 ? (
              <div style={{ opacity: 0.75 }}>keine miner vorhanden oder scan noch nicht fertig.</div>
            ) : (
              <table style={{ width: "100%", borderCollapse: "collapse", marginTop: 8 }}>
                <thead>
                  <tr>
                    <th style={th()}>select</th>
                    <th style={th()}>tokenId</th>
                    <th style={th()}>reward</th>
                    <th style={th()}>fee (usdc)</th>
                  </tr>
                </thead>
                <tbody>
                  {ownedTokenIds.map((id) => {
                    const p = previewMap.get(id.toString());
                    const reward = p ? formatUnits(p.reward, TOKENS.mebtc.decimals) : (previews.isLoading ? "loading..." : "-");
                    const fee = p ? formatUnits(p.fee, TOKENS.usdc.decimals) : (previews.isLoading ? "loading..." : "-");
                    const checked = !!selected[id.toString()];

                    return (
                      <tr key={id.toString()}>
                        <td style={td()}>
                          <input
                            type="checkbox"
                            checked={checked}
                            onChange={(e) => setSelected((s) => ({ ...s, [id.toString()]: e.target.checked }))}
                          />
                        </td>
                        <td style={td()}>#{id.toString()}</td>
                        <td style={td()}>{reward}</td>
                        <td style={td()}>{fee}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )}
          </div>
        </Card>
      </div>

      <div style={{ marginTop: 12, opacity: 0.7 }}>
        nächster schritt (danach): model cards (id 3/4) + buy miner (inkl. approve check)
      </div>
    </div>
  );
}

function Card(props: { title: string; children: any }) {
  return (
    <div style={{ border: "1px solid #999", borderRadius: 14, padding: 12 }}>
      <div style={{ fontSize: 16, marginBottom: 10 }}>{props.title}</div>
      <div style={{ display: "grid", gap: 6 }}>{props.children}</div>
    </div>
  );
}

function Line(props: { label: string; value: string }) {
  return (
    <div style={{ display: "flex", justifyContent: "space-between", gap: 12 }}>
      <div>{props.label}</div>
      <div style={{ fontVariantNumeric: "tabular-nums" }}>{props.value}</div>
    </div>
  );
}

function btn(): React.CSSProperties {
  return {
    padding: "10px 12px",
    borderRadius: 12,
    border: "1px solid #999",
    background: "transparent",
    cursor: "pointer",
  };
}

function pill(): React.CSSProperties {
  return {
    padding: "4px 8px",
    border: "1px solid #999",
    borderRadius: 999,
  };
}

function th(): React.CSSProperties {
  return {
    textAlign: "left",
    borderBottom: "1px solid #999",
    padding: "8px 6px",
    opacity: 0.8,
  };
}

function td(): React.CSSProperties {
  return {
    borderBottom: "1px solid #ddd",
    padding: "8px 6px",
    verticalAlign: "middle",
    fontVariantNumeric: "tabular-nums",
  };
}



