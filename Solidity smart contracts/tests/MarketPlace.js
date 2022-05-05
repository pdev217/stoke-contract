const { Offer } = require("../src/utils/offer")

const { expect } = require("chai");
const web3Abi = require("web3-eth-abi");
const { ethers } = require("hardhat");

const provider = waffle.provider;

let WETH, weth;
let nftArtifact, nftContract;
let marketContract;
let MarketPlace;
let owner, account1, account2, account3, account4;

describe("StokeMarketPlace contract", function () {
  it("Deploy contracts", async function () {
    [owner, account1, account2, account3, account4] = await ethers.getSigners();

    MarketPlace = await  ethers.getContractFactory('StokeMarketplace');
    marketContract = await MarketPlace.deploy();
    await marketContract.deployed();
    console.log("Marketplace Deployed to:", marketContract.address);

    nftArtifact = await  ethers.getContractFactory('StokeNFT');
    nftContract = await nftArtifact.deploy();
    await nftContract.deployed();
    console.log("NFT deployed to:", nftContract.address);

    WETH = await  ethers.getContractFactory('WETH9');
    // weth = await WETH.deploy('WrappedEther', 'WETH', 18, ethers.utils.parseUnits("100000000", 18), owner.address, owner.address);
    weth = await WETH.deploy();
    await weth.deployed();
    console.log("WETH deployed to:", weth.address);
  })

  it("Start make offer", async() => {
    const offerClass = new Offer({contractAddress: weth.address, signer:account1, library:provider})
    const nonce = await weth.nonces(account1.address);
    const {offer, signature} = await offerClass.makeOffer(account1.address, marketContract.address, 1, Number(ethers.utils.formatUnits(nonce))*10**18, Date.now("2022-04-20"));
    const signData = ethers.utils.splitSignature(signature);
    const { v,r,s} = signData;
    // await weth.permit(offer.owner, offer.spender, offer.value, offer.deadline, v,r,s);
  })

  it("Start accept offer", async() => {
    await weth.connect(account4).deposit({from:account4.address, value: ethers.utils.parseEther("1")})
    const offerClass = new Offer({contractAddress: weth.address, signer:account4, library:provider})
    const nonce = await weth.nonces(account4.address);
    const {offer, signature} = await offerClass.makeOffer(account4.address, marketContract.address, 1000000000000000, Number(ethers.utils.formatUnits(nonce))*10**18, Date.now("2022-04-20"));
    // const signData = ethers.utils.splitSignature(signature);
    // const { v,r,s} = signData;
    const offerC = {
      sender: offer.owner,
      amount:offer.value,
      expiresAt: offer.deadline
    }
    const Token = {
      tokenId: 0,
      tokenURI: "ipfs:lion"
    }
    // await weth.permit(offer.owner, offer.spender, offer.value, offer.deadline, v,r,s);
    // await marketContract.accept(offerC, weth.address, nftContract.address, Token, v,r,s);
    await marketContract.accept(offerC, weth.address, nftContract.address, Token);
    const amount = await weth.allowance(account4.address, marketContract.address);
    console.log(ethers.utils.formatUnits(amount))
  })

  it("Fixed list sale", async() => {
    await nftContract.connect(account1).createToken(1, account1.address, 'ipfs://lion');
    await nftContract.connect(account1).approve(marketContract.address, 1);
    await marketContract.connect(account2).buyOrder(account1.address, 1, nftContract.address, {value: 10000000});
  })

  it("start auction", async() => {
    await nftContract.connect(account1).createToken(1, account1.address, 'ipfs://lion');
    await nftContract.connect(account1).approve(marketContract.address, 1);
    await marketContract.connect(account2).buyOrder(account1.address, 1, nftContract.address, {value: 10000000});
  })
})