## `TheSpace`

_The Space_ is a pixel space owned by a decentralized autonomous organization (DAO), where members can tokenize, own, trade and color pixels.
Pixels are tokenized as ERC721 tokens and traded under Harberger tax, while members receive dividend based on the share of pixels they own.
Trading logic of Harberger tax is defined in [`IHarbergerMarket`](./IHarbergerMarket.md).

#### Trading

- User needs to call `approve` on currency contract before starting. If there is not sufficient allowance for taxing, the corresponding assets are defaulted.
- User buy land: call [`bid` function](./IHarbergerMarket.md) on `HarbergerMarket` contract.
- User set land price: call [`setPrice` function](./IHarbergerMarket.md) on `HarbergerMarket` contract.

## Functions

### `constructor(address currencyAddress_, address aclManager_, address marketAdmin_, address treasuryAdmin_)` (public)

### `setPixel(uint256 tokenId_, uint256 bid_, uint256 price_, uint256 color_)` (external)

Bid pixel, then set price and color.

### `getPixel(uint256 tokenId_) → uint256 tokenId, uint256 price, uint256 lastTaxCollection, uint256 ubi, address owner, uint256 color` (external)

Get pixel info.

### `setColor(uint256 tokenId, uint256 color)` (public)

Set color for a pixel.

Emits {Color} event.

### `getColor(uint256 tokenId) → uint256` (public)

Get color for a pixel.

## Events

### `Color(uint256 pixelId, uint256 color, address owner)`

Emitted when the color of a pixel is updated.
