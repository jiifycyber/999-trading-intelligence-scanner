(() => {
  // This bridge observes WebSocket messages already delivered to the user's page.
  // It does not read cookies, SID values, passwords, or authorization headers.

  const NativeWebSocket = window.WebSocket;

  function emitQuote(symbol, timestamp, price) {
    window.postMessage({
      __999Quote: true,
      symbol,
      timestamp,
      price
    }, '*');
  }

  function inspectValue(value) {
    // Firefox sometimes exposes text quote rows directly.
    if (typeof value === 'string') {
      const trimmed = value.trim();
      const first = trimmed.indexOf('[');
      if (first < 0) return;
      try {
        const parsed = JSON.parse(trimmed.slice(first));
        inspectParsed(parsed);
      } catch (_) {}
    }
  }

  function inspectParsed(parsed) {
    // Direct form: ["EURUSD_otc", timestamp, price]
    if (Array.isArray(parsed) &&
        parsed.length >= 3 &&
        typeof parsed[0] === 'string' &&
        typeof parsed[1] === 'number' &&
        typeof parsed[2] === 'number') {
      emitQuote(parsed[0], parsed[1], parsed[2]);
      return;
    }

    // Wrapped form: [["EURUSD_otc", timestamp, price], ...]
    if (Array.isArray(parsed)) {
      for (const item of parsed) {
        if (Array.isArray(item)) inspectParsed(item);
      }
    }
  }

  function WrappedWebSocket(url, protocols) {
    const ws = protocols === undefined
      ? new NativeWebSocket(url)
      : new NativeWebSocket(url, protocols);

    ws.addEventListener('message', (event) => {
      // Only parse text frames here. Binary protocol decoding is intentionally
      // not guessed or hard-coded.
      inspectValue(event.data);
    });

    return ws;
  }

  WrappedWebSocket.prototype = NativeWebSocket.prototype;
  Object.setPrototypeOf(WrappedWebSocket, NativeWebSocket);
  window.WebSocket = WrappedWebSocket;
})();
