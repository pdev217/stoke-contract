const { Offer } = require('../utils/signature');

const { expect } = require('chai');
const web3Abi = require('web3-eth-abi');
const { ethers } = require('hardhat');

const provider = waffle.provider;

let auctionFee;
let WETH, weth, signData;
let nftArtifact, nftContract;
let marketContract;
let MarketPlace;
let owner, account1, account2, account3, account4;

const Token = {
  tokenId: 1,
  tokenURI: 'ipfs:lion',
};

describe('StokeMarketPlace contract', function () {
  // helper to sign using (spender, tokenId, nonce, deadline) EIP 712
  async function sign(spender, tokenId, nonce, deadline) {
    const typedData = {
      types: {
        Permit: [
          { name: 'spender', type: 'address' },
          { name: 'tokenId', type: 'uint256' },
          { name: 'nonce', type: 'uint256' },
          { name: 'deadline', type: 'uint256' },
        ],
      },
      primaryType: 'Permit',
      domain: {
        name: "StokeMarketplace",
        version: '1',
        chainId: chainId,
        verifyingContract: contract.address,
      },
      message: {
        spender,
        tokenId,
        nonce,
        deadline,
      },
    };

    // sign Permit
    const signature = await deployer._signTypedData(
      typedData.domain,
      { Permit: typedData.types.Permit },
      typedData.message,
    );

    return signature;
  }
  it('Deploy contracts', async function () {
    [owner, account1, account2, account3, account4] = await ethers.getSigners();
    console.log(
      '🚀 ~ file: MarketPlace.js ~ line 24 ~ owner, account1, account2, account3, account4',
      owner.address,
      account1.address,
      account2.address,
      account3.address,
      account4.address
    );

    MarketPlace = await ethers.getContractFactory('StokeMarketplace');
    marketContract = await MarketPlace.deploy();
    await marketContract.deployed();
    console.log('Marketplace Deployed to:', marketContract.address);

    nftArtifact = await ethers.getContractFactory('StokeNFT');
    nftContract = await nftArtifact.deploy();
    await nftContract.deployed();
    console.log('NFT deployed to:', nftContract.address);

    WETH = await ethers.getContractFactory('WETH9');
    // weth = await WETH.deploy('WrappedEther', 'WETH', 18, ethers.utils.parseUnits("100000000", 18), owner.address, owner.address);
    weth = await WETH.deploy();
    await weth.deployed();
    console.log('WETH deployed to:', weth.address);
  });

  it('Start make offer', async () => {
    await nftContract.connect(account4).createToken(1, account4.address, 'ipfs://lion');
    const offerClass = new Offer({ contractAddress: weth.address, signer: account1, library: provider });
    const nonce = await weth.nonces(account1.address);
    signData = await offerClass.makeOffer(
      account1.address,
      marketContract.address,
      2,
      Number(ethers.utils.formatUnits(nonce)) * 10 ** 18,
      Math.floor(new Date('2022-05-20') / 1000)
    );
    console.log('🚀 ~ file: MarketPlace.js ~ line 47 ~ it ~ signData', signData);
    const tokenOwner = await nftContract.ownerOf(1);
    console.log('🚀 ~ nftContract.ownerOf(1)', tokenOwner);
  });

  it('Start accept offer', async () => {
    const { offer } = signData;
    console.log('🚀 ~ file: MarketPlace.js ~ line 51 ~ it ~ offer', offer);
    // const { v, r, s } = ethers.utils.splitSignature(signature);
    // FIXME: permit is not correct in ERC721
    const nonce = await weth.nonces(account1.address);
    const signature = await sign(
      await offer.owner,
      1,
      nonce,
      offer.deadline,
    );
    console.log("🚀 ~ file: MarketPlace.js ~ line 112 ~ it ~ signature", signature)
    // await weth.permit(offer.owner, offer.spender, offer.value, offer.deadline, v, r, s);
    await weth.connect(account1).deposit({ from: account1.address, value: ethers.utils.parseEther('1') });
    const offerC = {
      sender: offer.owner,
      amount: offer.value,
      expiresAt: offer.deadline,
    };
    // await weth.permit(offer.owner, offer.spender, offer.value, offer.deadline, v,r,s);
    // await marketContract.accept(offerC, weth.address, nftContract.address, Token, v,r,s);
    const tx = await marketContract.accept(offerC, weth.address, nftContract.address, Token, signature);
    const amount = await weth.allowance(account1.address, marketContract.address);
    const account1_balance = await weth.balanceOf(account1.address);
    const account4_balance = await weth.balanceOf(account4.address);
    const offerowner_balance = await weth.balanceOf(offer.owner);
    console.log('🚀 ~ file: MarketPlace.js ~ line 70 ~ it ~ account1_balance', account1_balance);
    console.log('🚀 ~ file: MarketPlace.js ~ line 71 ~ it ~ account4_balance', account4_balance);
    console.log('🚀 ~ file: MarketPlace.js ~ line 72 ~ it ~ offerowner_balance', offerowner_balance);
    // console.log("@@@@@", tx)
    console.log('account1 allowance', amount);
    const tokenOwner = await nftContract.ownerOf(1);
    console.log('🚀 ~ nftContract.ownerOf(1)', tokenOwner);
  });

  it('buy order', async () => {
    await nftContract.connect(account1).createToken(1, account1.address, 'ipfs://lion');
    await nftContract.connect(account1).approve(marketContract.address, 1);
    await marketContract.connect(account2).buyOrder(account1.address, 1, nftContract.address, { value: 10000000 });
  });

  it('Fixed list sale', async () => {
    await nftContract.connect(account1).createToken(2, account1.address, 'ipfs://lion');
    await nftContract.connect(account1).createToken(3, account1.address, 'ipfs://lion');
    // console.log("~ file: MarketPlace.js ~ line 81 ~ it ~ nftContract.address", nftContract.address);
    // console.log("~ file: MarketPlace.js ~ line 81 ~ it ~ marketContract", marketContract);
    await nftContract.connect(account1).approve(marketContract.address, 2);
    await nftContract.connect(account1).approve(marketContract.address, 3);
    fixedSale = await marketContract
      .connect(account1)
      .fixedSales(
        [2, 3],
        [5000, 50000000000],
        [Math.floor(new Date('2022-05-2') / 1000), Math.floor(new Date('2022-05-15') / 1000)],
        [Math.floor(new Date('2022-05-20') / 1000), Math.floor(new Date('2022-05-20') / 1000)],
        [nftContract.address, nftContract.address]
      );
    await fixedSale.wait();
  });

  it('buy NFT', async () => {
    fixedSale = await marketContract.connect(account2).buyNft(2, nftContract.address, { value: 5000 });
    await fixedSale.wait();
  });

  it('cancel list Fixed sale', async () => {
    await marketContract.connect(account1).cancelFixedSale(3, nftContract.address);
  });
  it('set auctionFee', async () => {
    await nftContract.connect(account1).createToken(3, account1.address, 'ipfs://lion');
    await nftContract.connect(account1).createToken(4, account1.address, 'ipfs://lion');
    // console.log("~ file: MarketPlace.js ~ line 81 ~ it ~ nftContract.address", nftContract.address);
    // console.log("~ file: MarketPlace.js ~ line 81 ~ it ~ marketContract", marketContract);
    // TODO: multi preapprove
    await nftContract.connect(account1).approve(marketContract.address, 3);
    await nftContract.connect(account1).approve(marketContract.address, 4);
    startAuction = await marketContract
      .connect(account1)
      .startAuction(
        [2, 3],
        false,
        [5000, 50000000000],
        [5000, 50000000000],
        [1651253229, 1662512429],
        [1652512429, 1652912429],
        [nftContract.address, nftContract.address]
      );
    await startAuction.wait();
  });

  it('start timing', async () => {
    const time = await nftContract.connect(account1).timing(Token.tokenId);
    // await nftContract.connect(account1).approve(marketContract.address, 1);
    // await marketContract.connect(account2).buyOrder(account1.address, 1, nftContract.address, {value: 10000000});
  });
  it('start auction', async () => {
    await nftContract.connect(account1).createToken(1, account1.address, 'ipfs://lion');
    // await nftContract.connect(account1).approve(marketContract.address, 1);
    await nftContract.connect(account1).startAuction(Token.tokenId, 10, 30, 24, 60, nftContract.address);
    // await nftContract.connect(account1).approve(marketContract.address, 1);
    // await marketContract.connect(account2).buyOrder(account1.address, 1, nftContract.address, {value: 10000000});
  });
  it('buy auction', async () => {
    await nftContract.connect(account2).buyAuction(Token.tokenId, 10, 30, 24, 60, nftContract.address);
    // await nftContract.connect(account1).approve(marketContract.address, 1);
    // await marketContract.connect(account2).buyOrder(account1.address, 1, nftContract.address, {value: 10000000});
  });
});
// TODO: metatransaction issue
// TODO: permit issue
