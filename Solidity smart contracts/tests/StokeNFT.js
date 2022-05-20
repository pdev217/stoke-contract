const { expect } = require("chai");

let StokeNFT;
let hardhatNFT;
let owner;
let addr1;

describe("StokeNFT contract", function () {
  it("Deployment should assign the total supply of tokens to the owner", async function () {
    [owner, addr1] = await ethers.getSigners();

    StokeNFT = await ethers.getContractFactory("StokeNFT");

    hardhatNFT= await StokeNFT.deploy();

    const ownerBalance = await hardhatNFT.balanceOf(owner.address);
    expect(await hardhatNFT.totalSupply()).to.equal(ownerBalance);
  });

  it("mint successfully", async function () {
    await hardhatNFT.createToken(1, addr1.address, 'https://ipfs.io/ipfs/QmRFs2ZhztgiVSivw9mJVYDqgsLsBcUSP8DipgkBovREX5')
      .then((res) => expect(res))
  })

  it("createOrder successfully", async function () {
    await hardhatNFT.createOrder('https://ipfs.io/ipfs/QmRFs2ZhztgiVSivw9mJVYDqgsLsBcUSP8DipgkBovREX5', 2, hardhatNFT.address, )
      .then((res) => expect(res))
  })

  it("Should get state if exist tokenId minted in blockchain", async function () {
    expect(await hardhatNFT.IsExistToken(1));
  })
})