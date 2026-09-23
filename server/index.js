// server/index.js
// Standalone Express server — deployed on Render in a non-US region
// (Binance.com blocks API requests originating from US-based servers).
// The Binance key/secret live only in Render's environment variables.

const express = require('express');
const crypto = require('crypto');

const app = express();
const PORT = process.env.PORT || 3000;

// Allow the frontend (any origin, since this endpoint only returns
// public-ish read-only totals, not account credentials) to call this.
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});

app.get('/balance', async (req, res) => {
  try {
    const apiKey = process.env.BINANCE_API_KEY;
    const apiSecret = process.env.BINANCE_API_SECRET;

    if (!apiKey || !apiSecret) {
      return res.status(500).json({ error: 'Server not configured — missing Binance API env vars' });
    }

    const timestamp = Date.now();
    const query = `timestamp=${timestamp}&recvWindow=10000`;
    const signature = crypto.createHmac('sha256', apiSecret).update(query).digest('hex');

    const accountRes = await fetch(
      `https://api.binance.com/api/v3/account?${query}&signature=${signature}`,
      { headers: { 'X-MBX-APIKEY': apiKey } }
    );

    if (!accountRes.ok) {
      const detail = await accountRes.text();
      return res.status(502).json({ error: 'Binance account fetch failed', detail });
    }
    const account = await accountRes.json();

    const relevant = ['BTC', 'USDT', 'ETH'];
    const balances = {};
    relevant.forEach(asset => {
      const b = account.balances.find(x => x.asset === asset);
      balances[asset] = b ? parseFloat(b.free) + parseFloat(b.locked) : 0;
    });

    const priceRes = await fetch('https://api.binance.com/api/v3/ticker/price?symbols=%5B%22BTCUSDT%22%2C%22ETHUSDT%22%5D');
    const prices = await priceRes.json();
    const btcPrice = parseFloat(prices.find(p => p.symbol === 'BTCUSDT').price);
    const ethPrice = parseFloat(prices.find(p => p.symbol === 'ETHUSDT').price);

    const totalUsd = (balances.BTC * btcPrice) + (balances.ETH * ethPrice) + balances.USDT;

    res.json({
      btc: balances.BTC,
      usdt: balances.USDT,
      eth: balances.ETH,
      btcPrice,
      ethPrice,
      totalUsd,
      updatedAt: new Date().toISOString()
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/', (req, res) => res.send('Alpha Strategy balance proxy — OK'));

app.listen(PORT, () => console.log(`Balance proxy listening on port ${PORT}`));
