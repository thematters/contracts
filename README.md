# Solidity Smart Contracts of Matters Lab

## Contracts

| Name    | Network        | Address                                                                                                                         |
| ------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Logbook | Polygon Mumbai | [0x203197e074b7a2f4ff6890815e4657a9c47c68b1](https://mumbai.polygonscan.com/address/0x203197e074b7a2f4ff6890815e4657a9c47c68b1) |

In the "Contract" tab of Polygonscan/Etherscan, you can see the contract code and ABI.

### ABI

See [Docs](./docs/) for Contract ABI.

### Usages

```ts
import { ethers } from "ethers";

/**
 * Instantiate contract
 */
const address = "0x203197e074b7a2f4ff6890815e4657a9c47c68b1";
const abi = '[{"inputs":[{"internalType":"string","name":"name_","type":"string"}...]';
const alchemyAPIKey = "...";
const provider = new ethers.providers.AlchemyProvider("maticmum", alchemyAPIKey);
const contract = new ethers.Contract(address, abi, provider);

/**
 * Interact with contract
 */
// mint a logbook
const publicSalePrice = await contract.publicSalePrice();
const tokenId = await contract.publicSaleMint({ value: publicSalePrice });

// set title, description & fork price in one transaction
const title = "Ut cupidatat";
const description = "Ut cupidatat amet ea et veniam amet aute aute eu.";
const forkPrice = ethers.utils.parseEther("0.1"); // 0.1 Ether to Wei
const iface = new ethers.utils.Interface(abi);
const calldata = [
  // title
  iface.encodeFunctionData("setTitle", [tokenId, title]),
  // description
  iface.encodeFunctionData("setDescription", [tokenId, title]),
  // fork price
  iface.encodeFunctionData("setForkPrice", [tokenId, forkPrice]),
];
await contract.multicall(calldata);

// donate
const donationAmount = ethers.utils.parseEther("0.02");
await contract.donate(tokenId, { value: donationAmount });
```

Ethers.js also supports [Human-Readable ABI](https://docs.ethers.io/v5/api/utils/abi/formats/), it's recommended to use, for smaller client bundle size.

To query the contract data, please checkout [thematters/subgraphs](https://github.com/thematters/subgraphs).

## Development

Install [Forge](https://github.com/gakonst/foundry)

Environment

```bash
cp .env.local.example .env.local
```

Build

```bash
make build
```

Testing

```bash
make test
```

## Deployment

### Deploy on Local Node:

```bash
# Run local node
npm run ganache

# Preprare environment
cp .env.local.example .env.local
cp .env.polygon-mainnet.example .env.polygon-mainnet
cp .env.polygon-mumbai.example .env.polygon-mumbai

# Deploy Logbook contract (defaults to local node)
make deploy-logbook

# Deploy currency first, then add the contract address to THESPACE_CURRENCY_ADDRESS env variable
make deploy-the-space-currency
# Deploy the space contract
make deploy-the-space

# Deploy the snapper contract
# Preprare SNAPPER_THESPACE_CREATION_BLOCKNUM and SNAPPER_THESPACE_INITIAL_SNAPSHOT_CID (a png file IPFS CID) env variable first, then:
make deploy-snapper
```

### Deploy on testnet or mainnet:

```bash
# Deploy The Space contract
make deploy-the-space

# Deploy to Poygon Mainnet
make deploy-the-space NETWORK=polygon-mainnet

# Deploy to Polygon Mumbai
make deploy-the-space NETWORK=polygon-mumbai
```

## Verify Contract

### [Automatically](https://onbjerg.github.io/foundry-book/forge/deploying.html#verifying)

```bash
# Verify on Polygon Mumbai
make verify-the-space NETWORK=polygon-mumbai

# Verify on Poygon Mainnet
make verify-the-space NETWORK=polygon-mainnet
```

### Manually

```bash
# 1. Concat all file into one
forge flatten src/Logbook/Logbook.sol

# 2. On (Polygonscan)[https://mumbai.polygonscan.com/verifycontract], Select "Solidity (Single File)" and upload
```
