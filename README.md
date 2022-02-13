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

Build

```
make build
```

Testing

```
make test
```

## Deployment

Deploy on Polygon Mainnet:

```
make deploy-polygon-mainnet
```

Deploy on Polygon Mumbai:

```
make deploy-polygon-mumbai
```
