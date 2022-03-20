## `TheSpace`

_The Space_ is a pixel space owned by a decentralized autonomous organization (DAO), where members can tokenize, own, trade and color pixels. Pixels are tokenized as ERC721 tokens and traded under Harberger tax, while members receive dividend based on the share of pixels they own.

### Contracts

![The Space Contracts Relationship](./TheSpaceContracts.png "The Space Contracts Relationship")

### Use Cases

#### Trading

- User needs to call `approve` on currency contract before starting. If there is not sufficient allowance for taxing, the corresponding assets are defaulted.
- User buy land: call [`bid` function](./HarbergerMarket.md) on `HarbergerMarket` contract.
- User set land price: call [`price` function](./HarbergerMarket.md) on `HarbergerMarket` contract.

#### Setting Content

- Frontend renders pixel canvas: fetch [`Color` events](./TheSpace.md) from `TheSpace` contract.
- User color an array of pixels: call [`setColors` function](./TheSpace.md) on `TheSpace` contract.
- Frontend fetch content / metadata URI: call [`tokenURI` function](./Property.md) on `Property` contract.
- User set token content: call [`setTokenURI` function](./Property.md) on `Property` contract.

## Functions

### `constructor(string propertyName_, string propertySymbol_, address currencyAddress_, uint256 taxRate_, uint256 totalSupply_)` (public)

### `setColor(uint256 tokenId_, uint256 color_)` (external)

Set colors in batch for an array of pixels.

Emits {Color} events.

## Events

### `Color(uint256 pixelId, uint256 color)`

Emitted when the color of a pixel is updated.
TBD: use uint8 for color encoding?
