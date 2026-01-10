// src/web3.ts
import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { http } from "wagmi";
import { CHAIN } from "./addresses";

export const wagmiConfig = getDefaultConfig({
  appName: "MeBTC",
  projectId: "mebtc-walletconnect", // dummy string ok, aber für echtes WalletConnect brauchst du später eine echte ProjectId
  chains: [
    {
      id: CHAIN.id,
      name: CHAIN.name,
      nativeCurrency: { name: "AVAX", symbol: "AVAX", decimals: 18 },
      rpcUrls: { default: { http: CHAIN.rpcUrls as unknown as string[] } },
      blockExplorers: { default: { name: "Snowtrace", url: CHAIN.blockExplorer } },
    },
  ],
  transports: {
    [CHAIN.id]: http(CHAIN.rpcUrls[0]),
  },
});
