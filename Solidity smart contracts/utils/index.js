import { LazyMinter } from "./lazyMinter";
import { Offer } from "./signature";
import axios from "axios";

export const toHex = (num) => {
    const val = Number(num);
    return "0x" + val.toString(16);
};

export const switchNetwork = async (network, library) => {
    await library.provider.request({
      method: "wallet_switchEthereumChain",
      params: [{ chainId: toHex(network) }],
    });
};

export const getEtherPrice = async () => {
  const cryptoData = await axios.get("https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd", {
    headers: {
      "Access-Control-Allow-Origin": "*"
    }
  });
  const ethereum = cryptoData.data[1];
  return ethereum.current_price;
}

export { LazyMinter, Offer }