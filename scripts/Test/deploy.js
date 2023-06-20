// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  // const MYSTABLETOKEN = await hre.ethers.getContractFactory("MyStableToken");
  // const myStableToken = await MYSTABLETOKEN.deploy();

  // await myStableToken.deployed();

  // console.log("MyStableToken deployed to:", myStableToken.address);

  // stablecoin - 0x256bf0A23eE0F37A647e9A56b83d7496c72c2d2C

  const VAULT = await hre.ethers.getContractFactory("RichieRich");
  const vault = await VAULT.attach("0x4E9638d228CBC01a231970cd9c16D80583d767Ce");
  // const vault = await VAULT.deploy(
    // "0x256bf0A23eE0F37A647e9A56b83d7496c72c2d2C",
    // ["0xf3636704cB8f042a0De759a307060058b2593570", "0xdCdFae782d8429A75C345ac4C920e8dc605afD80"],
    // ["50000000", "50000000"],
    // "4028",
    // "0x7a1bac17ccc5b313516c5e16fb24f7659aa5ebed",
    // "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f",
    // "0x79981294986Da068Ff372D536E43895DbcF7b3bC"
  // );

  // await vault.deployed();
    
  // console.log("Vault deployed to:", vault.address);

  const LOTTOGAME = await hre.ethers.getContractFactory("Doremon");
  const lottoGame = await LOTTOGAME.deploy(
    "0x256bf0A23eE0F37A647e9A56b83d7496c72c2d2C",
    "100000000",
    "4028",
    "0x7a1bac17ccc5b313516c5e16fb24f7659aa5ebed",
    "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f",
    "0x6f1e9a6320E8CAD50Fc9bC383C5Ff720CA65EAE5"
  );

  await lottoGame.deployed();

  console.log("LottoGame deployed to:", lottoGame.address);

  let tx = await vault.addWhiteListed([lottoGame.address]);
  await tx.wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
