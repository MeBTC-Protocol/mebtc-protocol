export function toHttpUrl(uri?: string): string {
  if (!uri) return ''

  // already http(s)
  if (uri.startsWith('http://') || uri.startsWith('https://')) return uri

  // ipfs://<cid>/path or ipfs://ipfs/<cid>/path
  if (uri.startsWith('ipfs://')) {
    const cleaned = uri
      .replace('ipfs://ipfs/', 'ipfs://')
      .replace('ipfs://', '')

    // use a public gateway (can switch later to Pinata if you want)
    return `https://ipfs.io/ipfs/${cleaned}`
  }

  return uri
}
