const { TypedDataUtils } = require('ethers-eip712')

const SIGNING_DOMAIN_NAME = "OfferSystem"
const SIGNING_DOMAIN_VERSION = "1"

class Offer {

  constructor({ contractAddress, signer, library }) {
    this.contractAddress = contractAddress
    this.signer = signer
    this.library = library

    this.types = {
      EIP712Domain: [
        {name: "name", type: "string"},
        {name: "version", type: "string"},
        {name: "chainId", type: "uint256"},
        {name: "verifyingContract", type: "address"},
      ],
      Permit: [
        { name: "owner", type: "address" },
        { name: "spender", type: "address" },
        { name: "value", type: "uint256" },
        { name: "nonce", type: "uint256" },
        { name: "deadline", type: "uint256" }
      ]
    }
  }

  async _signingDomain() {
    if (this._domain != null) {
      return this._domain
    }
    const chainId = await this.signer.getChainId();
    this._domain = {
      name: SIGNING_DOMAIN_NAME,
      version: SIGNING_DOMAIN_VERSION,
      verifyingContract: this.contractAddress,
      chainId,
    }
    return this._domain
  }

  async _formatOffer(offer) {
    const domain = await this._signingDomain();
    return {
      domain,
      types: this.types,
      primaryType: 'Permit',
      message: offer,
    }
  }

  async makeOffer(owner, spender, value, nonce, deadline) {
    const offer = { owner, spender, value, nonce, deadline}
    const typedData = await this._formatOffer(offer);
    // const digest = TypedDataUtils.encodeDigest(typedData)
    const signature = await this.library.send("eth_signTypedData_v4", [owner, JSON.stringify(typedData)]);
    return {
        offer,
        signature
    }
  }
}

module.exports = {
    Offer
}