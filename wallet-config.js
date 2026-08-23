/* ============================================================
   WALLET CONFIG — reserve deposit addresses
   Shown to participants in the dashboard "Deposit" panel.
   Double-check these against your exchange/wallet before
   changing them — a wrong address here sends real funds astray.
   ============================================================ */

const WALLET_ADDRESSES = {
  BTC: {
    label: "Bitcoin",
    network: "Bitcoin (BTC network only)",
    address: "17jNnN6hbBpzGsFivU6cVwzRaVwgfv5tWw"
  },
  USDT: {
    label: "USDT",
    network: "BNB Smart Chain — BEP20 only",
    address: "0x80a7afe31b5fc5c5f16ba1c5a4cb4cc3a0ac8786"
  },
  ETH: {
    label: "Ethereum",
    network: "Ethereum — ERC20 only",
    address: "0x80a7afe31b5fc5c5f16ba1c5a4cb4cc3a0ac8786"
  }
};
