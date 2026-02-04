export type ErrorHelp = {
  title: string
  message: string
  steps: string[]
  raw: string
}

function baseTitle(context?: string) {
  return context ? `Fehler bei ${context}` : 'Fehler'
}

function help(message: string, steps: string[], raw: string, context?: string): ErrorHelp {
  return {
    title: baseTitle(context),
    message,
    steps,
    raw
  }
}

export function explainError(raw: string, context?: string): ErrorHelp {
  const msg = (raw || '').trim()
  const lower = msg.toLowerCase()

  if (!msg) {
    return help(
      'Es ist etwas schiefgelaufen.',
      ['Bitte erneut versuchen.', 'Seite neu laden und Wallet neu verbinden.'],
      raw,
      context
    )
  }

  if (lower.includes('user rejected') || lower.includes('rejected') || lower.includes('abgebrochen') || lower.includes('denied')) {
    return help(
      'Du hast die Transaktion abgebrochen.',
      ['Wenn du fortfahren willst, in der Wallet bestaetigen.', 'Wallet-Fenster oeffnen und erneut versuchen.'],
      msg,
      context
    )
  }

  if (lower.includes('wallet nicht verbunden') || lower.includes('not connected') || lower.includes('keine adresse')) {
    return help(
      'Deine Wallet ist nicht verbunden.',
      ['Wallet verbinden.', 'Danach die Aktion erneut starten.'],
      msg,
      context
    )
  }

  if (lower.includes('falsches netzwerk') || lower.includes('wrong network') || lower.includes('chain')) {
    return help(
      'Du bist im falschen Netzwerk.',
      ['In der Wallet auf Avalanche Fuji wechseln.', 'Seite neu laden und erneut versuchen.'],
      msg,
      context
    )
  }

  if (lower.includes('allowance') || lower.includes('approve') || lower.includes('approval')) {
    return help(
      'Es fehlt eine Freigabe (Allowance).',
      ['Zuerst die Freigabe/Approve bestaetigen.', 'Danach die Aktion erneut starten.'],
      msg,
      context
    )
  }

  if (lower.includes('insufficient') || lower.includes('balance') || lower.includes('saldo') || lower.includes('funds')) {
    return help(
      'Dein Guthaben reicht nicht aus.',
      ['Betrag verringern oder Guthaben aufladen.', 'Danach erneut versuchen.'],
      msg,
      context
    )
  }

  if (lower.includes('nonce') || lower.includes('replacement fee too low') || lower.includes('underpriced') || lower.includes('already known')) {
    return help(
      'Es gibt eine offene oder haengende Transaktion.',
      ['Wallet oeffnen und offene Transaktionen pruefen.', 'Falls noetig abbrechen/ersetzen, dann erneut versuchen.'],
      msg,
      context
    )
  }

  if (lower.includes('timeout') || lower.includes('failed to fetch') || lower.includes('network') || lower.includes('rpc')) {
    return help(
      'Netzwerk/Provider ist gerade nicht erreichbar.',
      ['Internetverbindung pruefen.', 'Seite neu laden und erneut versuchen.'],
      msg,
      context
    )
  }

  if (lower.includes('format') || lower.includes('ungueltig') || lower.includes('betrag fehlt')) {
    return help(
      'Die Eingabe ist ungueltig.',
      ['Bitte einen gueltigen Betrag eingeben.', 'Beispiele: 10000 oder 10000.5'],
      msg,
      context
    )
  }

  if (lower.includes('previews fehlen') || lower.includes('preview')) {
    return help(
      'Es fehlen Daten fuer deine Miner.',
      ['Kurz warten und erneut laden.', 'Dann den Claim erneut versuchen.'],
      msg,
      context
    )
  }

  if (lower.includes('execution reverted') || lower.includes('revert')) {
    return help(
      'Der Smart Contract hat die Aktion abgelehnt.',
      ['Eingaben pruefen (Menge, TokenId, Allowance).', 'Dann erneut versuchen.'],
      msg,
      context
    )
  }

  return help(
    'Die Aktion konnte nicht abgeschlossen werden.',
    ['Bitte erneut versuchen.', 'Wenn es wieder passiert: Seite neu laden.'],
    msg,
    context
  )
}
