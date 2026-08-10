# 999 Trading Intelligence — V2 Live Feed Architecture

This build upgrades V1 into a provider-independent, multi-asset scanner.

## What V2 adds

- Pluggable feed adapters
- Browser Quote Bridge adapter
- Generic WebSocket provider adapter
- Automatic asset discovery
- Separate state per symbol
- 1s / 5s / 15s / 60s candles
- EMA 9 / EMA 21
- RSI 14
- Tick velocity
- 5-second momentum
- 15-second candle-body strength
- Feed staleness protection
- CALL / PUT / WAIT scoring
- Live asset ranking
- Local quote relay
- Browser extension scaffold that forwards only sanitized quote data

## Important design choice

The scanner does **not** store or reuse Pocket Option passwords, cookies, SID values,
authorization headers, or session tokens.

The browser-side bridge is designed to forward only:

```json
{"symbol":"EURUSD_otc","timestamp":1786338005.59,"price":1.19212}
```

The included page bridge only parses text quote frames that are already visible to the page.
It deliberately does not guess at undocumented binary decoding or bypass broker authentication.

## Quick test

### 1. Run the Flutter scanner

```bash
flutter pub get
flutter run -d chrome
```

Click **Run Demo Feed** to test the scanner immediately.

### 2. Run the local relay

In another terminal:

```bash
python3 -m pip install -r requirements.txt
python3 bridge_server.py
```

Relay ports:

- Scanner receives on `ws://127.0.0.1:8765`
- Browser extension sends to `ws://127.0.0.1:8766`

### 3. Load the extension

Chrome/Chromium:
1. Open `chrome://extensions`
2. Enable Developer mode
3. Choose **Load unpacked**
4. Select the `bridge_extension` folder

Firefox:
- For temporary testing, use `about:debugging` → This Firefox → Load Temporary Add-on
- Select `bridge_extension/manifest.json`

Browser-extension APIs differ slightly by browser version. The extension scaffold is deliberately minimal.

### 4. Connect the scanner

In 999 Trading Intelligence, click:

**Connect Browser Bridge**

If sanitized quote rows are observed and forwarded, detected assets will populate automatically.

## External provider path

The scanner brain is not tied to Pocket Option.

`lib/feeds/generic_websocket_adapter.dart` is the starting point for licensed APIs such as
Massive or Twelve Data. Add the provider-specific authentication/subscription logic there,
then normalize every quote to:

```text
symbol | timestamp | price
```

The scanner engine does the rest.

## Recommended production sequence

1. Validate quote timestamps and price freshness
2. Confirm 1-minute candle boundaries
3. Add provider-specific Massive/Twelve Data adapters
4. Add persistent signal logging
5. Backtest CALL/PUT/WAIT thresholds
6. Add payout/asset filters if you have a legitimate data source for them
7. Only then evaluate live signal quality

No signal engine can guarantee winning 60-second trades. Treat the output as analytical software, not a guaranteed result.
