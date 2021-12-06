const Multisig = artifacts.require("Multisig");

const threshold = 2
const signer0 = "0x05dE8Dd5E43da4E415a8C5015A2f0F01a09DE8de"
const signer1 = "0xd7f6B7e438e32aE1E8e075fF285Fb065b641Ab38"
const signer2 = "0xc4d91d22354751607de0a529D09BCf1045707336"

module.exports = function (deployer) {
  deployer.deploy(Multisig, [signer0, signer1, signer2], threshold);
};
