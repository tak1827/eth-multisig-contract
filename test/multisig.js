const Multisig = artifacts.require("Multisig");
const MockERC721 = artifacts.require("MockERC721");
const { constants, BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;
const { expect } = require('chai');

const NFT_NAME = "MockToken";
const PRI_KEY = "0xdf38daebd09f56398cc8fd699b72f5ea6e416878312e1692476950f427928e7d";

contract("Multisig", function ([deployer, signer0, signer1, signer2, signer3, owner, attacker]) {

  describe('deploy', () => {
    it('check deployed paramaters of multisig', async function () {
      const threshold = 2
      const multisig = await Multisig.new([signer0, signer1, signer2], threshold)

      expect(await multisig.signers(0)).to.be.equal(signer0);
      expect(await multisig.signers(1)).to.be.equal(signer1);
      expect(await multisig.signers(2)).to.be.equal(signer2);
      expect(await multisig.threshold()).to.be.bignumber.equal('2');
    });

    it('check deployed paramaters of mock erc721', async function () {
      const threshold = 2
      const multisig = await Multisig.new([signer0, signer1, signer2], threshold)

      const controlled = await multisig.controlled()
      const nft = await MockERC721.at(controlled);

      expect(await nft.name()).to.be.equal(NFT_NAME);
    });
  });

  describe('callControlled', () => {
    const tokenId = 101
    const abiEncodedCall = web3.eth.abi.encodeFunctionCall({
      name: 'mint',
      type: 'function',
      inputs: [{
          type: 'address',
          name: 'to'
      },{
          type: 'uint256',
          name: 'tokenId'
      }]
    }, [owner, tokenId]);

    it('succeed to mint nft', async function () {
      const mintSigner = web3.eth.accounts.privateKeyToAccount(PRI_KEY);
      const threshold = 2
      const multisig = await Multisig.new([signer0, mintSigner.address, signer2], threshold)

      const hash = web3.utils.sha3(abiEncodedCall);
      const sig = await web3.eth.accounts.sign(hash, mintSigner.privateKey);

      const receipt = await multisig.callControlled([sig.signature], abiEncodedCall, {from: signer0})
      expectEvent(receipt, 'Called', {
        caller: signer0,
        data: abiEncodedCall,
        returndata: null
      });

      const controlled = await multisig.controlled()
      const nft = await MockERC721.at(controlled);

      expect(await nft.exists(tokenId)).to.be.equal(true);
    });

    it('failed by insufficient sig', async function () {
      const mintSigner = web3.eth.accounts.privateKeyToAccount(PRI_KEY);
      const threshold = 3
      const multisig = await Multisig.new([signer0, mintSigner.address, signer2, signer3], threshold)

      const hash = web3.utils.sha3(abiEncodedCall);
      const sig = await web3.eth.accounts.sign(hash, mintSigner.privateKey);

      await expectRevert(
        multisig.callControlled([sig.signature], abiEncodedCall, {from: signer0}),
        "insufficient signatures"
      );
    });

    it('failed by duplicated sig', async function () {
      const mintSigner = web3.eth.accounts.privateKeyToAccount(PRI_KEY);
      const threshold = 3
      const multisig = await Multisig.new([signer0, mintSigner.address, signer2, signer3], threshold)

      const hash = web3.utils.sha3(abiEncodedCall);
      const sig = await web3.eth.accounts.sign(hash, mintSigner.privateKey);

      await expectRevert(
        multisig.callControlled([sig.signature, sig.signature], abiEncodedCall, {from: signer0}),
        "already approved signature"
      );
    });

    it('failed by sender own sig', async function () {
      const mintSigner = web3.eth.accounts.privateKeyToAccount(PRI_KEY);
      const threshold = 2
      const multisig = await Multisig.new([signer0, mintSigner.address, signer2, signer3], threshold)

      const hash = web3.utils.sha3(abiEncodedCall);
      const sig = await web3.eth.accounts.sign(hash, mintSigner.privateKey);

      await expectRevert(
        multisig.callControlled([sig.signature], abiEncodedCall, {from: mintSigner.address}),
        "msg.sender should not be signer"
      );
    });

    it('failed by directly calling nft', async function () {
      const threshold = 2
      const multisig = await Multisig.new([signer0, signer1, signer2], threshold, {from: deployer})

      const controlled = await multisig.controlled()
      const nft = await MockERC721.at(controlled);

      await expectRevert(
        nft.mint(owner, tokenId, {from: deployer}),
        "Ownable: caller is not the owner"
      );
    });
  });

  describe('replaceSinger', () => {
    it('succeed', async function () {
      const threshold = 2;
      const multisig = await Multisig.new([signer0, signer1, signer2], threshold);

      const receipt = await multisig.replaceSinger(signer3, {from: signer1});
      expectEvent(receipt, 'SignerReplaced', {
        oldSinger: signer1,
        newSinger: signer3
      });

      expect(await multisig.signers(1)).to.be.equal(signer3);
    });

    it('failed by called unauthenticated user', async function () {
      const threshold = 2;
      const multisig = await Multisig.new([signer0, signer1, signer2], threshold);

      await expectRevert(
        multisig.replaceSinger(signer3, {from: attacker}),
        "unauthorized msg sender"
      );
    });
  });

});
