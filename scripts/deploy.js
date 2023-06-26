// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  // const MYSTABLETOKEN = await hre.ethers.getContractFactory("MYStableToken");
  // const myStableToken = await MYSTABLETOKEN.deploy();

  // await myStableToken.deployed();

  // console.log("MyStableToken deployed to:", myStableToken.address);

  // stablecoin - bsc - 0x2139507Be79A9d80677Cc208B5A456a7B84eb310
  // stablecoin - mumbai - 0x256bf0a23ee0f37a647e9a56b83d7496c72c2d2c
  // stablecoin - avax - 0xBF9169751B7Cb2a4fD1390B328F59f65d337DdA3
  // stablecoin - arb_testnet - 0xe45360bE929AA0d4E21F205b9ad3f645Eb932C7b
  // stablecoin - sepolia - 0x85f0a44F6F9B52136CB19138B67356bdb37c45BA
  // stablecoin - rsk_testnet - 0xe45360bE929AA0d4E21F205b9ad3f645Eb932C7b
  // stablecoin - moonbase_testnet - 0xBF9169751B7Cb2a4fD1390B328F59f65d337DdA3
  // stablecoin - fantom_testnet - 0x85f0a44F6F9B52136CB19138B67356bdb37c45BA
  // stablecoin - milkomeda_c1_testnet - 0xe45360bE929AA0d4E21F205b9ad3f645Eb932C7b
  // stablecoin - goerli - 0xBF9169751B7Cb2a4fD1390B328F59f65d337DdA3
  // stablecoin - optimism_testnet - 0xe45360bE929AA0d4E21F205b9ad3f645Eb932C7b

  const VAULT = await hre.ethers.getContractFactory("Vault");
  const vault = await VAULT.attach("0x96B8aC7243bf0bfFC58Edc886C01b99C0eFd1498")
  // const vault = await VAULT.deploy(
  //   "0x256bf0a23ee0f37a647e9a56b83d7496c72c2d2c",
  //   ["0xf3636704cB8f042a0De759a307060058b2593570", "0xdCdFae782d8429A75C345ac4C920e8dc605afD80"],
  //   ["50000000", "50000000"],
  //   "0x79981294986Da068Ff372D536E43895DbcF7b3bC"
  // );

  // await vault.deployed();
    
  // console.log("Vault deployed to:", vault.address);

  const LOTTOGAME = await hre.ethers.getContractFactory("LottoGame");
  // const lottoGame = await LOTTOGAME.attach("0x32BA09c8B1851602E1F158033b3e0bC55Ad96E60")
  const lottoGame = await LOTTOGAME.deploy(
    "0x256bf0a23ee0f37a647e9a56b83d7496c72c2d2c",
    "10000000",
    vault.address,
    "1"
  );

  await lottoGame.deployed();

  console.log("LottoGame deployed to:", lottoGame.address);

  const RNG = await hre.ethers.getContractFactory("RNG");
  const rng = await RNG.attach("0x5785494d3f0Df561e59D1b5247EAFB04B879c177");
  // const rng = await RNG.deploy(
  //   // "4028",
  //   // "0x7a1bac17ccc5b313516c5e16fb24f7659aa5ebed",
  //   // "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f",
  //   // "0x7f5AF7a37a33898544717AAa6c35c111dCe95b28",
  //   "0xa0AD79D995DdeeB18a14eAef56A549A04e3Aa1Bd",
  //   "0x6238772544f029ecaBfDED4300f13A3c4FE84E1D",
  //   "0x27cc2713e7f968e4e86ed274a051a5c8aaee9cca66946f23af6f29ecea9704c3",
  //   [lottoGame.address, vault.address]
  // );

  // await rng.deployed();

  // console.log("RNG deployed to:", rng.address);

  let tx = await vault.addWhiteListed([lottoGame.address]);
  await tx.wait();

  let tx1 = await lottoGame.setRNGManager(rng.address);
  await tx1.wait();

  // let tx2 = await vault.setRNGManager(rng.address);
  // await tx2.wait();

  let tx4 = await rng.setWhitelisted([lottoGame.address]);
  await tx4.wait();

  // let tx3 = await rng.setGasPrice("301000000000000000");
  // await tx3.wait();
}


// npx @api3/airnode-admin derive-sponsor-wallet-address \
//   --airnode-xpub xpub6CuDdF9zdWTRuGybJPuZUGnU4suZowMmgu15bjFZT2o6PUtk4Lo78KGJUGBobz3pPKRaN9sLxzj21CMe6StP3zUsd8tWEJPgZBesYBMY7Wo \
//   --airnode-address 0x6238772544f029ecaBfDED4300f13A3c4FE84E1D \
//   --sponsor-address <Use the address of your Deployed Lottery Contract>
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
