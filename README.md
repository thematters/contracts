# Contracts for Matters Protocol

## The Space

_The Space_ is a pixel space owned by a decentralized autonomous organization (DAO), where members can tokenize, own, trade and color pixels. Pixels are tokenized as ERC721 tokens and traded under Harberger tax, while members receive dividend based on the share of pixels they own.

### Contracts

![The Space Contracts Relationship](./docs/TheSpace/TheSpaceContracts.png "The Space Contracts Relationship")

### Use Cases

#### Trading

- User needs to call `approve` on currency contract before starting. If there is not sufficient allowance for taxing, the corresponding assets are defaulted.
- User buy land: call [`bid` function](./docs/TheSpace/HarbergerMarket.md) on `HarbergerMarket`/`PixelBoard` contract.
- User set land price: call [`price` function](./docs/TheSpace/HarbergerMarket.md) on `HarbergerMarket`/`PixelBoard` contract.

#### Setting Content

- Frontend renders pixel canvas: fetch [`Color` events](./docs/TheSpace/PixelBoard.md) from `PixelBoard` contract.
- User color an array of pixels: call [`setColors` function](./docs/TheSpace/PixelBoard.md) on `PixelBoard` contract.
- Frontend fetch content / metadata URI: call [`tokenURI` function](./docs/TheSpace/Asset.md) on `Asset` contract.
- User set token content: call [`setTokenURI` function](./docs/TheSpace/Asset.md) on `Asset` contract.

#### Tokenize

- User combine multiple token into one: call [`groupTokens` function](./docs/TheSpace/Asset.md) on `Asset` contract.
- User seperate pixels in one token into multiple tokens: call [`ungroupToken` function](./docs/TheSpace/Asset.md) on `Asset` contract.

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

[Automatically](https://onbjerg.github.io/foundry-book/forge/deploying.html#verifying)

```bash
# Verify on Poygon Mainnet
make verify-the-space NETWORK=polygon-mainnet

# Verify on Polygon Mumbai
make verify-the-space NETWORK=polygon-mumbai
```

Manually

```bash
# 1. Concat all file into one
forge flatten src/Logbook/Logbook.sol

# 2. On (Polygonscan)[https://mumbai.polygonscan.com/verifycontract], Select "Solidity (Single File)" and upload
```
