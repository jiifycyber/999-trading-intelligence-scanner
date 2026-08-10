(() => {
  const script = document.createElement('script');
  script.src = chrome.runtime.getURL('page_bridge.js');
  (document.documentElement || document.head).appendChild(script);
  script.onload = () => script.remove();

  let relay = null;

  function connectRelay() {
    try {
      relay = new WebSocket('ws://127.0.0.1:8766');
      relay.onclose = () => setTimeout(connectRelay, 1500);
      relay.onerror = () => {};
    } catch (_) {
      setTimeout(connectRelay, 1500);
    }
  }
  connectRelay();

  window.addEventListener('message', (event) => {
    if (event.source !== window) return;
    const data = event.data;
    if (!data || data.__999Quote !== true) return;

    const symbol = data.symbol;
    const timestamp = data.timestamp;
    const price = data.price;

    if (typeof symbol !== 'string') return;
    if (typeof timestamp !== 'number') return;
    if (typeof price !== 'number') return;

    if (relay && relay.readyState === WebSocket.OPEN) {
      relay.send(JSON.stringify({symbol, timestamp, price}));
    }
  });
})();
