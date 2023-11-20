# Solidity Smart Contracts of Matters Lab

## Contracts

| Name             | Network         | Address                                                                                                                         |
| ---------------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Logbook          | Polygon Mumbai  | [0x203197e074b7a2f4ff6890815e4657a9c47c68b1](https://mumbai.polygonscan.com/address/0x203197e074b7a2f4ff6890815e4657a9c47c68b1) |
| Logbook          | Polygon Mainnet | [0xcdf8D568EC808de5fCBb35849B5bAFB5d444D4c0](https://polygonscan.com/address/0xcdf8D568EC808de5fCBb35849B5bAFB5d444D4c0)        |
| SpaceToken       | Polygon Mumbai  | [0xeb6814043dc2184b0b321f6de995bf11bdbcc5b8](https://mumbai.polygonscan.com/address/0xeb6814043dc2184b0b321f6de995bf11bdbcc5b8) |
| SpaceToken       | Polygon Mainnet | [0x264808855b0a6a5a318d238c6ee9f299179f27fc](https://polygonscan.com/address/0x264808855b0a6a5a318d238c6ee9f299179f27fc)        |
| TheSpace         | Polygon Mainnet | [0x9b71045ac2a1563dc5ff8e0c537413a6aae16cd1](https://polygonscan.com/address/0x9b71045ac2a1563dc5ff8e0c537413a6aae16cd1)        |
| TheSpaceRegistry | Polygon Mainnet | [0x8da7a7a48ebbd870358f2fd824e52e5142f44257](https://polygonscan.com/address/0x8da7a7a48ebbd870358f2fd824e52e5142f44257)        |
| Billboard        | Polygon Mumbai  | [0x88EA16c2a69f50B9bc2E8f7684D425f33f29225F](https://mumbai.polygonscan.com/address/0x88EA16c2a69f50B9bc2E8f7684D425f33f29225F) |
| Billboard        | Polygon Mainnet | /                                                                                                                               |

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

Static Analyzers

```bash
make analyze-billboard
```

## Deployment

### Deploy on Local Node:

```bash
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
make deploy-snapper
```

### Deploy & Verify on testnet or mainnet:

```bash
# Deploy The Space contract
make deploy-the-space

# Deploy to Poygon Mainnet
make deploy-the-space NETWORK=polygon-mainnet

# Deploy to Polygon Mumbai
make deploy-the-space NETWORK=polygon-mumbai
```

## Verify Contract Manually

```bash
# 1. Concat all file into one
forge flatten src/Logbook/Logbook.sol

# 2. On (Polygonscan)[https://mumbai.polygonscan.com/verifycontract], Select "Solidity (Single File)" and upload
```
