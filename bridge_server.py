#!/usr/bin/env python3
"""
999 Trading Intelligence local quote relay.

Receives sanitized browser-extension quote messages on ws://127.0.0.1:8766
and forwards them to the Flutter scanner on ws://127.0.0.1:8765.

Only messages shaped like:
{"symbol":"EURUSD_otc","timestamp":1786338005.59,"price":1.19212}
are relayed.
"""
import asyncio
import json
import websockets

SCANNER_CLIENTS = set()

async def scanner_handler(ws):
    SCANNER_CLIENTS.add(ws)
    try:
        await ws.wait_closed()
    finally:
        SCANNER_CLIENTS.discard(ws)

async def capture_handler(ws):
    async for raw in ws:
        try:
            data = json.loads(raw)
            if not isinstance(data, dict):
                continue
            symbol = data.get("symbol")
            timestamp = data.get("timestamp")
            price = data.get("price")
            if not isinstance(symbol, str):
                continue
            if not isinstance(timestamp, (int, float)):
                continue
            if not isinstance(price, (int, float)):
                continue

            clean = json.dumps({
                "symbol": symbol,
                "timestamp": float(timestamp),
                "price": float(price),
            })

            dead = []
            for client in list(SCANNER_CLIENTS):
                try:
                    await client.send(clean)
                except Exception:
                    dead.append(client)
            for client in dead:
                SCANNER_CLIENTS.discard(client)
        except Exception:
            continue

async def main():
    async with websockets.serve(scanner_handler, "127.0.0.1", 8765), \
               websockets.serve(capture_handler, "127.0.0.1", 8766):
        print("999 local relay running")
        print("Scanner input : ws://127.0.0.1:8765")
        print("Browser output: ws://127.0.0.1:8766")
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())
