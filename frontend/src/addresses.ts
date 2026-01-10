// src/addresses.ts
export const CHAIN = {
  id: 43113,
  name: "Avalanche Fuji",
  rpcUrls: ["https://api.avax-test.network/ext/bc/C/rpc"],
  blockExplorer: "https://testnet.snowtrace.io",
} as const;

export const ADDRESSES = {
  minerNft: "0x6127cDdF02D5E4d8F2eBa3d0e140C39Dd10A091e",
  miningManager: "0xB47bd7DAB142c895FDf3a8f7bB1BC55A6D743D8b",
  mebtc: "0xa3296c78c91D840d5DA62d350e2d7cd709C3A794",
  usdc: "0x5425890298aed601595a70AB815c96711a31Bc65",
} as const;

export const TOKENS = {
  mebtc: { symbol: "MeBTC", decimals: 18 },
  usdc: { symbol: "USDC", decimals: 6 },
} as const;

// optional: hier kannst du später deinen ipfs gateway link für das token icon eintragen
export const ME_BTC_ICON_URL = "https://gateway.pinata.cloud/ipfs/bafybeicbbbq34icbttul7wjnybktvkgqp4fhlzi2iebx4amq4cdlwrnkti/MeBTC.png"; // z.B. "https://gateway.pinata.cloud/ipfs/bafybeicbbbq34icbttul7wjnybktvkgqp4fhlzi2iebx4amq4cdlwrnkti/MeBTC.png"
