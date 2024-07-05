# Solidity Smart Contracts of Matters Lab

## Contracts

| Name                     | Network         | Address                                                                                                                                |
| ------------------------ | --------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| Logbook                  | Polygon Mumbai  | [0x203197e074b7a2f4ff6890815e4657a9c47c68b1](https://mumbai.polygonscan.com/address/0x203197e074b7a2f4ff6890815e4657a9c47c68b1)        |
| Logbook                  | Polygon Mainnet | [0xcdf8D568EC808de5fCBb35849B5bAFB5d444D4c0](https://polygonscan.com/address/0xcdf8D568EC808de5fCBb35849B5bAFB5d444D4c0)               |
| SpaceToken               | Polygon Mumbai  | [0xeb6814043dc2184b0b321f6de995bf11bdbcc5b8](https://mumbai.polygonscan.com/address/0xeb6814043dc2184b0b321f6de995bf11bdbcc5b8)        |
| SpaceToken               | Polygon Mainnet | [0x264808855b0a6a5a318d238c6ee9f299179f27fc](https://polygonscan.com/address/0x264808855b0a6a5a318d238c6ee9f299179f27fc)               |
| TheSpace                 | Polygon Mainnet | [0x9b71045ac2a1563dc5ff8e0c537413a6aae16cd1](https://polygonscan.com/address/0x9b71045ac2a1563dc5ff8e0c537413a6aae16cd1)               |
| TheSpaceRegistry         | Polygon Mainnet | [0x8da7a7a48ebbd870358f2fd824e52e5142f44257](https://polygonscan.com/address/0x8da7a7a48ebbd870358f2fd824e52e5142f44257)               |
| Curation                 | Polygon Mainnet | [0x5edebbdae7B5C79a69AaCF7873796bb1Ec664DB8](https://polygonscan.com/address/0x5edebbdae7b5c79a69aacf7873796bb1ec664db8)               |
| Curation                 | Polygon Mumbai  | [0xa219C6722008aa22828B31A13ab9Ba93bB91222c](https://mumbai.polygonscan.com/address/0xa219c6722008aa22828b31a13ab9ba93bb91222c)        |
| Curation                 | OP Sepolia      | [0x92a117aea74963cd0cedf9c50f99435451a291f7](https://sepolia-optimism.etherscan.io/address/0x92a117aea74963cd0cedf9c50f99435451a291f7) |
| Curation                 | OP Mainnet      | [0x5edebbdae7B5C79a69AaCF7873796bb1Ec664DB8](https://optimistic.etherscan.io/address/0x5edebbdae7b5c79a69aacf7873796bb1ec664db8#code)  |
| Billboard (Operator)     | OP Mainnet      | [0x88ea16c2a69f50b9bc2e8f7684d425f33f29225f](https://optimistic.etherscan.io/address/0x88ea16c2a69f50b9bc2e8f7684d425f33f29225f)       |
| Billboard (Registry)     | OP Mainnet      | [0x031Dc7C68D4A7057D28814dCc8c61e6f83c7DF25](https://optimistic.etherscan.io/address/0x031Dc7C68D4A7057D28814dCc8c61e6f83c7DF25)       |
| Billboard (Distribution) | OP Mainnet      | [0xad5caac6910f5a737ec53847000c13122b09eada](https://optimistic.etherscan.io/address/0xad5caac6910f5a737ec53847000c13122b09eada)       |
| Billboard (Operator)     | OP Sepolia      | [0x2412316A9fA929CA5D476b9160Fd2688C76614Fe](https://sepolia-optimism.etherscan.io/address/0x2412316A9fA929CA5D476b9160Fd2688C76614Fe) |
| Billboard (Registry)     | OP Sepolia      | [0xF28e390E51ef279170E2Ccbd3Ffcd9c069A9332d](https://sepolia-optimism.etherscan.io/address/0xF28e390E51ef279170E2Ccbd3Ffcd9c069A9332d) |
| Billboard (Distribution) | OP Sepolia      | [0x32C838d74f8b8f49a5B27c74E71797dEd3CCE8A3](https://sepolia-optimism.etherscan.io/address/0x32C838d74f8b8f49a5B27c74E71797dEd3CCE8A3) |

In the "Contract" tab of Polygonscan/Etherscan, you can see the contract code and ABI.

### ABI

To get the contract ABI,

1. Run `make build`;
2. Find on `abi` field of `out/YOUR_CONTRACT.sol/YOUR_CONTRACT.json`;

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

# Deploy Logbook contract (defaults to local node)
make deploy-logbook
```

### Deploy & Verify on testnet or mainnet:

```bash
# Deploy to local node
make deploy-the-space

# Deploy to testnet
cp .env.polygon-mumbai.example .env.polygon-mumbai
make deploy-the-space NETWORK=polygon-mumbai

# Deploy to mainnet
cp .env.op-mainnet.example .env.op-mainnet
make deploy-the-space NETWORK=op-mainnet
```

## Verify Contract Manually

```bash
# 1. Concat all file into one
forge flatten src/Logbook/Logbook.sol

# 2. On (Polygonscan)[https://mumbai.polygonscan.com/verifycontract], Select "Solidity (Single File)" and upload
```
