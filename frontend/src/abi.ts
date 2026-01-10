// src/abi.ts
export const erc20Abi = [
  { type: "function", name: "decimals", stateMutability: "view", inputs: [], outputs: [{ type: "uint8" }] },
  { type: "function", name: "symbol", stateMutability: "view", inputs: [], outputs: [{ type: "string" }] },
  { type: "function", name: "balanceOf", stateMutability: "view", inputs: [{ name: "a", type: "address" }], outputs: [{ type: "uint256" }] },
  { type: "function", name: "allowance", stateMutability: "view", inputs: [{ type: "address" }, { type: "address" }], outputs: [{ type: "uint256" }] },
  { type: "function", name: "approve", stateMutability: "nonpayable", inputs: [{ type: "address" }, { type: "uint256" }], outputs: [{ type: "bool" }] },
] as const;

export const minerNftAbi = [
  { type: "function", name: "balanceOf", stateMutability: "view", inputs: [{ type: "address" }], outputs: [{ type: "uint256" }] },
  { type: "function", name: "ownerOf", stateMutability: "view", inputs: [{ type: "uint256" }], outputs: [{ type: "address" }] },
  { type: "function", name: "tokenURI", stateMutability: "view", inputs: [{ type: "uint256" }], outputs: [{ type: "string" }] },

  {
    type: "function",
    name: "getModel",
    stateMutability: "view",
    inputs: [{ type: "uint16" }],
    outputs: [
      { type: "uint32" }, // baseHashrate
      { type: "uint32" }, // basePowerWatt
      { type: "uint32" }, // maxSupply
      { type: "uint32" }, // minted
      { type: "uint256" }, // priceUSDC
      { type: "bool" }, // finalized
      { type: "uint256[4]" }, // powerStepCost
      { type: "uint256[4]" }, // hashStepCost
      { type: "string" }, // uri
    ],
  },

  { type: "function", name: "buyFromModel", stateMutability: "nonpayable", inputs: [{ type: "uint16" }, { type: "uint256" }], outputs: [{ type: "uint256" }] },

  { type: "function", name: "requestUpgradeHash", stateMutability: "nonpayable", inputs: [{ type: "uint256" }], outputs: [{ type: "uint16" }] },
  { type: "function", name: "requestUpgradePower", stateMutability: "nonpayable", inputs: [{ type: "uint256" }], outputs: [{ type: "uint16" }] },

  {
    type: "function",
    name: "getMinerState",
    stateMutability: "view",
    inputs: [{ type: "uint256" }],
    outputs: [
      {
        type: "tuple",
        components: [
          { name: "modelId", type: "uint16" },
          { name: "powerUpgradeBps", type: "uint16" },
          { name: "hashUpgradeBps", type: "uint16" },
          { name: "pendingPowerUpgradeBps", type: "uint16" },
          { name: "pendingHashUpgradeBps", type: "uint16" },
          { name: "createdAt", type: "uint40" },
          { name: "lastClaimAt", type: "uint40" },
        ],
      },
    ],
  },

  // event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)
  {
    type: "event",
    name: "Transfer",
    inputs: [
      { indexed: true, name: "from", type: "address" },
      { indexed: true, name: "to", type: "address" },
      { indexed: true, name: "tokenId", type: "uint256" },
    ],
    anonymous: false,
  },
] as const;

export const miningManagerAbi = [
  { type: "function", name: "claim", stateMutability: "nonpayable", inputs: [{ type: "uint256[]" }], outputs: [] },
  // preview(id, owner) returns (reward, feeUSDC)
  { type: "function", name: "preview", stateMutability: "view", inputs: [{ type: "uint256" }, { type: "address" }], outputs: [{ type: "uint256" }, { type: "uint256" }] },
] as const;
