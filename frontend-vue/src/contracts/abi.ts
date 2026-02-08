export const erc20Abi = [
  {
    type: 'function',
    name: 'balanceOf',
    stateMutability: 'view',
    inputs: [{ name: 'account', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }]
  },
  {
    type: 'function',
    name: 'allowance',
    stateMutability: 'view',
    inputs: [
      { name: 'owner', type: 'address' },
      { name: 'spender', type: 'address' }
    ],
    outputs: [{ name: '', type: 'uint256' }]
  },
  {
    type: 'function',
    name: 'approve',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'spender', type: 'address' },
      { name: 'amount', type: 'uint256' }
    ],
    outputs: [{ name: '', type: 'bool' }]
  }
] as const

export const minerNftAbi = [
  {
    type: 'function',
    name: 'payToken',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ name: '', type: 'address' }]
  },
  {
    type: 'function',
    name: 'balanceOf',
    stateMutability: 'view',
    inputs: [{ name: 'owner', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }]
  },
  {
    type: 'function',
    name: 'ownerOf',
    stateMutability: 'view',
    inputs: [{ name: 'tokenId', type: 'uint256' }],
    outputs: [{ name: '', type: 'address' }]
  },
  {
    type: 'event',
    name: 'Transfer',
    inputs: [
      { indexed: true, name: 'from', type: 'address' },
      { indexed: true, name: 'to', type: 'address' },
      { indexed: true, name: 'tokenId', type: 'uint256' }
    ],
    anonymous: false
  }
] as const

export const miningManagerAbi = [
  {
    type: 'function',
    name: 'payToken',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ name: '', type: 'address' }]
  },
  {
    type: 'function',
    name: 'claim',
    stateMutability: 'nonpayable',
    inputs: [{ name: 'tokenIds', type: 'uint256[]' }],
    outputs: []
  },
  {
    type: 'function',
    name: 'claimWithMebtc',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'tokenIds', type: 'uint256[]' },
      { name: 'mebtcShareBps', type: 'uint16' }
    ],
    outputs: []
  },
  {
    type: 'function',
    name: 'preview',
    stateMutability: 'view',
    inputs: [
      { name: 'tokenId', type: 'uint256' },
      { name: 'owner', type: 'address' }
    ],
    outputs: [
      { name: 'reward', type: 'uint256' },
      { name: 'feeUSDC', type: 'uint256' }
    ]
  },
  {
    type: 'function',
    name: 'resyncMiner',
    stateMutability: 'nonpayable',
    inputs: [{ name: 'tokenId', type: 'uint256' }],
    outputs: []
  }
] as const

export const stakeVaultAbi = [
  {
    type: 'function',
    name: 'stake',
    stateMutability: 'nonpayable',
    inputs: [{ name: 'amount', type: 'uint256' }],
    outputs: []
  },
  {
    type: 'function',
    name: 'unstake',
    stateMutability: 'nonpayable',
    inputs: [{ name: 'amount', type: 'uint256' }],
    outputs: []
  },
  {
    type: 'function',
    name: 'getStakeInfo',
    stateMutability: 'view',
    inputs: [{ name: 'user', type: 'address' }],
    outputs: [
      { name: 'balance', type: 'uint256' },
      { name: 'tier', type: 'uint8' },
      { name: 'unlockAt', type: 'uint64' },
      { name: 'hashBonusBps', type: 'uint16' },
      { name: 'powerBonusBps', type: 'uint16' }
    ]
  }
] as const
