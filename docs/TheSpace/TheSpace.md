## `TheSpace`

_The Space_ is a pixel space owned by a decentralized autonomous organization (DAO), where members can tokenize, own, trade and color pixels.
Pixels are tokenized as ERC721 tokens and traded under Harberger tax, while members receive dividend based on the share of pixels they own.
Trading logic of Harberger tax is defined in [`IHarbergerMarket`](./IHarbergerMarket.md).

#### Trading

- User needs to call `approve` on currency contract before starting. If there is not sufficient allowance for taxing, the corresponding assets are defaulted.
- User buy pixel: call [`bid` function](./IHarbergerMarket.md) on `HarbergerMarket` contract.
- User set pixel price: call [`setPrice` function](./IHarbergerMarket.md) on `HarbergerMarket` contract.

## Functions

### `constructor(uint256 totalSupply_, address currencyAddress_, address aclManager_, address marketAdmin_, address treasuryAdmin_)` (public)

### `setPixel(uint256 tokenId_, uint256 bidPrice_, uint256 newPrice_, uint256 color_)` (external)

Bid pixel, then set price and color.

### `getPixel(uint256 tokenId_) → struct TheSpace.Pixel pixel` (external)

Get pixel info.

### `_getPixel(uint256 tokenId_) → struct TheSpace.Pixel pixel` (internal)

Get pixel info.

### `setColor(uint256 tokenId_, uint256 color_)` (public)

Set color for a pixel.

Emits {Color} event.

### `_setColor(uint256 tokenId_, uint256 color_, address owner_)` (public)

### `getColor(uint256 tokenId) → uint256` (public)

Get color for a pixel.

### `getPixelsByOwner(address owner_, uint256 limit_, uint256 offset_) → uint256 total, uint256 limit, uint256 offset, struct TheSpace.Pixel[] pixels` (external)

Get owned pixels for a user using pagination.

offset based pagination

## Events

### `Color(uint256 pixelId, uint256 color, address owner)`

Emitted when the color of a pixel is updated.

### `Pixel`

uint256
tokenId

uint256
price

uint256
lastTaxCollection

uint256
ubi

address
owner

uint256
color
