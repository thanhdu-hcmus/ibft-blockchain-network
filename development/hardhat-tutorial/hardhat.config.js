require("@nomicfoundation/hardhat-toolbox");
/** @type import('hardhat/config').HardhatUserConfig */

// Accessing environment variables
const URL = process.env.URL; // Accessing a custom variable
const ACCOUNTS = process.env.ACCOUNTS;  // Accessing the secret

module.exports = {
  solidity: "0.8.27",
  networks: {
    quorum: {
      url: URL,
      accounts: ACCOUNTS.split(','),
    },
  },
};
