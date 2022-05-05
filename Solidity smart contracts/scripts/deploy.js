// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const Stoke = await ethers.getContractFactory("StokeNFT");
  const stoke = await Stoke.deploy();

  const Token = await ethers.getContractFactory("WETH9");
  const tokenContract = await Token.deploy();

  const offer = await ethers.getContractFactory("OfferSystem");
  const offerSystem = await Token.deploy();

  const lazy = await ethers.getContractFactory("LazyNFT");
  const lazyminter = await lazy.deploy();

  await stoke.deployed();
  await tokenContract.deployed();
  await offerSystem.deployed();
  await lazyminter.deployed();

  console.log("StokeNFT deployed to:", stoke.address);
  console.log("WEH9 deployed to:", tokenContract.address);
  console.log("offer system deployed to:", offerSystem.address);
  console.log("lazy minter deployed to:", lazyminter.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
