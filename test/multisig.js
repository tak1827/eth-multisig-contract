const Multisig = artifacts.require("Multisig");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("Multisig", function (/* accounts */) {
  it("should assert true", async function () {
    await Multisig.deployed();
    return assert.isTrue(true);
  });
});
