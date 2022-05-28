[_The Space_](https://www.thespace.game/) is a pixel canvas organized by Harberger Tax and UBI, where each pixel is implemented as ERC721 token.

# Design

## Introduction

See _The Space [Whitepaper](https://wiki.thespace.game/introduction-to-the-space)_ for detail.

An explainer of the idea can be found [here](https://medium.com/coinmonks/radical-markets-can-work-on-blockchain-our-web3-experiment-the-space-shows-how-1b5d49b91d27). Resources on Harberger Tax, also referred to as Partial Common Ownership can be found on [RadicalxChange](https://www.radicalxchange.org/concepts/partial-common-ownership/) and [PartialCommonOwnership](https://partialcommonownership.com/).

## Bidding pixel

Any user can bid on any pixel at anytime, by specifying a bid price.

- All minted pixel has a ask price. If the bid price is higher than or equal with the ask price, the bidder pays the owner the ask price for the pixel.
  - Before transfer, the contract will collect tax from the current owner, and default the pixel if tax is not fully collected. Then the bidder acquire the pixel as if bidding a not-yet-minted pixel.
- If the pixel is not minted yet, the bidder pays a mint tax to mint the pixel. The mint tax needs to be larger than 0 to prevent constantly defaulting and minting pixels.

For any pixel, an user can query the following information to help decide whether to bid a pixel:

- how much tax this pixel owes, and whether it will be defaulted if tax is collected, via `evaluateOwnership`
- how much UBI is available for this pixel, via `ubiAvailable`

## Contracts

- [ITheSpace](./ITheSpace.md)/[TheSpace](./TheSpace.md): main entrance and interface. Implements pixel-specific logical such as setting and reading colors, and logic for trading ERC721 tokens under Harberger Tax and issuing UBI according to the number of token owned. Can be upgraded by calling `upgradeTo`.
- [ITheSpaceRegistry](./ITheSpaceRegistry.md)/[TheSpaceRegistry](./TheSpaceRegistry.md): storage contract for The Space. All state is stored in this contract, upgraded `ITheSpace` still owns this contract.
- [IACLManager](./IACLManager.md)/[ACLManager](./ACLManager.md): special roles that can update settings or withdraw treasury on `TheSpace`.
- [SpaceToken](./SpaceToken.md): standard ERC20 token that can be used as currency in `TheSpace`.

## Logic flow for functions

### `settleTax`

![settleTax function](./settleTax-function.png)

### `transferFrom`

![transferFrom function](./transferFrom-function.png)

### `bid`

![bid function](./bid-function.png)

# Deployment

Make file is at project root.

## Preprare environment

cp .env.local.example .env.local
cp .env.polygon-mainnet.example .env.polygon-mainnet
cp .env.polygon-mumbai.example .env.polygon-mumbai

## Deploy to mainnet

### Deploy $SPACE currency

```
make deploy-the-space-currency NETWORK=polygon-mainnet
```

### Deploy TheSpace

Add the contract address deployed above into env file variable `THESPACE_CURRENCY_ADDRESS`, then deploy TheSpace:

```
make deploy-the-space NETWORK=polygon-mainnet
```

### Deploy the snapper contract

Preprare `SNAPPER_THESPACE_CREATION_BLOCKNUM` and `SNAPPER_THESPACE_INITIAL_SNAPSHOT_CID` (a png file IPFS CID) env variable first, then:

```
make deploy-snapper NETWORK=polygon-mainnet
```
