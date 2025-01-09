require("@nomicfoundation/hardhat-toolbox");
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.27",
  networks: {
    quorum: {
      url: "http://18.138.252.0:8545",
      accounts: ["0x13d70c66406b3e631fe9fa24e9ab6136a554769d23229ebaac70e953de389961"],
    },
  },
};
