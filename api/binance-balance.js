// /api/binance-balance.js
// Vercel serverless function — runs server-side only.
// The Binance API key/secret live in Vercel's environment variables and
// are NEVER sent to the browser. The frontend only ever calls this
// endpoint and gets back clean, already-computed numbers.

const crypto = require('crypto');

module.exports = async (req, res) => {
  try {
    const apiKey = process.env.BINANCE_API_KEY;
    const apiSecret = process.env.BINANCE_API_SECRET;

    if (!apiKey || !apiSecret) {
      return res.status(500).json({ error: 'Server not configured — missing Binance API env vars' });
    }

    // ---- signed request to Binance's account endpoint (read-only key) ----
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

    // ---- public price data (no auth needed) to value the reserve in USD ----
    const priceRes = await fetch('https://api.binance.com/api/v3/ticker/price?symbols=%5B%22BTCUSDT%22%2C%22ETHUSDT%22%5D');
    const prices = await priceRes.json();
    const btcPrice = parseFloat(prices.find(p => p.symbol === 'BTCUSDT').price);
    const ethPrice = parseFloat(prices.find(p => p.symbol === 'ETHUSDT').price);

    const totalUsd = (balances.BTC * btcPrice) + (balances.ETH * ethPrice) + balances.USDT;

    res.setHeader('Cache-Control', 's-maxage=15, stale-while-revalidate=30');
    return res.status(200).json({
      btc: balances.BTC,
      usdt: balances.USDT,
      eth: balances.ETH,
      btcPrice,
      ethPrice,
      totalUsd,
      updatedAt: new Date().toISOString()
    });
  } catch (e) {
    return res.status(500).json({ error: e.message });
  }
};
