import { ref } from 'vue'
import { Contract, getAddress, id as keccakId, zeroPadValue } from 'ethers'
import { useWallet } from './useWallet'
import { ADDRESSES } from '../contracts/addresses'

const MINER_ABI = [
  'event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)',
  'function ownerOf(uint256 tokenId) view returns (address)'
]

// ✅ Startblock nach deinem Wunsch
const START_BLOCK = 49_900_000

// Start-Chunk-Größe (wird bei Limit-Errors automatisch kleiner)
const INITIAL_SPAN = 2_000
const MIN_SPAN = 1_000

function isTooManyResultsError(e: any) {
  const msg = String(e?.message ?? e ?? '').toLowerCase()
  return (
    msg.includes('more than') ||
    msg.includes('too many') ||
    msg.includes('query returned more than') ||
    msg.includes('limit') ||
    msg.includes('2048') ||
    msg.includes('response size') ||
    msg.includes('result is too large')
  )
}

export function useOwnedMinerTokenIds() {
  const { address, readProvider, isConnected, onChain } = useWallet()

  const owned = ref<bigint[]>([])
  const busy = ref(false)
  const msg = ref('')
  const error = ref('')

  async function getLogsPaged(params: {
    fromBlock: number
    toBlock: number
    topics: (string | null)[]
  }) {
    const p = readProvider.value
    let from = params.fromBlock
    const to = params.toBlock
    let span = INITIAL_SPAN

    const all: any[] = []

    while (from <= to) {
      const end = Math.min(to, from + span)

      try {
        const logs = await p.getLogs({
          address: ADDRESSES.minerNft,
          fromBlock: from,
          toBlock: end,
          topics: params.topics
        })

        all.push(...logs)

        // Fortschritt
        msg.value = `scan logs: ${from} → ${end} (span ${span}) | logs so far: ${all.length}`

        // wenn erfolgreich: weiter
        from = end + 1

        // optional: wenn wir gerade sehr klein waren, können wir wieder leicht hochgehen
        if (span < INITIAL_SPAN) span = Math.min(INITIAL_SPAN, span * 2)
      } catch (e: any) {
        if (isTooManyResultsError(e) && span > MIN_SPAN) {
          // Chunk zu groß -> halbieren und retry selben from
          span = Math.max(MIN_SPAN, Math.floor(span / 2))
          msg.value = `rpc limit hit, reducing span to ${span} and retrying…`
          continue
        }
        throw e
      }
    }

    return all
  }

  async function rescan() {
    error.value = ''
    msg.value = ''
    owned.value = []

    if (!isConnected.value) {
      msg.value = 'wallet nicht verbunden'
      return
    }
    if (!onChain.value) {
      msg.value = 'falsches netzwerk'
      return
    }
    if (!address.value) {
      msg.value = 'keine adresse'
      return
    }

    busy.value = true
    try {
      const p = readProvider.value
      const miner = new Contract(ADDRESSES.minerNft, MINER_ABI, p)

      const user = getAddress(address.value)

      // Transfer(address,address,uint256)
      const transferTopic = keccakId('Transfer(address,address,uint256)')
      const topicUser = zeroPadValue(user, 32).toLowerCase()

      const latest = await p.getBlockNumber()
      const fromBlock = Math.min(START_BLOCK, latest)

      msg.value = `start scan from block ${fromBlock} to ${latest}…`

      // ✅ logs where to = user (received/minted)
      const logsTo = await getLogsPaged({
        fromBlock,
        toBlock: latest,
        topics: [transferTopic, null, topicUser]
      })

      // ✅ logs where from = user (sent away)
      const logsFrom = await getLogsPaged({
        fromBlock,
        toBlock: latest,
        topics: [transferTopic, topicUser, null]
      })

      // Candidate set
      const candidate = new Set<string>()
      for (const l of logsTo) {
        const tokenId = BigInt(l.topics[3])
        candidate.add(tokenId.toString())
      }
      for (const l of logsFrom) {
        const tokenId = BigInt(l.topics[3])
        candidate.add(tokenId.toString())
      }

      msg.value = `verifying ownerOf() for ${candidate.size} tokenIds…`

      // Verify ownership now
      const ids: bigint[] = []
      const arr = Array.from(candidate).map(x => BigInt(x)).sort((x, y) => (x < y ? -1 : 1))

      for (const tokenId of arr) {
        try {
          const currentOwner = getAddress(await miner.ownerOf(tokenId))
          if (currentOwner === user) ids.push(tokenId)
        } catch {
          // ignore
        }
      }

      owned.value = ids
      msg.value = `found ${ids.length} miners`
    } catch (e: any) {
      error.value = e?.shortMessage ?? e?.message ?? String(e)
    } finally {
      busy.value = false
    }
  }

  return { owned, busy, msg, error, rescan }
}


