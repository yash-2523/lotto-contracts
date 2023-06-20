require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

const { POLYGON_API_KEY, BSC_API_KEY, AVAX_API_KEY, ARB_API_KEY, PRIVATE_KEY } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {

  networks: {
    mumbaiTestnet: {
      url: "https://polygon-mumbai.infura.io/v3/5c7db01997694b50aceb8bded54bc41f",
      accounts: [`0x${PRIVATE_KEY}`],
      gas: 2100000,
      gasPrice: 8000000000
    },
    bscTestnet: {
      url: `https://binance-testnet.rpc.thirdweb.com/ed043a51ae23b0db3873f5a38b77ab28175fa496f15d3c53cf70401be89b622a`,
      accounts: [`0x${PRIVATE_KEY}`],
      gas: 21000000,
      gasPrice: 8000000000
    },
    avaxTestnet: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      accounts: [`0x${PRIVATE_KEY}`],
    },
    arbitrum_testnet: {
      url: "https://arb-goerli.g.alchemy.com/v2/Zaym8f5SAZ063NID9rfPceFwrq2vz5QB",
      accounts: [`0x${PRIVATE_KEY}`],
    },
    goreli: {
      url: "https://goerli.rpc.thirdweb.com/ed043a51ae23b0db3873f5a38b77ab28175fa496f15d3c53cf70401be89b622a",
      accounts: [`0x${PRIVATE_KEY}`]
    },
    sepolia: {
      url: "https://sepolia.infura.io/v3/5c7db01997694b50aceb8bded54bc41f",
      accounts: [`0x${PRIVATE_KEY}`]
    },
    rskTestnet: {
      url: 'https://public-node.testnet.rsk.co/',
      accounts: [`0x${PRIVATE_KEY}`]
    },
    optimism_testnet: {
      url: "https://optimism-goerli.infura.io/v3/5c7db01997694b50aceb8bded54bc41f",
      accounts: [`0x${PRIVATE_KEY}`]
    },
    moonbase_testnet: {
      url: "https://moonbase-alpha.rpc.thirdweb.com/ed043a51ae23b0db3873f5a38b77ab28175fa496f15d3c53cf70401be89b622a",
      accounts: [`0x${PRIVATE_KEY}`]
    },
    fantom_testnet: {
      url: "https://fantom-testnet.rpc.thirdweb.com/ed043a51ae23b0db3873f5a38b77ab28175fa496f15d3c53cf70401be89b622a",
      accounts: [`0x${PRIVATE_KEY}`]
    },
    milkomeda_c1_testnet: {
      url: " https://rpc-devnet-cardano-evm.c1.milkomeda.com",
      accounts: [`0x${PRIVATE_KEY}`]
    }
  },
  solidity: {
    compilers: [
      {
        version: "0.8.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ]

  },
  etherscan: {
    apiKey: {
      arbitrum_testnet: ARB_API_KEY,
      avalancheFujiTestnet: AVAX_API_KEY,
      polygonMumbai: POLYGON_API_KEY,
    },
    customChains: [
      {
        network: "arbitrum_testnet",
        chainId: 421613,
        urls: {
          apiURL: "https://api-goerli.arbiscan.io/api",
          browserURL: "https://goerli.arbiscan.io/"
        }
      }
    ]
  }
};
