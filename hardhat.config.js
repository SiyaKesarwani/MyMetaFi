require("dotenv").config();
require("@nomiclabs/hardhat-waffle");
require('@openzeppelin/hardhat-upgrades');
require('solidity-coverage');
require("@nomiclabs/hardhat-etherscan");
require('hardhat-contract-sizer');

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    goerli: {
      url: `https://goerli.infura.io/v3/${process.env.INFURA_KEY}`,
      chainId: 5,
      accounts: [`0x${process.env.DEPLOYER_PRIVATE_KEY_1}`],
      timeout: 1000000,
      allowUnlimitedContractSize: true
    },
    sepolia: {
      chainId: 11155111,
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: [`0x${process.env.DEPLOYER_PRIVATE_KEY_1}`],
      timeout: 1000000,
      allowUnlimitedContractSize: true
    },
    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
      accounts: [`0x${process.env.DEPLOYER_PRIVATE_KEY_1}`],
      timeout: 1000000,
      allowUnlimitedContractSize: true
    },
    hardhat: {
      // forking: {
      // url: `https://sepolia.infura.io/v3/${process.env.INFURA_KEY}`,
      // },
      chainId: 1
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  },
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
    overrides: {
      "contracts/conduit/Conduit.sol": {
        version: "0.8.20",
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      "contracts/conduit/ConduitController.sol": {
        version: "0.8.20",
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      "contracts/helper/TransferHelper.sol": {
        version: "0.8.20",
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    },
    contractSizer: {
      alphaSort: true,
      disambiguatePaths: false,
      runOnCompile: true,
      strict: true,
      only: [],
    },
  },
};
