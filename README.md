# eth-multisig-contract
Multisig EVM compatible chain smart contract

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

# deploy at bsc testnet
npm run migrate:bsctest
```
