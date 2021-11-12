# eth-multisig-contract
Multisig EVM compatible chain smart contract
- M of N is fixed at the deploy moment
- The access controlled contract is instantiated at the deploy moment
  the controlled extend `Ownable`, so that controlled only via this multisig
- the length of signers CANNOT be changed once they are set

# PreRequirements
|  Software  |  Version  |
| ---- | ---- |
|  Truffle  |  ^v5.x  |
|  Ganache CLI  |  ^v6.x  |

# Getting start
```bash
# install dependencies
npm install

# run test chain
npm run chain

# export environmental variables
export DEPLOYER_KEY=XXX...
export NODE_URL=https://bsc-dataseed.binance.org/

# execute tests
npm run test
```

# Example
The example of calling `mint` function of NFT
```javascript
const web3 = require("web3");
const Multisig = artifacts.require("Multisig");

const PRI_KEY_0 = "0xXXX..."
const PRI_KEY_1 = "0xXXX..."
const PRI_KEY_2 = "0xXXX..."

const signer0 = web3.eth.accounts.privateKeyToAccount(PRI_KEY_0);
const signer0 = web3.eth.accounts.privateKeyToAccount(PRI_KEY_1);
const signer0 = web3.eth.accounts.privateKeyToAccount(PRI_KEY_2);

const threshold = 2;
const multisig = await Multisig.new([signer0.address, signer1.address, signer2.address], threshold, { from: signer0.address});

const tokenId = 101;
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
}, [signer1.address, tokenId]);

const hash = web3.utils.sha3(abiEncodedCall);
const sig = await web3.eth.accounts.sign(hash, signer1.privateKey);

await multisig.callControlled([sig.signature], abiEncodedCall, {from: signer0.address});
````
