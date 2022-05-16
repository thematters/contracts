## `ITheSpace`

_The Space_ is a pixel space owned by a decentralized autonomous organization (DAO), where members can tokenize, own, trade and color pixels.

Pixels are tokenized as ERC721 tokens and traded under Harberger tax, while members receive dividend based on the share of pixels they own.

#### Trading

- User needs to call `approve` on currency contract before starting. If there is not sufficient allowance for taxing, the corresponding assets are defaulted.
- User buy pixel: call [`bid` function](./ITheSpace.md).
- User set pixel price: call [`setPrice` function](./ITheSpace.md).

This contract holds the logic of market place, while read from and write into {TheSpaceRegistry}, which is the storage contact.
This contract owns a {TheSpaceRegistry} contract for storage, and can be updated by transfering ownership to a new implementation contract.

## Functions

### `upgradeTo(address newImplementation)` (external)

Switch logic contract to another one.

Access: only `Role.aclManager`.
Throws: `RoleRequired` error.

### `setTotalSupply(uint256 totalSupply_)` (external)

Update total supply of ERC721 token.

Access: only `Role.marketAdmin`.
Throws: `RoleRequired` error.

### `setTaxConfig(enum ITheSpaceRegistry.ConfigOptions option_, uint256 value_)` (external)

Update current tax configuration.

Access: only `Role.marketAdmin`.
Emits: `Config` event.
Throws: `RoleRequired` error.

### `withdrawTreasury(address to)` (external)

Withdraw all available treasury.

Access: only `Role.treasuryAdmin`.
Throws: `RoleRequired` error.

### `getPixel(uint256 tokenId_) → struct ITheSpaceRegistry.Pixel pixel` (external)

Get pixel info.

### `setPixel(uint256 tokenId_, uint256 bidPrice_, uint256 newPrice_, uint256 color_)` (external)

Bid pixel, then set price and color.

Throws: inherits from `bid` and `setPrice`.

### `setColor(uint256 tokenId_, uint256 color_)` (external)

Set color for a pixel.

Access: only token owner or approved operator.
Throws: `Unauthorized` or `ERC721: operator query for nonexistent token` error.
Emits: `Color` event.

### `getColor(uint256 tokenId_) → uint256 color` (external)

Get color for a pixel.

### `getPixelsByOwner(address owner_, uint256 limit_, uint256 offset_) → uint256 total, uint256 limit, uint256 offset, struct ITheSpaceRegistry.Pixel[] pixels` (external)

Get pixels owned by a given address.

offset-based pagination

### `getPrice(uint256 tokenId_) → uint256 price` (external)

Returns the current price of a token by id.

### `setPrice(uint256 tokenId_, uint256 price_)` (external)

Set the current price of a token with id. Triggers tax settle first, price is succefully updated after tax is successfully collected.

Access: only token owner or approved operator.
Throws: `Unauthorized` or `ERC721: operator query for nonexistent token` error.
Emits: `Price` event.

### `getOwner(uint256 tokenId_) → address owner` (external)

Returns the current owner of an Harberger property with token id.

If token does not exisit, return zero address and user can bid the token as usual.

### `bid(uint256 tokenId_, uint256 price_)` (external)

Purchase property with bid higher than current price.
If bid price is higher than ask price, only ask price will be deducted.

Clear tax for owner before transfer.

Throws: `PriceTooLow` or `InvalidTokenId` error.
Emits: `Deal`, `Tax` events.

### `getTax(uint256 tokenId_) → uint256 amount` (external)

Calculate outstanding tax for a token.

### `evaluateOwnership(uint256 tokenId_) → uint256 collectable, bool shouldDefault` (external)

Calculate amount of tax that can be collected, and determine if token should be defaulted.

### `settleTax(uint256 tokenId_) → bool success` (external)

Collect outstanding tax of a token and default it if needed.

Anyone can trigger this function. It could be desirable for the developer team to trigger it once a while to make sure all tokens meet their tax obligation.

Throws: `PriceTooLow` or `InvalidTokenId` error.
Emits: `Tax` events.

### `ubiAvailable(uint256 tokenId_) → uint256 amount` (external)

Amount of UBI available for withdraw on given token.

### `withdrawUbi(uint256 tokenId_)` (external)

Withdraw all UBI on given token.

Emits: `UBI` event.

### `beforeTransferByRegistry(uint256 tokenId_) → bool success` (external)

Perform before `safeTransfer` and `safeTransferFrom` by registry contract.

Collect tax and set price.

Access: only registry.
Throws: `Unauthorized` error.
