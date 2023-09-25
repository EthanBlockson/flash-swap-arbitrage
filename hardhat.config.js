require("@nomicfoundation/hardhat-ethers");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.0",
      },
    ],
  },
  networks: {
    alchemyGoerli: {
      url: 'YOUR_ALCHEMY_API_KEY_HERE', // link or API key
      accounts: [
        'YOUR_OWNER_WALLET_PRIVATE_KEY_HERE', // 'owner'
      ],
    },
    bscTestnet: {
      url: 'https://data-seed-prebsc-1-s1.bnbchain.org:8545', // link or API key
      chainId: 97, // BSC Testnet Chain ID
      gasPrice: 11000000000, // wei
      gas: 6000000, // Gas limit
      accounts: [
        'YOUR_OWNER_WALLET_PRIVATE_KEY_HERE', // 'owner'
      ],
    },
  },
};
