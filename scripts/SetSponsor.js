// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

// mumbai - 0x0B38aA9774c7286C59afcA40619A409eE639bBD9
// arb - 0x4C4e5C49B4296DCD2451f619c73870113111bcbD
// avax - 0x22aA0c8b8dc73f0F28B29F234C847031988555c2  

  const RNG = await hre.ethers.getContractFactory("RNG");
  const rng = await RNG.attach("0xd2BA99991ab50E03A1532cC583c7ABA9Bd1B1aab");

  let tx = await rng.setSponsorWallet("0xA13c2AB6FFc23baecbB0A0f8cdDb5CC633D4953d");
  await tx.wait();

  // const LOTTOGAME = await hre.ethers.getContractFactory("LottoGame");
  // const lottoGame = await LOTTOGAME.attach("0x0e049fF412ab376E0e1576bB09824089d23c199A")
  // const lottoGame = await LOTTOGAME.deploy(
  //   "0x256bf0a23ee0f37a647e9a56b83d7496c72c2d2c",
  //   "10000000",
  //   vault.address
  // );

  // await lottoGame.deployed();

  // console.log("LottoGame deployed to:", lottoGame.address);

  // let test = await lottoGame.buyTickets("NA", "test", "28", "0xbab3dbf478bb0b76d17d26d63b29c554f62fde14842d180b5aa7ead6e0ae282c", "0x49094618c890869f5f32c64fdc5198e448fd81e272dd2a723393bc75c4d50cd0");
  // await test.wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
